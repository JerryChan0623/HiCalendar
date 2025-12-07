//
//  PremiumView.swift
//  HiCalendar
//
//  Created on 2024. Premium Features Purchase View
//

import SwiftUI
import StoreKit

struct PremiumView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var purchaseManager = PurchaseManager.shared
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingPrivacyPolicy = false
    @State private var showingTermsOfService = false
    @State private var selectedProductID: String = PurchaseManager.ProductID.monthlySubscription.rawValue // 默认选中月度会员

    var body: some View {
        NavigationStack {
            ZStack {
                // 背景渐变
                LinearGradient(
                    colors: [BrandColor.primaryBlue.opacity(0.1), BrandColor.primaryYellow.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: BrandSpacing.xl) {
                        // 头部标题
                        headerSection

                        // 功能特性
                        featuresSection

                        // 产品和价格
                        if !purchaseManager.products.isEmpty {
                            productSection
                        }

                        // 购买按钮
                        purchaseSection

                        // 恢复购买
                        restoreSection


                        Spacer(minLength: BrandSpacing.xxl)
                    }
                    .padding(BrandSpacing.lg)
                }
            }
            .navigationTitle(L10n.upgradeToPro)
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(BrandColor.background.opacity(0.9), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L10n.done) {
                        dismiss()
                    }
                    .font(BrandFont.body(size: 16, weight: .medium))
                    .foregroundColor(BrandColor.primaryBlue)
                }
            }
        }
        .task {
            print("📱 PremiumView.task 开始执行")
            print("📱 环境信息:")
            print("   - Bundle ID: \(Bundle.main.bundleIdentifier ?? "unknown")")
            print("   - 是否TestFlight: \(Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt")")
            print("   - 产品数量(加载前): \(purchaseManager.products.count)")

            await purchaseManager.loadProducts()

            print("📱 产品加载完成:")
            print("   - 产品数量: \(purchaseManager.products.count)")
            print("   - 产品列表: \(purchaseManager.products.map { "\($0.id) - \($0.displayName)" })")
            print("   - 按钮禁用状态: \(purchaseManager.products.isEmpty)")

            await purchaseManager.updateCustomerProductStatus()

            print("📱 购买状态更新完成:")
            print("   - isPremiumUnlocked: \(purchaseManager.isPremiumUnlocked)")
            print("   - purchasedProductIDs: \(purchaseManager.purchasedProductIDs)")
        }
        .alert("提示", isPresented: $showingAlert) {
            Button(L10n.ok, role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $showingPrivacyPolicy) {
            PrivacyPolicyView()
        }
        .sheet(isPresented: $showingTermsOfService) {
            TermsOfServiceView()
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: BrandSpacing.md) {
            // Pro 徽章
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [BrandColor.primaryYellow, BrandColor.primaryBlue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .neobrutalStyle(cornerRadius: 50, borderWidth: BrandBorder.thick)

                Text("⭐")
                    .font(.system(size: 40))
            }

            Text("HiCalendar Pro")
                .font(BrandFont.body(size: 28, weight: .heavy))
                .foregroundColor(BrandColor.onSurface)

            Text(L10n.unlockFullFeatures)
                .font(BrandFont.body(size: 16, weight: .medium))
                .foregroundColor(BrandColor.onSurface.opacity(0.7))
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Features Section
    private var featuresSection: some View {
        VStack(spacing: BrandSpacing.lg) {
            Text(L10n.proFeatures)
                .font(BrandFont.body(size: 20, weight: .bold))
                .foregroundColor(BrandColor.onSurface)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: BrandSpacing.md) {
                FeatureCard(
                    icon: "☁️",
                    title: L10n.cloudSync,
                    description: L10n.cloudSyncFeatureDesc,
                    isUnlocked: purchaseManager.canSyncToCloud
                )

                FeatureCard(
                    icon: "📱",
                    title: L10n.desktopWidgets,
                    description: L10n.widgetFeatureDesc,
                    isUnlocked: purchaseManager.canUseWidget
                )

                FeatureCard(
                    icon: "🔔",
                    title: L10n.smartPushFeatureTitle,
                    description: L10n.smartPushFeatureDesc,
                    isUnlocked: purchaseManager.canUsePushNotifications
                )

                FeatureCard(
                    icon: "📅",
                    title: L10n.systemCalendarFeatureTitle,
                    description: L10n.systemCalendarFeatureDesc,
                    isUnlocked: purchaseManager.isPremiumUnlocked
                )
            }
        }
    }

    // MARK: - Product Section
    private var productSection: some View {
        VStack(spacing: BrandSpacing.md) {
            Text("选择订阅方案")
                .font(BrandFont.body(size: 20, weight: .bold))
                .foregroundColor(BrandColor.onSurface)
                .frame(maxWidth: .infinity, alignment: .leading)

            // 月度订阅（放在上面，默认选中）
            if let monthlyProduct = purchaseManager.products.first(where: { $0.id == PurchaseManager.ProductID.monthlySubscription.rawValue }) {
                SubscriptionCard(
                    product: monthlyProduct,
                    isRecommended: false,
                    savingsText: nil,
                    isSelected: selectedProductID == monthlyProduct.id,
                    onSelect: {
                        selectedProductID = monthlyProduct.id
                    }
                )
            }

            // 暂时注释掉年度订阅，等App Store Connect配置完成后再启用
            /*
            // 年度订阅
            if let yearlyProduct = purchaseManager.products.first(where: { $0.id == PurchaseManager.ProductID.yearlySubscription.rawValue }) {
                SubscriptionCard(
                    product: yearlyProduct,
                    isRecommended: true,
                    savingsText: "相比月度订阅每年节省¥148",
                    isSelected: selectedProductID == yearlyProduct.id,
                    onSelect: {
                        selectedProductID = yearlyProduct.id
                    }
                )
            }
            */
        }
    }

    // MARK: - Purchase Section
    private var purchaseSection: some View {
        VStack(spacing: BrandSpacing.sm) {
            if purchaseManager.isPremiumUnlocked {
                // 已购买状态
                Button(action: {}) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20, weight: .bold))
                        Text(L10n.alreadyUnlockedPro)
                            .font(BrandFont.body(size: 18, weight: .bold))
                    }
                    .foregroundColor(BrandColor.onPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: BrandRadius.lg, style: .continuous)
                            .fill(BrandColor.success)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: BrandRadius.lg, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: BrandRadius.lg, style: .continuous)
                            .stroke(BrandBorder.outline, lineWidth: BrandBorder.thick)
                    )
                }
                .disabled(true)

            } else {
                        // 购买按钮
                        Button(action: {
                            Task {
                                await purchaseProduct()
                            }
                        }) {
                            VStack(spacing: 6) {
                                if purchaseManager.isLoading {
                                    HStack(spacing: BrandSpacing.sm) {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: BrandColor.onPrimary))
                                            .scaleEffect(0.8)
                                        Text(L10n.purchasing)
                                            .font(BrandFont.body(size: 18, weight: .bold))
                                    }
                                } else if purchaseManager.products.isEmpty {
                                    // 临时调试信息 - 显示为什么按钮被禁用
                                    VStack(spacing: 4) {
                                        Text("⚠️ 产品加载失败")
                                            .font(BrandFont.body(size: 16, weight: .bold))
                                        Text("产品数量: \(purchaseManager.products.count)")
                                            .font(BrandFont.body(size: 12, weight: .medium))
                                        Text("请检查App Store Connect配置")
                                            .font(BrandFont.body(size: 12, weight: .medium))
                                    }
                                } else {
                                    // 主要文案
                                    HStack(spacing: BrandSpacing.xs) {
                                        Image(systemName: "star.fill")
                                            .font(.system(size: 18, weight: .bold))
                                        Text(L10n.unlockProFeatures)
                                            .font(BrandFont.body(size: 18, weight: .bold))
                                    }

                                    // 试用提示 - 更醒目
                                    Text("🎁 前7天免费体验")
                                        .font(BrandFont.body(size: 16, weight: .heavy))
                                        .foregroundColor(BrandColor.primaryYellow)
                                }
                            }
                            .foregroundColor(BrandColor.onPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: BrandRadius.lg, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [BrandColor.primaryBlue, BrandColor.primaryBlue.opacity(0.8)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: BrandRadius.lg, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: BrandRadius.lg, style: .continuous)
                                    .stroke(BrandBorder.outline, lineWidth: BrandBorder.thick)
                            )
                        }
                        .disabled(purchaseManager.isLoading || purchaseManager.products.isEmpty)
                        .opacity((purchaseManager.isLoading || purchaseManager.products.isEmpty) ? 0.6 : 1.0)

                // Hint 说明文字
                VStack(spacing: 4) {
                    Text("• 可随时取消，试用期内不扣费")
                    Text("• 取消后服务持续到当前周期结束")
                }
                .font(BrandFont.body(size: 12, weight: .medium))
                .foregroundColor(BrandColor.onSurface.opacity(0.6))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 4)
            }
        }
    }

    // MARK: - Restore Section
    private var restoreSection: some View {
        VStack(spacing: BrandSpacing.sm) {
            if !purchaseManager.isPremiumUnlocked {
                // 恢复购买和兑换码按钮
                HStack(spacing: BrandSpacing.lg) {
                    Button(L10n.restorePurchase) {
                        Task {
                            await restorePurchases()
                        }
                    }
                    .font(BrandFont.body(size: 16, weight: .medium))
                    .foregroundColor(BrandColor.primaryBlue)
                    .disabled(purchaseManager.isLoading)

                    Text("•")
                        .foregroundColor(BrandColor.outline)

                    // 兑换码按钮
                    Button(L10n.redeemCode) {
                        redeemOfferCode()
                    }
                    .font(BrandFont.body(size: 16, weight: .medium))
                    .foregroundColor(BrandColor.primaryBlue)
                    .disabled(purchaseManager.isLoading)
                }
            } else {
                // 已订阅用户显示管理订阅按钮
                Button("管理订阅") {
                    manageSubscription()
                }
                .font(BrandFont.body(size: 16, weight: .medium))
                .foregroundColor(BrandColor.primaryBlue)
            }

            // 隐私和条款链接
            HStack(spacing: BrandSpacing.md) {
                Button(L10n.privacyPolicy) {
                    openPrivacyPolicy()
                }

                Text("•")
                    .foregroundColor(BrandColor.outline)

                Button(L10n.termsTitle) {
                    openTermsOfService()
                }
            }
            .font(BrandFont.body(size: 14, weight: .medium))
            .foregroundColor(BrandColor.outline)
        }
    }

    // MARK: - Helper Methods
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private func purchaseProduct() async {
        print("🛒 purchaseProduct() 被调用")
        print("🛒 选中产品ID: \(selectedProductID)")
        print("🛒 产品列表数量: \(purchaseManager.products.count)")
        print("🛒 产品列表: \(purchaseManager.products.map { $0.id })")
        print("🛒 isLoading: \(purchaseManager.isLoading)")
        print("🛒 isPremiumUnlocked: \(purchaseManager.isPremiumUnlocked)")

        // 使用当前选中的产品
        guard let product = purchaseManager.products.first(where: { $0.id == selectedProductID }) else {
            print("❌ 没有找到选中的产品")
            showAlert(message: "未选择产品，请选择一个订阅方案")
            return
        }

        print("✅ 找到产品: \(product.id) - \(product.displayName)")

        do {
            print("🛒 开始购买流程...")
            let transaction = try await purchaseManager.purchase(product)
            if transaction != nil {
                print("✅ 购买成功")
                showAlert(message: "订阅成功！7天免费试用已激活")
            } else {
                print("⚠️ 购买返回nil（可能用户取消）")
            }
        } catch {
            print("❌ 购买失败: \(error)")
            showAlert(message: "购买失败\n\n错误信息：\n\(error.localizedDescription)")
        }
    }

    private func purchaseSpecificProduct(_ product: Product) async {
        do {
            let transaction = try await purchaseManager.purchase(product)
            if transaction != nil {
                showAlert(message: "订阅成功！7天免费试用已激活")
            }
        } catch {
            showAlert(message: L10n.purchaseFailedError(error.localizedDescription))
        }
    }

    private func manageSubscription() {
        // 跳转到系统设置的订阅管理页面
        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
            UIApplication.shared.open(url)
        }
    }

    /// 兑换优惠码 - 显示App Store兑换码输入界面
    private func redeemOfferCode() {
        Task {
            do {
                // 获取当前的 UIWindowScene
                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
                    print("❌ 无法获取 WindowScene")
                    showAlert(message: L10n.redeemFailed("无法打开兑换界面"))
                    return
                }

                // iOS 16+ 支持的兑换码界面
                try await AppStore.presentOfferCodeRedeemSheet(in: windowScene)
                print("✅ 兑换码界面已显示")

                // 兑换成功后刷新购买状态
                await purchaseManager.updateCustomerProductStatus()

                if purchaseManager.isPremiumUnlocked {
                    showAlert(message: L10n.redeemSuccess)
                }
            } catch {
                print("❌ 兑换码界面错误: \(error)")
                // 用户取消不显示错误
                if (error as NSError).code != 2 { // SKError.paymentCancelled
                    showAlert(message: L10n.redeemFailed(error.localizedDescription))
                }
            }
        }
    }

    private func restorePurchases() async {
        await purchaseManager.restorePurchases()
        if let errorMessage = purchaseManager.errorMessage {
            showAlert(message: errorMessage)
        } else if purchaseManager.isPremiumUnlocked {
            showAlert(message: L10n.purchaseRestored)
        } else {
            showAlert(message: L10n.noPreviousPurchase)
        }
    }

    private func showAlert(message: String) {
        alertMessage = message
        showingAlert = true
    }

    // MARK: - 法律条款方法
    private func openTermsOfService() {
        showingTermsOfService = true
    }

    private func openPrivacyPolicy() {
        showingPrivacyPolicy = true
    }

}

