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
            .navigationTitle("升级到 Pro")
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
            await purchaseManager.loadProducts()
            await purchaseManager.updateCustomerProductStatus()
        }
        .alert("提示", isPresented: $showingAlert) {
            Button(L10n.ok, role: .cancel) { }
        } message: {
            Text(alertMessage)
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

            Text("解锁完整功能，让日历管理更高效")
                .font(BrandFont.body(size: 16, weight: .medium))
                .foregroundColor(BrandColor.onSurface.opacity(0.7))
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Features Section
    private var featuresSection: some View {
        VStack(spacing: BrandSpacing.lg) {
            Text("Pro 功能")
                .font(BrandFont.body(size: 20, weight: .bold))
                .foregroundColor(BrandColor.onSurface)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: BrandSpacing.md) {
                FeatureCard(
                    icon: "☁️",
                    title: L10n.cloudSync,
                    description: "多设备同步您的日历数据，永不丢失",
                    isUnlocked: purchaseManager.canSyncToCloud
                )

                FeatureCard(
                    icon: "📱",
                    title: L10n.desktopWidgets,
                    description: "在主屏幕直接查看今日事项，一目了然",
                    isUnlocked: purchaseManager.canUseWidget
                )

                FeatureCard(
                    icon: "🔔",
                    title: "智能推送通知",
                    description: "云端智能推送提醒，多设备同步推送状态",
                    isUnlocked: purchaseManager.canUsePushNotifications
                )
            }
        }
    }

    // MARK: - Product Section
    private var productSection: some View {
        VStack(spacing: BrandSpacing.md) {
            if let premiumProduct = purchaseManager.products.first(where: { $0.id == PurchaseManager.ProductID.premium.rawValue }) {
                MD3Card(type: .elevated) {
                    VStack(spacing: BrandSpacing.md) {
                        HStack {
                            VStack(alignment: .leading, spacing: BrandSpacing.xs) {
                                Text(premiumProduct.displayName)
                                    .font(BrandFont.body(size: 18, weight: .bold))
                                    .foregroundColor(BrandColor.onSurface)

                                Text(premiumProduct.description)
                                    .font(BrandFont.body(size: 14, weight: .medium))
                                    .foregroundColor(BrandColor.onSurface.opacity(0.7))
                            }

                            Spacer()

                            VStack(alignment: .trailing) {
                                Text(premiumProduct.displayPrice)
                                    .font(BrandFont.body(size: 24, weight: .heavy))
                                    .foregroundColor(BrandColor.primaryBlue)

                                Text(L10n.lifetimeAccess)
                                    .font(BrandFont.body(size: 12, weight: .medium))
                                    .foregroundColor(BrandColor.onSurface.opacity(0.6))
                            }
                        }
                    }
                    .padding(BrandSpacing.lg)
                }
            }
        }
    }

    // MARK: - Purchase Section
    private var purchaseSection: some View {
        VStack(spacing: BrandSpacing.md) {
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
                    HStack {
                        if purchaseManager.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: BrandColor.onPrimary))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "star.fill")
                                .font(.system(size: 20, weight: .bold))
                        }

                        Text(purchaseManager.isLoading ? L10n.purchasing : L10n.unlockProFeatures)
                            .font(BrandFont.body(size: 18, weight: .bold))
                    }
                    .foregroundColor(BrandColor.onPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: BrandRadius.lg, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [BrandColor.primaryYellow, BrandColor.primaryBlue],
                                    startPoint: .leading,
                                    endPoint: .trailing
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
            }
        }
    }

    // MARK: - Restore Section
    private var restoreSection: some View {
        VStack(spacing: BrandSpacing.sm) {
            if !purchaseManager.isPremiumUnlocked {
                Button(L10n.restorePurchase) {
                    Task {
                        await restorePurchases()
                    }
                }
                .font(BrandFont.body(size: 16, weight: .medium))
                .foregroundColor(BrandColor.primaryBlue)
                .disabled(purchaseManager.isLoading)
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
    private func purchaseProduct() async {
        guard let product = purchaseManager.products.first(where: { $0.id == PurchaseManager.ProductID.premium.rawValue }) else {
            showAlert(message: "产品未找到，请稍后再试")
            return
        }

        do {
            let transaction = try await purchaseManager.purchase(product)
            if transaction != nil {
                showAlert(message: "购买成功！Pro 功能已解锁 🎉")
            }
        } catch {
            showAlert(message: "购买失败: \(error.localizedDescription)")
        }
    }

    private func restorePurchases() async {
        await purchaseManager.restorePurchases()
        if let errorMessage = purchaseManager.errorMessage {
            showAlert(message: errorMessage)
        } else if purchaseManager.isPremiumUnlocked {
            showAlert(message: "购买已恢复！Pro 功能已解锁 🎉")
        } else {
            showAlert(message: "未找到之前的购买记录")
        }
    }

    private func showAlert(message: String) {
        alertMessage = message
        showingAlert = true
    }

    // MARK: - 法律条款方法
    private func openTermsOfService() {
        if let url = URL(string: "https://github.com/chenzhencong/HiCalendar/blob/main/TERMS_OF_SERVICE.md") {
            UIApplication.shared.open(url)
        }
    }

    private func openPrivacyPolicy() {
        if let url = URL(string: "https://github.com/chenzhencong/HiCalendar/blob/main/PRIVACY_POLICY.md") {
            UIApplication.shared.open(url)
        }
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
                    HStack {
                        Text(title)
                            .font(BrandFont.body(size: 16, weight: .bold))
                            .foregroundColor(BrandColor.onSurface)

                        Spacer()

                        if isUnlocked {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(BrandColor.success)
                        } else {
                            Image(systemName: "lock.circle.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(BrandColor.outline)
                        }
                    }

                    Text(description)
                        .font(BrandFont.body(size: 14, weight: .medium))
                        .foregroundColor(BrandColor.onSurface.opacity(0.7))
                        .multilineTextAlignment(.leading)
                }

                Spacer()
            }
            .padding(BrandSpacing.md)
        }
    }
}

#Preview {
    PremiumView()
}
