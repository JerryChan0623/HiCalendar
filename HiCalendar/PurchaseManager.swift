//
//  PurchaseManager.swift
//  HiCalendar
//
//  Created on 2024. In-App Purchase Manager using StoreKit 2
//

import Foundation
import StoreKit
import SwiftUI
import WidgetKit

@MainActor
class PurchaseManager: ObservableObject {
    static let shared = PurchaseManager()

    // MARK: - Published Properties
    @Published var products: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    // MARK: - Product IDs
    enum ProductID: String, CaseIterable {
        case premium = "com.chenzhencong.HiCalendar.premium"

        var displayName: String {
            switch self {
            case .premium: return "HiCalendar Pro"
            }
        }

        var description: String {
            switch self {
            case .premium: return L10n.unlockCloudSyncDescription
            }
        }

        var emoji: String {
            switch self {
            case .premium: return "⭐"
            }
        }
    }

    // MARK: - Convenience Properties
    var isPremiumUnlocked: Bool {
        let isUnlocked = purchasedProductIDs.contains(ProductID.premium.rawValue)
        print("🔍 检查Premium状态: \(isUnlocked), 已购买产品: \(purchasedProductIDs)")
        return isUnlocked
    }

    var canSyncToCloud: Bool {
        let canSync = isPremiumUnlocked
        print("☁️ 检查云同步权限: \(canSync)")
        return canSync
    }

    var canUseWidget: Bool {
        let canUse = isPremiumUnlocked
        print("📱 检查Widget权限: \(canUse)")
        return canUse
    }

    var canUsePushNotifications: Bool {
        let canUse = isPremiumUnlocked
        print("🔔 检查推送通知权限: \(canUse)")
        return canUse
    }

    private var productsLoaded = false
    private var updates: Task<Void, Never>? = nil

    private init() {
        // Start a transaction listener as close to app launch as possible so you don't miss any transactions.
        updates = observeTransactionUpdates()
    }

    deinit {
        updates?.cancel()
    }

    // MARK: - StoreKit Methods

    /// 加载产品信息
    func loadProducts() async {
        guard !productsLoaded else { return }

        isLoading = true
        errorMessage = nil

        do {
            // Load products from the App Store
            let productIDs = ProductID.allCases.map { $0.rawValue }
            let storeProducts = try await Product.products(for: productIDs)

            DispatchQueue.main.async {
                self.products = storeProducts
                self.productsLoaded = true
                self.isLoading = false
            }

            print("✅ 已加载 \(storeProducts.count) 个产品")

        } catch {
            DispatchQueue.main.async {
                self.errorMessage = L10n.loadingProductsFailed(error.localizedDescription)
                self.isLoading = false
            }
            print("❌ 加载产品失败: \(error)")
        }
    }