// MARK: - Subscription Card Component
struct SubscriptionCard: View {
    let product: Product
    let isRecommended: Bool
    let savingsText: String?
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: {
            onSelect() // 只触发选择，不触发购买
        }) {
            VStack(alignment: .leading, spacing: BrandSpacing.md) {
                // 推荐标签和选中状态
                HStack {
                    if isRecommended {
                        Text("🌟 推荐")
                            .font(BrandFont.body(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, BrandSpacing.sm)
                            .padding(.vertical, 4)
                            .background(
                                LinearGradient(
                                    colors: [BrandColor.primaryYellow, BrandColor.primaryBlue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(BrandRadius.sm)
                    }

                    Spacer()

                    // 选中指示器
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(BrandColor.primaryBlue)
                    } else {
                        Image(systemName: "circle")
                            .font(.system(size: 20, weight: .regular))
                            .foregroundColor(BrandColor.outline)
                    }
                }

                // 产品名称和价格
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: BrandSpacing.xs) {
                        Text(product.displayName)
                            .font(BrandFont.body(size: 18, weight: .bold))
                            .foregroundColor(BrandColor.onSurface)

                        if let savingsText = savingsText {
                            Text(savingsText)
                                .font(BrandFont.body(size: 12, weight: .medium))
                                .foregroundColor(BrandColor.success)
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(product.displayPrice)
                            .font(BrandFont.body(size: 24, weight: .heavy))
                            .foregroundColor(BrandColor.primaryBlue)

                        Text(product.subscription?.subscriptionPeriod.unit == .month ? "/月" : "/年")
                            .font(BrandFont.body(size: 12, weight: .medium))
                            .foregroundColor(BrandColor.onSurface.opacity(0.7))
                    }
                }
            }
            .padding(BrandSpacing.lg)
            .background(
                RoundedRectangle(cornerRadius: BrandRadius.lg, style: .continuous)
                    .fill(isSelected ? BrandColor.primaryBlue.opacity(0.08) : BrandColor.surface)
                    .neobrutalStyle(
                        cornerRadius: BrandRadius.lg,
                        borderWidth: isSelected ? BrandBorder.thick : BrandBorder.regular,
                        borderColor: isSelected ? BrandColor.primaryBlue : BrandBorder.outline
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Feature Card Component
struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let isUnlocked: Bool

    var body: some View {
        MD3Card(type: .outlined) {
            HStack(spacing: BrandSpacing.md) {
                // 图标
                ZStack {
                    Circle()
                        .fill(isUnlocked ? BrandColor.success.opacity(0.2) : BrandColor.outline.opacity(0.1))
                        .frame(width: 50, height: 50)

                    Text(icon)
                        .font(.system(size: 24))
                }

                // 内容
                VStack(alignment: .leading, spacing: BrandSpacing.xs) {
                    Text(title)
                        .font(BrandFont.body(size: 16, weight: .bold))
                        .foregroundColor(BrandColor.onSurface)

                    Text(description)
                        .font(BrandFont.body(size: 14, weight: .medium))
                        .foregroundColor(BrandColor.onSurface.opacity(0.7))
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                // 锁定/解锁图标 - 右侧垂直居中
                if isUnlocked {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(BrandColor.success)
                } else {
                    Image(systemName: "lock.circle.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(BrandColor.outline)
                }
            }
            .padding(BrandSpacing.md)
        }
    }
}

#Preview {
    PremiumView()
}
