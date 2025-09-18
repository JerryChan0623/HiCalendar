//
//  SettingsView.swift
//  HiCalendar
//
//  Created on 2024. Cute Calendar AI 设置页
//

import SwiftUI
import PhotosUI
import WidgetKit

struct SettingsView: View {
    @StateObject private var backgroundManager = BackgroundImageManager.shared
    @StateObject private var supabaseManager = SupabaseManager.shared
    @StateObject private var pushManager = PushNotificationManager.shared
    @StateObject private var purchaseManager = PurchaseManager.shared
    @StateObject private var systemCalendarManager = SystemCalendarManager.shared
    @State private var showingPhotoPicker = false
    @State private var selectedImage: UIImage?
    @State private var showingRemoveAlert = false
    @State private var showingCropView = false
    @State private var croppedImage: UIImage?
    @State private var showingSignOutAlert = false
    @State private var showingPremiumView = false
    @Environment(\.dismiss) private var dismiss
    
    @ViewBuilder
    private var mainContent: some View {
        VStack(spacing: BrandSpacing.xl) {
            if supabaseManager.isAuthenticated {
                // 已登录：显示完整设置
                userSection
                backgroundSection
                systemCalendarToggleSection
                pushNotificationSection
                signOutSection
                legalSection
            } else {
                // 未登录：只显示登录引导
                signInSection
                loginBenefitsSection
            }
        }
        .padding(BrandSpacing.lg)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                mainContent
            }
            .background(BrandColor.background.ignoresSafeArea())
            .navigationTitle(L10n.settings)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text(L10n.back)
                                .font(.system(size: 17))
                        }
                        .foregroundColor(BrandColor.primary)
                    }
                }
            }
        }
        .task {
            // 加载商品用于价格展示，并刷新购买状态
            await purchaseManager.loadProducts()
            await purchaseManager.updateCustomerProductStatus()
        }
        .sheet(isPresented: $showingPhotoPicker) {
            PhotoPickerView(selectedImage: $selectedImage)
        }
        .sheet(isPresented: $showingCropView) {
            if let image = selectedImage {
                ImageCropView(originalImage: image, croppedImage: $croppedImage)
            }
        }
        .sheet(isPresented: $showingPremiumView) {
            PremiumView()
        }
        .onChange(of: selectedImage) { _, image in
            if let _ = image {
                // 选择图片后显示裁切界面
                showingCropView = true
            }
        }
        .onChange(of: croppedImage) { _, image in
            if let image = image {
                backgroundManager.saveBackgroundImage(image)
                // 清理临时状态
                selectedImage = nil
                croppedImage = nil
            }
        }
        .overlay(removeBackgroundAlert)
        .overlay(signOutAlert)
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("PurchaseStatusChanged"))) { _ in
            print("🔄 收到购买状态变化通知，刷新UI")
            // 强制刷新状态
            Task {
                await purchaseManager.updateCustomerProductStatus()
            }
        }
    }
    
    @ViewBuilder
    private var removeBackgroundAlert: some View {
        if showingRemoveAlert {
            NeobrutalismAlert(
                title: L10n.reallyDontWant,
                message: L10n.sureDeleteImage,
                isPresented: $showingRemoveAlert
            ) {
                HStack(spacing: BrandSpacing.lg) {
                    Button(L10n.iThinkAgain) {
                        showingRemoveAlert = false
                    }
                    .buttonStyle(MD3ButtonStyle(type: .text))

                    Button(L10n.dontWantIt) {
                        backgroundManager.removeBackgroundImage()
                        showingRemoveAlert = false
                    }
                    .buttonStyle(MD3ButtonStyle(type: .filled))
                }
            }
        }
    }
    
    @ViewBuilder
    private var signOutAlert: some View {
        if showingSignOutAlert {
            NeobrutalismAlert(
                title: L10n.leavingAlready,
                message: L10n.reallyLeaving,
                isPresented: $showingSignOutAlert
            ) {
                HStack(spacing: BrandSpacing.lg) {
                    Button(L10n.iThinkAgain) {
                        showingSignOutAlert = false
                    }
                    .buttonStyle(MD3ButtonStyle(type: .text))
                    
                    Button(L10n.seeYouLater) {
                        signOut()
                    }
                    .buttonStyle(MD3ButtonStyle(type: .filled))
                }
            }
        }
    }
    
    // MARK: - 用户信息区域
    private var userSection: some View {
        MD3Card(type: .elevated) {
            VStack(alignment: .leading, spacing: BrandSpacing.lg) {
                HStack {
                    Text(L10n.whoIsHere)
                        .font(BrandFont.body(size: 18, weight: .bold))
                        .foregroundColor(BrandColor.neutral900)

                    Spacer()

                    // 会员状态图标按钮
                    Button(action: { showingPremiumView = true }) {
                        HStack(spacing: BrandSpacing.xs) {
                            Image(systemName: purchaseManager.isPremiumUnlocked ? "crown.fill" : "crown")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(purchaseManager.isPremiumUnlocked ? .yellow : BrandColor.neutral500)

                            Text(purchaseManager.isPremiumUnlocked ? "会员" : "升级")
                                .font(BrandFont.body(size: 12, weight: .bold))
                                .foregroundColor(purchaseManager.isPremiumUnlocked ? BrandColor.success : BrandColor.primaryBlue)
                        }
                        .padding(.horizontal, BrandSpacing.sm)
                        .padding(.vertical, BrandSpacing.xs)
                        .background(
                            RoundedRectangle(cornerRadius: BrandRadius.sm)
                                .fill(purchaseManager.isPremiumUnlocked ? BrandColor.success.opacity(0.1) : BrandColor.primaryBlue.opacity(0.1))
                                .stroke(purchaseManager.isPremiumUnlocked ? BrandColor.success.opacity(0.3) : BrandColor.primaryBlue.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                VStack(alignment: .leading, spacing: BrandSpacing.sm) {
                    Text(L10n.itsYou)
                        .font(BrandFont.body(size: 14, weight: .medium))
                        .foregroundColor(BrandColor.neutral500)

                    Text(supabaseManager.currentUser?.email ?? "Supabase用户")
                        .font(BrandFont.body(size: 16, weight: .bold))
                        .foregroundColor(BrandColor.neutral900)
                }
            }
        }
    }
    
    // MARK: - 登出区域
    private var signOutSection: some View {
        Button(action: {
            showingSignOutAlert = true
        }) {
            HStack(spacing: BrandSpacing.md) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.title2)
                    .foregroundColor(BrandColor.danger)
                
                Text(L10n.seeYouLater)
                    .font(BrandFont.body(size: 16, weight: .bold))
                    .foregroundColor(BrandColor.danger)
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(BrandSpacing.lg)
            .background(
                RoundedRectangle(cornerRadius: BrandRadius.md)
                    .stroke(BrandColor.danger, lineWidth: BrandBorder.regular)
            )
        }
    }
    
    // MARK: - 背景设置区域
    private var backgroundSection: some View {
        MD3Card(type: .elevated) {
            backgroundSectionContent
        }
    }


    // MARK: - 背景设置内容
    private var backgroundSectionContent: some View {
        VStack(alignment: .leading, spacing: BrandSpacing.lg) {
            // 标题
            HStack {
                Text(L10n.changeCalendarSkin)
                    .font(BrandFont.body(size: 16, weight: .bold))
                    .foregroundColor(BrandColor.neutral900)

                Spacer()

                Image(systemName: "photo.on.rectangle")
                    .font(.system(size: 16))
                    .foregroundColor(BrandColor.primaryBlue)
            }
                
                // 当前背景预览
                if backgroundManager.hasCustomBackground, let image = backgroundManager.backgroundImage {
                    VStack(spacing: BrandSpacing.md) {
                        Text(L10n.currentLook)
                            .font(BrandFont.body(size: 14, weight: .medium))
                            .foregroundColor(BrandColor.neutral700)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(9/16, contentMode: .fit) // 手机屏幕比例
                            .frame(maxHeight: 240)
                            .clipped()
                            .cornerRadius(BrandRadius.md)
                            .neobrutalStyle(cornerRadius: BrandRadius.md, borderWidth: BrandBorder.regular)
                        
                        // 移除按钮
                        Button(L10n.dontWantThis) {
                            showingRemoveAlert = true
                        }
                        .font(BrandFont.body(size: 14, weight: .medium))
                        .foregroundColor(BrandColor.danger)
                        .padding(.vertical, BrandSpacing.sm)
                        .padding(.horizontal, BrandSpacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: BrandRadius.sm)
                                .stroke(BrandColor.danger, lineWidth: BrandBorder.thin)
                        )
                    }
                } else {
                    VStack(spacing: BrandSpacing.md) {
                        Text(L10n.noBackgroundYet)
                            .font(BrandFont.body(size: 14, weight: .medium))
                            .foregroundColor(BrandColor.neutral500)
                        
                        RoundedRectangle(cornerRadius: BrandRadius.md)
                            .fill(BrandColor.neutral200)
                            .aspectRatio(9/16, contentMode: .fit) // 手机屏幕比例
                            .frame(maxHeight: 240)
                            .overlay(
                                VStack(spacing: BrandSpacing.sm) {
                                    Image(systemName: "photo")
                                        .font(.largeTitle)
                                        .foregroundColor(BrandColor.neutral500)
                                    Text(L10n.simpleBeauty)
                                        .font(BrandFont.bodySmall)
                                        .foregroundColor(BrandColor.neutral500)
                                }
                            )
                            .neobrutalStyle(cornerRadius: BrandRadius.md, borderWidth: BrandBorder.regular)
                    }
                }
                
                // 上传按钮
                Button(action: {
                    showingPhotoPicker = true
                }) {
                    HStack(spacing: BrandSpacing.md) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                        
                        Text(backgroundManager.hasCustomBackground ? L10n.updateBackground : L10n.chooseBackground)
                            .font(BrandFont.body(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, BrandSpacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: BrandRadius.md)
                            .fill(BrandColor.primaryBlue)
                            .neobrutalStyle(cornerRadius: BrandRadius.md, borderWidth: BrandBorder.regular)
                    )
                }
                
            // 说明文字
            Text(L10n.backgroundTip)
                .font(BrandFont.bodySmall)
                .foregroundColor(BrandColor.neutral500)
                .multilineTextAlignment(.leading)
        }
    }
    
    // MARK: - 推送通知设置区域
    private var pushNotificationSection: some View {
        MD3Card(type: .elevated) {
            VStack(alignment: .leading, spacing: BrandSpacing.lg) {
                // 标题
                HStack {
                    Text(L10n.notificationSettings)
                        .font(BrandFont.body(size: 18, weight: .bold))
                        .foregroundColor(BrandColor.neutral900)

                    Spacer()

                    // 会员功能标识（云端推送）
                    HStack(spacing: 4) {
                        Image(systemName: purchaseManager.isPremiumUnlocked ? "crown.fill" : "crown")
                            .font(.caption)
                            .foregroundColor(purchaseManager.isPremiumUnlocked ? .yellow : BrandColor.neutral500)
                        Text(purchaseManager.isPremiumUnlocked ? "云推送" : "会员")
                            .font(BrandFont.body(size: 12, weight: .bold))
                            .foregroundColor(purchaseManager.isPremiumUnlocked ? BrandColor.success : .orange)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(purchaseManager.isPremiumUnlocked ? BrandColor.success.opacity(0.1) : .orange.opacity(0.1))
                            .stroke(purchaseManager.isPremiumUnlocked ? BrandColor.success.opacity(0.3) : .orange.opacity(0.3), lineWidth: 1)
                    )

                    // 权限状态指示器
                    Circle()
                        .fill(pushManager.isPermissionGranted ? BrandColor.success : BrandColor.danger)
                        .frame(width: 8, height: 8)
                }
                
                // 权限状态
                if !pushManager.isPermissionGranted {
                    VStack(alignment: .leading, spacing: BrandSpacing.md) {
                        Text(L10n.pushNotEnabled)
                            .font(BrandFont.body(size: 16, weight: .medium))
                            .foregroundColor(BrandColor.danger)
                        
                        Text(L10n.enablePushTip)
                            .font(BrandFont.body(size: 14, weight: .medium))
                            .foregroundColor(BrandColor.neutral500)
                        
                        Button(L10n.enablePush) {
                            Task {
                                let granted = await pushManager.requestPermission()
                                if !granted {
                                    // 如果用户拒绝，提示去设置页面开启
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                        pushManager.openSettings()
                                    }
                                }
                            }
                        }
                        .buttonStyle(MD3ButtonStyle(type: .filled, isFullWidth: true))
                    }
                } else {
                    // 推送设置选项
                    VStack(spacing: BrandSpacing.lg) {
                        // 1天前推送
                        Toggle(isOn: Binding(
                            get: { pushManager.pushSettings.dayBeforeEnabled },
                            set: { newValue in
                                // 立即更新本地状态
                                pushManager.pushSettings.dayBeforeEnabled = newValue
                                // 异步同步到服务端
                                Task {
                                    await pushManager.updatePushSettings(pushManager.pushSettings)
                                }
                            }
                        )) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(L10n.dayBeforeReminder)
                                    .font(BrandFont.body(size: 16, weight: .medium))
                                Text(L10n.dayBeforeDesc)
                                    .font(BrandFont.body(size: 12, weight: .regular))
                                    .foregroundColor(BrandColor.neutral500)
                            }
                        }
                        .toggleStyle(SwitchToggleStyle(tint: BrandColor.primary))
                        
                        // 1周前推送
                        Toggle(isOn: Binding(
                            get: { pushManager.pushSettings.weekBeforeEnabled },
                            set: { newValue in
                                // 立即更新本地状态
                                pushManager.pushSettings.weekBeforeEnabled = newValue
                                // 异步同步到服务端
                                Task {
                                    await pushManager.updatePushSettings(pushManager.pushSettings)
                                }
                            }
                        )) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(L10n.weekBeforeReminder)
                                    .font(BrandFont.body(size: 16, weight: .medium))
                                Text(L10n.weekBeforeDesc)
                                    .font(BrandFont.body(size: 12, weight: .regular))
                                    .foregroundColor(BrandColor.neutral500)
                            }
                        }
                        .toggleStyle(SwitchToggleStyle(tint: BrandColor.primary))
                        
                        
                    }
                }
            }
        }
    }
    
    
    // MARK: - Pro功能区域（重构UI）
    private var premiumSection: some View {
        ZStack {
            RoundedRectangle(cornerRadius: BrandRadius.lg)
                .fill(
                    LinearGradient(
                        colors: [BrandColor.primaryBlue.opacity(0.14), BrandColor.primaryYellow.opacity(0.14)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: BrandRadius.lg)
                        .stroke(BrandColor.outline.opacity(0.2), lineWidth: BrandBorder.regular)
                )
                .neobrutalStyle(cornerRadius: BrandRadius.lg, borderWidth: BrandBorder.regular)

            VStack(alignment: .leading, spacing: BrandSpacing.lg) {
                HStack(alignment: .center, spacing: BrandSpacing.md) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [BrandColor.primaryYellow, BrandColor.primaryBlue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 40, height: 40)
                        Text("⭐").font(.system(size: 18))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(purchaseManager.isPremiumUnlocked ? L10n.hiCalendarMember : L10n.upgradeHiCalendarPro)
                            .font(BrandFont.body(size: 18, weight: .bold))
                            .foregroundColor(BrandColor.neutral900)
                        Text(purchaseManager.isPremiumUnlocked ? L10n.alreadyUnlocked : L10n.unlockFeatures)
                            .font(BrandFont.body(size: 13, weight: .medium))
                            .foregroundColor(BrandColor.neutral500)
                    }

                    Spacer()

                    if purchaseManager.isPremiumUnlocked {
                        Label("已解锁", systemImage: "checkmark.seal.fill")
                            .font(BrandFont.body(size: 12, weight: .bold))
                            .foregroundColor(BrandColor.onPrimary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(BrandColor.success)
                            .clipShape(Capsule())
                    }
                }

                HStack(spacing: BrandSpacing.sm) {
                    benefitPill(emoji: "☁️", text: L10n.cloudSync)
                    benefitPill(emoji: "📱", text: L10n.desktopWidgets)
                    benefitPill(emoji: "🔔", text: L10n.smartPush)
                }

                if !purchaseManager.isPremiumUnlocked {
                    VStack(alignment: .leading, spacing: BrandSpacing.md) {
                        HStack {
                            Text(displayPrice())
                                .font(BrandFont.body(size: 22, weight: .heavy))
                                .foregroundColor(BrandColor.primaryBlue)
                            Spacer()
                            Button(action: { showingPremiumView = true }) {
                                HStack(spacing: BrandSpacing.xs) {
                                    Image(systemName: "star.fill").font(.system(size: 16, weight: .bold))
                                    Text(L10n.upgradeNow).font(BrandFont.body(size: 16, weight: .bold))
                                }
                                .foregroundColor(BrandColor.onPrimary)
                                .padding(.horizontal, BrandSpacing.lg)
                                .padding(.vertical, BrandSpacing.sm)
                                .background(
                                    LinearGradient(
                                        colors: [BrandColor.primaryYellow, BrandColor.primaryBlue],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(BrandBorder.outline, lineWidth: BrandBorder.regular)
                                )
                            }
                        }
                        Button(L10n.restorePurchase) {
                            Task { await purchaseManager.restorePurchases() }
                        }
                        .font(BrandFont.body(size: 14, weight: .medium))
                        .foregroundColor(BrandColor.primaryBlue)
                    }
                } else {
                    VStack(alignment: .leading, spacing: BrandSpacing.sm) {
                        HStack(spacing: BrandSpacing.md) {
                            statusTag(text: "云同步 已激活", color: BrandColor.success)
                            statusTag(text: "小组件 已激活", color: BrandColor.success)
                            statusTag(text: "推送 已激活", color: BrandColor.success)
                        }
                        // 生产版本简化：只保留打开会员中心按钮
                        Button(action: { showingPremiumView = true }) {
                            Label("管理会员", systemImage: "star")
                                .font(BrandFont.body(size: 14, weight: .medium))
                        }
                        .buttonStyle(MD3ButtonStyle(type: .outlined))
                    }
                }
            }
            .padding(BrandSpacing.lg)
        }
    }

    private func displayPrice() -> String {
        if let p = purchaseManager.products.first(where: { $0.id == PurchaseManager.ProductID.premium.rawValue }) {
            return p.displayPrice
        }
        return ""
    }

    private func benefitPill(emoji: String, text: String) -> some View {
        HStack(spacing: BrandSpacing.xs) {
            Text(emoji).font(.system(size: 14))
            Text(text).font(BrandFont.body(size: 13, weight: .medium))
        }
        .foregroundColor(BrandColor.onSurface)
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(BrandColor.surface.opacity(0.7))
        .clipShape(Capsule())
    }

    private func statusTag(text: String, color: Color) -> some View {
        Text(text)
            .font(BrandFont.body(size: 12, weight: .bold))
            .foregroundColor(color)
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }

    // MARK: - Apple登录区域
    private var signInSection: some View {
        MD3Card(type: .elevated) {
            VStack(spacing: BrandSpacing.lg) {
                HStack {
                    Text(L10n.pleaseLogin)
                        .font(BrandFont.body(size: 18, weight: .bold))
                        .foregroundColor(BrandColor.neutral900)
                    
                    Spacer()
                    
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.title2)
                        .foregroundColor(BrandColor.primaryBlue)
                }
                
                VStack(spacing: BrandSpacing.md) {
                    Text(L10n.loginBenefits)
                        .font(BrandFont.body(size: 14, weight: .medium))
                        .foregroundColor(BrandColor.neutral500)
                        .multilineTextAlignment(.center)
                    
                    // Apple登录按钮
                    AppleSignInButton {
                        // 点击登录时检查推送权限
                        checkPushPermissionBeforeLogin()
                    }
                    .padding(.top, BrandSpacing.sm)

                    // 法律条款链接
                    VStack(spacing: BrandSpacing.xs) {
                        Text(L10n.loginAgreement)
                            .font(BrandFont.body(size: 12, weight: .medium))
                            .foregroundColor(BrandColor.neutral500)

                        HStack(spacing: BrandSpacing.xs) {
                            Button(L10n.termsOfService) {
                                openTermsOfService()
                            }
                            .font(BrandFont.body(size: 12, weight: .medium))
                            .foregroundColor(BrandColor.primaryBlue)

                            Text(L10n.and)
                                .font(BrandFont.body(size: 12, weight: .medium))
                                .foregroundColor(BrandColor.neutral500)

                            Button(L10n.privacyPolicy) {
                                openPrivacyPolicy()
                            }
                            .font(BrandFont.body(size: 12, weight: .medium))
                            .foregroundColor(BrandColor.primaryBlue)
                        }
                    }
                    .padding(.top, BrandSpacing.xs)
                    
                    // 显示登录错误信息
                    if let errorMessage = supabaseManager.errorMessage {
                        Text("登录错误: \(errorMessage)")
                            .font(BrandFont.bodySmall)
                            .foregroundColor(BrandColor.danger)
                            .multilineTextAlignment(.center)
                            .padding(.top, BrandSpacing.sm)
                    }
                    
                    // 显示Apple登录管理器的错误信息
                    if let appleError = AppleAuthManager.shared.errorMessage {
                        Text("Apple认证错误: \(appleError)")
                            .font(BrandFont.bodySmall)
                            .foregroundColor(BrandColor.danger)
                            .multilineTextAlignment(.center)
                            .padding(.top, BrandSpacing.sm)
                    }
                }
            }
        }
    }
    
    
    // MARK: - 登出方法
    private func signOut() {
        Task {
            try? await supabaseManager.signOut()
            await MainActor.run {
                showingSignOutAlert = false
            }
        }
    }


    // MARK: - 登录好处说明区域
    private var loginBenefitsSection: some View {
        MD3Card(type: .outlined) {
            VStack(alignment: .leading, spacing: BrandSpacing.lg) {
                // 标题
                HStack {
                    Text("🔐")
                        .font(.system(size: 24))
                    Text(L10n.unlockMoreSettings)
                        .font(BrandFont.body(size: 18, weight: .bold))
                        .foregroundColor(BrandColor.onSurface)
                    Spacer()
                }

                // 登录功能
                VStack(spacing: BrandSpacing.md) {
                    benefitItem(
                        icon: "🎨",
                        title: L10n.personalizedBackground,
                        description: "自定义日历背景图片，让界面独一无二"
                    )
                }

                Divider()
                    .background(BrandColor.onSurface.opacity(0.2))

                // 会员功能标题
                HStack {
                    Text("⭐")
                        .font(.system(size: 20))
                    Text(L10n.becomeMemberUnlock)
                        .font(BrandFont.body(size: 16, weight: .bold))
                        .foregroundColor(BrandColor.onSurface)
                    Spacer()
                }

                // 会员功能列表
                VStack(spacing: BrandSpacing.sm) {
                    benefitItem(
                        icon: "☁️",
                        title: "数据云端备份",
                        description: "多设备数据同步，永不丢失"
                    )

                    benefitItem(
                        icon: "🔔",
                        title: "智能推送提醒",
                        description: "云端推送通知，多设备同步状态"
                    )

                    benefitItem(
                        icon: "📱",
                        title: L10n.desktopWidgets,
                        description: "主屏幕直接查看今日事项"
                    )
                }

                // 登录提示
                Text("先登录享受个性化设置，升级会员解锁全部云端功能")
                    .font(BrandFont.body(size: 14, weight: .medium))
                    .foregroundColor(BrandColor.onSurface.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.top, BrandSpacing.sm)
            }
            .padding(BrandSpacing.lg)
        }
    }

    // 功能项视图
    private func benefitItem(icon: String, title: String, description: String) -> some View {
        HStack(spacing: BrandSpacing.md) {
            Text(icon)
                .font(.system(size: 20))
                .frame(width: 32)

            VStack(alignment: .leading, spacing: BrandSpacing.xs) {
                Text(title)
                    .font(BrandFont.body(size: 16, weight: .bold))
                    .foregroundColor(BrandColor.onSurface)

                Text(description)
                    .font(BrandFont.body(size: 14, weight: .medium))
                    .foregroundColor(BrandColor.onSurface.opacity(0.7))
            }

            Spacer()
        }
    }

    // MARK: - 推送权限检查方法
    private func checkPushPermissionBeforeLogin() {
        // 检查当前推送权限状态
        pushManager.checkNotificationPermission()

        if !pushManager.isPermissionGranted {
            // 权限未开启，直接请求系统推送权限，然后开始登录
            print("🔔 推送权限未开启，先请求权限再登录")
            Task {
                let granted = await pushManager.requestPermission()
                await MainActor.run {
                    if granted {
                        print("✅ 用户同意推送权限，开始登录")
                    } else {
                        print("⚠️ 用户拒绝推送权限，仍然开始登录")
                    }
                    startAppleSignIn()
                }
            }
        } else {
            // 权限已开启，直接开始登录
            print("✅ 推送权限已开启，直接开始登录")
            startAppleSignIn()
        }
    }

    private func startAppleSignIn() {
        // 直接调用 Apple 登录流程
        AppleAuthManager.shared.startSignInWithApple()
    }

    // MARK: - 系统日历同步开关区域（一级页面）
    private var systemCalendarToggleSection: some View {
        MD3Card(type: .elevated) {
            VStack(alignment: .leading, spacing: BrandSpacing.lg) {
                // 主标题行
                HStack {
                    Text(L10n.systemCalendarSync)
                        .font(BrandFont.body(size: 18, weight: .bold))
                        .foregroundColor(BrandColor.neutral900)

                    Spacer()

                    // 会员功能标识
                    HStack(spacing: 4) {
                        Image(systemName: purchaseManager.isPremiumUnlocked ? "crown.fill" : "crown")
                            .font(.caption)
                            .foregroundColor(purchaseManager.isPremiumUnlocked ? .yellow : BrandColor.neutral500)
                        Text(purchaseManager.isPremiumUnlocked ? "已解锁" : "会员")
                            .font(BrandFont.body(size: 12, weight: .bold))
                            .foregroundColor(purchaseManager.isPremiumUnlocked ? BrandColor.success : .orange)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(purchaseManager.isPremiumUnlocked ? BrandColor.success.opacity(0.1) : .orange.opacity(0.1))
                            .stroke(purchaseManager.isPremiumUnlocked ? BrandColor.success.opacity(0.3) : .orange.opacity(0.3), lineWidth: 1)
                    )
                }

                // 描述和开关行
                HStack {
                    Text("与系统日历双向同步")
                        .font(BrandFont.body(size: 14, weight: .medium))
                        .foregroundColor(BrandColor.neutral700)

                    Spacer()

                    // 同步开关
                    Toggle("", isOn: Binding(
                        get: {
                            systemCalendarManager.syncEnabled &&
                            systemCalendarManager.hasCalendarAccess &&
                            purchaseManager.isPremiumUnlocked
                        },
                        set: { isEnabled in
                            if !purchaseManager.isPremiumUnlocked {
                                showingPremiumView = true
                                return
                            }

                            Task {
                                if isEnabled {
                                    let hasPermission = await systemCalendarManager.requestCalendarPermission()
                                    if hasPermission {
                                        await systemCalendarManager.enableSync()
                                    }
                                } else {
                                    systemCalendarManager.disableSync()
                                }
                            }
                        }
                    ))
                    .toggleStyle(SwitchToggleStyle(tint: BrandColor.primary))
                    .disabled(!purchaseManager.isPremiumUnlocked)
                }

                // 详细设置入口
                if systemCalendarManager.syncEnabled && purchaseManager.isPremiumUnlocked {
                    NavigationLink(destination: SystemCalendarSyncView()) {
                        HStack {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 14))
                                .foregroundColor(BrandColor.primaryBlue)

                            Text("详细同步设置")
                                .font(BrandFont.body(size: 14, weight: .medium))
                                .foregroundColor(BrandColor.primaryBlue)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(BrandColor.neutral500)
                        }
                        .padding(.top, BrandSpacing.sm)
                    }
                }
            }
        }
    }

    // MARK: - 法律条款区域（缩小版本）
    private var legalSection: some View {
        VStack(alignment: .leading, spacing: BrandSpacing.sm) {
            HStack {
                Text("📄")
                    .font(.system(size: 14))
                Text(L10n.legalInfo)
                    .font(BrandFont.body(size: 14, weight: .bold))
                    .foregroundColor(BrandColor.neutral700)
                Spacer()
            }

            HStack(spacing: BrandSpacing.lg) {
                Button(action: openTermsOfService) {
                    Text(L10n.termsOfService)
                        .font(BrandFont.body(size: 13, weight: .medium))
                        .foregroundColor(BrandColor.primaryBlue)
                }

                Button(action: openPrivacyPolicy) {
                    Text(L10n.privacyPolicy)
                        .font(BrandFont.body(size: 13, weight: .medium))
                        .foregroundColor(BrandColor.primaryBlue)
                }

                Spacer()
            }

            Text("联系我们：iamtotalchan@gmail.com")
                .font(BrandFont.body(size: 11, weight: .medium))
                .foregroundColor(BrandColor.neutral500)
                .padding(.top, 2)
        }
        .padding(BrandSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: BrandRadius.sm)
                .fill(BrandColor.neutral100.opacity(0.5))
        )
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

#Preview {
    SettingsView()
}