    /// 购买产品
    func purchase(_ product: Product) async throws -> StoreKit.Transaction? {
        isLoading = true
        errorMessage = nil

        // 追踪购买流程开始
        let userEventsCount = EventStorageManager.shared.events.count
        MixpanelManager.shared.trackPurchaseFlowStarted(
            productId: product.id,
            priceDisplayed: product.displayPrice,
            currency: "USD", // 可以从product.priceFormatStyle中获取
            triggerSource: "cta_button", // 可以根据调用位置调整
            userEventsCount: userEventsCount
        )

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                // Check whether the transaction is verified. If it isn't, catch `failedVerification` error.
                let transaction = try checkVerified(verification)

                // The transaction is verified. Deliver content to the user.
                await updateCustomerProductStatus()

                // Always finish a transaction.
                await transaction.finish()

                // 追踪购买成功
                let formatter = ISO8601DateFormatter()
                let purchaseTime = formatter.string(from: transaction.purchaseDate)
                let installDate = UserDefaults.standard.object(forKey: "HasLaunchedBefore") as? Date ?? Date()
                let daysToConvert = Calendar.current.dateComponents([.day], from: installDate, to: Date()).day ?? 0

                MixpanelManager.shared.trackPurchaseCompleted(
                    productId: product.id,
                    pricePaid: Double(truncating: product.price as NSNumber),
                    currency: "USD",
                    paymentMethod: "apple_pay",
                    purchaseTime: purchaseTime,
                    daysToConvert: daysToConvert
                )

                DispatchQueue.main.async {
                    self.isLoading = false
                    print("💰 购买完成，当前状态: isPremium=\(self.isPremiumUnlocked)")

                    // 购买成功后强制刷新Widget
                    self.forceRefreshWidget()

                    // 发送购买成功通知，让UI刷新
                    NotificationCenter.default.post(name: Notification.Name("PurchaseStatusChanged"), object: nil)
                }

                print("✅ 购买成功: \(product.displayName)")
                return transaction

            case .userCancelled:
                // 追踪购买取消
                MixpanelManager.shared.trackPurchaseFailed(
                    productId: product.id,
                    errorType: "user_cancelled",
                    errorCode: "user_cancelled",
                    stepFailed: "payment_confirmation"
                )

                DispatchQueue.main.async {
                    self.isLoading = false
                }
                print("🚫 用户取消购买")
                return nil

            case .pending:
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                print("⏳ 购买等待中（家庭共享批准等）")
                return nil

            @unknown default:
                DispatchQueue.main.async {
                    self.errorMessage = L10n.unknownPurchaseResult
                    self.isLoading = false
                }
                return nil
            }

        } catch {
            let nsError = error as NSError

            // 追踪购买失败
            let errorCode = "\(nsError.domain):\(nsError.code)"
            MixpanelManager.shared.trackPurchaseFailed(
                productId: product.id,
                errorType: "store_error",
                errorCode: errorCode,
                stepFailed: "payment_confirmation"
            )

            if nsError.domain == "StoreKitErrorDomain" && nsError.code == 2 { // verification failed
                DispatchQueue.main.async {
                    self.errorMessage = L10n.purchaseVerificationFailed
                    self.isLoading = false
                }
                throw PurchaseError.failedVerification
            } else {
                DispatchQueue.main.async {
                    self.errorMessage = L10n.purchaseFailedError(error.localizedDescription)
                    self.isLoading = false
                }
                print("❌ 购买失败: \(error)")
                throw error
            }
        }
    }

    /// 恢复购买
    func restorePurchases() async {
        isLoading = true
        errorMessage = nil

        do {
            // This call displays a system prompt that asks users to authenticate with their App Store credentials.
            try await AppStore.sync()

            await updateCustomerProductStatus()

            DispatchQueue.main.async {
                self.isLoading = false
            }

            print("✅ 购买恢复完成")

        } catch {
            DispatchQueue.main.async {
                self.errorMessage = L10n.restorePurchaseFailed(error.localizedDescription)
                self.isLoading = false
            }
            print("❌ 恢复购买失败: \(error)")
        }
    }

    /// 更新客户产品状态
    func updateCustomerProductStatus() async {
        print("🚀 开始更新客户产品状态...")
        var purchasedProducts: Set<String> = []
        var transactionCount = 0

        // Iterate through all of the user's purchased products.
        for await result in StoreKit.Transaction.currentEntitlements {
            transactionCount += 1
            print("📋 处理交易 #\(transactionCount): \(result)")

            do {
                // Check whether the transaction is verified. If it isn't, catch `failedVerification` error.
                let transaction = try checkVerified(result)
                print("✅ 交易验证成功: ProductID=\(transaction.productID), ProductType=\(transaction.productType)")

                // Check the `productType` of the transaction and get the corresponding product ID.
                // 简化逻辑：只排除消耗型产品，其他都添加
                if transaction.productType != .consumable {
                    purchasedProducts.insert(transaction.productID)
                    print("✅ 添加产品: \(transaction.productID), 类型: \(transaction.productType)")
                } else {
                    print("⚠️ 跳过消耗型产品: \(transaction.productID)")
                }
            } catch {
                print("❌ 交易验证失败: \(error)")
            }
        }

        print("📊 总共处理了 \(transactionCount) 个交易，有效产品: \(purchasedProducts)")

        DispatchQueue.main.async {
            let oldProducts = self.purchasedProductIDs
            self.purchasedProductIDs = purchasedProducts
            print("🔄 购买状态已更新: 旧状态=\(oldProducts) → 新状态=\(purchasedProducts)")

            // 检查是否状态发生变化
            let statusChanged = oldProducts != purchasedProducts
            if statusChanged {
                print("📱 检测到购买状态变化，准备刷新Widget和同步会员数据...")

                // 触发会员数据同步
                Task {
                    await self.handleMembershipStatusChange()
                }
            }

            // 同步付费状态到App Groups供Widget使用
            self.syncPremiumStatusToAppGroups()

            // 如果状态发生变化，额外延迟刷新确保UI同步
            if statusChanged {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if #available(iOS 14.0, *) {
                        WidgetCenter.shared.reloadAllTimelines()
                        print("🔄 延迟刷新Widget确保同步")
                    }
                }
            }
        }

        print("🔄 购买状态更新完成: \(purchasedProducts)")
    }

    /// 处理会员状态变化
    private func handleMembershipStatusChange() async {
        if isPremiumUnlocked {
            print("🎉 用户成为会员，开始升级数据同步...")

            // 调用Edge Function升级会员状态
            await upgradeMembershipStatus()

            // 触发完整数据同步
            let syncResult = await MemberDataSyncManager.shared.performFullSync()
            if syncResult.success {
                print("✅ 会员数据同步完成")
            } else {
                print("❌ 会员数据同步失败: \(syncResult.errorMessage ?? L10n.somethingWentWrong)")
            }
        } else {
            print("📉 会员状态失效，停止云端同步")
        }
    }

    /// 升级会员状态（调用Edge Function）
    private func upgradeMembershipStatus() async {
        do {
            guard let currentUser = await SupabaseManager.shared.getCurrentUser() else {
                print("❌ 无法获取当前用户信息")
                return
            }

            let url = URL(string: "\(SupabaseManager.shared.supabaseURL)/functions/v1/member-data-sync?action=member-upgrade")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("Bearer \(SupabaseManager.shared.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")

            // 设置会员有效期（1年）
            let membershipExpiry = Calendar.current.date(byAdding: .year, value: 1, to: Date())

            let body = [
                "user_id": currentUser.id.uuidString,
                "membership_expires_at": membershipExpiry?.ISO8601Format() ?? ""
            ]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)

            let (_, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                print("✅ 会员状态升级成功")

                // 更新本地用户信息
                await SupabaseManager.shared.updateUserMembershipStatus(isMember: true, expiresAt: membershipExpiry)
            } else {
                print("❌ 会员状态升级失败")
            }
        } catch {
            print("❌ 升级会员状态异常: \(error)")
        }
    }

    /// 同步付费状态到App Groups供Widget使用
    private func syncPremiumStatusToAppGroups() {
        print("🔄 开始同步付费状态到App Groups...")

        guard let sharedDefaults = UserDefaults(suiteName: "group.com.chenzhencong.HiCalendar") else {
            print("❌ 无法访问App Groups UserDefaults: group.com.chenzhencong.HiCalendar")
            return
        }

        let isPremium = isPremiumUnlocked
        let oldValue = sharedDefaults.bool(forKey: "premium_unlocked")

        sharedDefaults.set(isPremium, forKey: "premium_unlocked")

        // 添加时间戳，帮助调试Widget刷新
        let timestamp = Date().timeIntervalSince1970
        sharedDefaults.set(timestamp, forKey: "premium_status_updated_at")

        sharedDefaults.synchronize() // 强制同步

        let newValue = sharedDefaults.bool(forKey: "premium_unlocked")
        print("💰 App Groups同步完成: 旧值=\(oldValue) → 新值=\(newValue) (期望=\(isPremium))")
        print("⏰ 同步时间戳: \(timestamp)")

        // 验证同步是否成功
        if newValue == isPremium {
            print("✅ App Groups同步验证成功")

            // 立即强制刷新Widget
            if #available(iOS 14.0, *) {
                WidgetCenter.shared.reloadAllTimelines()
                print("🔄 已触发Widget立即刷新")
            }
        } else {
            print("❌ App Groups同步验证失败: 期望=\(isPremium), 实际=\(newValue)")
        }
    }

    /// 强制刷新Widget显示
    private func forceRefreshWidget() {
        print("🔄 开始强制刷新Widget...")

        // 首先同步付费状态到App Groups
        syncPremiumStatusToAppGroups()

        // 立即刷新一次
        if #available(iOS 14.0, *) {
            WidgetCenter.shared.reloadAllTimelines()
            print("🔄 立即刷新Widget")
        }

        // 延迟再刷新一次，确保状态完全同步
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if #available(iOS 14.0, *) {
                WidgetCenter.shared.reloadAllTimelines()
                print("🔄 延迟刷新Widget完成")
            }
        }
    }

    /// 手动刷新购买状态和Widget（用于调试）
    func manualRefreshStatus() async {
        await updateCustomerProductStatus()
        forceRefreshWidget()
        print("🔄 手动刷新购买状态完成")
    }


    private func observeTransactionUpdates() -> Task<Void, Never> {
        Task(priority: .background) { [unowned self] in
            for await verificationResult in StoreKit.Transaction.updates {
                do {
                    let transaction = try checkVerified(verificationResult)

                    // Deliver products to the user.
                    await updateCustomerProductStatus()

                    // Always finish a transaction.
                    await transaction.finish()
                } catch {
                    // StoreKit has a transaction that fails verification. Don't deliver content to the user.
                    print("❌ 交易更新验证失败: \(error)")
                }
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        // Check whether the JWS passes StoreKit verification.
        switch result {
        case .unverified:
            // StoreKit parses the JWS, but it fails verification.
            throw PurchaseError.failedVerification
        case .verified(let safe):
            // The result is verified. Return the unwrapped value.
            return safe
        }
    }
}

// MARK: - Purchase Errors
enum PurchaseError: Error, LocalizedError {
    case failedVerification
    case productNotFound

    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return L10n.verificationFailedMessage
        case .productNotFound:
            return L10n.productNotFoundMessage
        }
    }
}

// MARK: - Helper Extensions
extension Product {
    var localizedPrice: String {
        return displayPrice
    }

    var formattedPrice: String {
        return "¥\(displayPrice)"
    }
}