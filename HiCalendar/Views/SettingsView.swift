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
                premiumSection
                pushNotificationSection
                backgroundSection
                widgetDebugSection
                signOutSection
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
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("返回")
                                .font(.system(size: 17))
                        }
                        .foregroundColor(BrandColor.primary)
                    }
                }
            }
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
                title: "真的不要了？",
                message: "真的不要这张美图了吗？删了可就没了哦 🥺",
                isPresented: $showingRemoveAlert
            ) {
                HStack(spacing: BrandSpacing.lg) {
                    Button("我再想想") {
                        showingRemoveAlert = false
                    }
                    .buttonStyle(MD3ButtonStyle(type: .text))
                    
                    Button("不要了！") {
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
                title: "要走了吗？",
                message: "真的要走了吗？下次记得回来哦 👋",
                isPresented: $showingSignOutAlert
            ) {
                HStack(spacing: BrandSpacing.lg) {
                    Button("我再想想") {
                        showingSignOutAlert = false
                    }
                    .buttonStyle(MD3ButtonStyle(type: .text))
                    
                    Button("拜拜～") {
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
                    Text("看看是谁在这儿 👀")
                        .font(BrandFont.body(size: 18, weight: .bold))
                        .foregroundColor(BrandColor.neutral900)
                    
                    Spacer()
                    
                    Image(systemName: "person.circle.fill")
                        .font(.title2)
                        .foregroundColor(BrandColor.primaryBlue)
                }
                
                VStack(alignment: .leading, spacing: BrandSpacing.sm) {
                    Text("就是你啦～")
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
                
                Text("溜了溜了 👋")
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
            VStack(alignment: .leading, spacing: BrandSpacing.lg) {
                // 标题
                HStack {
                    Text("给日历换个皮肤 🎨")
                        .font(BrandFont.body(size: 18, weight: .bold))
                        .foregroundColor(BrandColor.neutral900)
                    
                    Spacer()
                    
                    Image(systemName: "photo.on.rectangle")
                        .font(.title2)
                        .foregroundColor(BrandColor.primaryBlue)
                }
                
                // 当前背景预览
                if backgroundManager.hasCustomBackground, let image = backgroundManager.backgroundImage {
                    VStack(spacing: BrandSpacing.md) {
                        Text("现在的装扮")
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
                        Button("不要这张了啦") {
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
                        Text("还没换装呢，素颜也挺好 ✨")
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
                                    Text("朴素美也是美")
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
                        
                        Text(backgroundManager.hasCustomBackground ? "更换背景图片" : "选择背景图片")
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
                Text("挑张好看的图，让日历也美美哒～记得选清晰的哦，不然字都看不清就尴尬了 😅")
                    .font(BrandFont.bodySmall)
                    .foregroundColor(BrandColor.neutral500)
                    .multilineTextAlignment(.leading)
            }
        }
    }
    
    // MARK: - 推送通知设置区域
    private var pushNotificationSection: some View {
        MD3Card(type: .elevated) {
            VStack(alignment: .leading, spacing: BrandSpacing.lg) {
                // 标题
                HStack {
                    Text("通知提醒设置 🔔")
                        .font(BrandFont.body(size: 18, weight: .bold))
                        .foregroundColor(BrandColor.neutral900)
                    
                    Spacer()
                    
                    // 权限状态指示器
                    Circle()
                        .fill(pushManager.isPermissionGranted ? BrandColor.success : BrandColor.danger)
                        .frame(width: 8, height: 8)
                }
                
                // 权限状态
                if !pushManager.isPermissionGranted {
                    VStack(alignment: .leading, spacing: BrandSpacing.md) {
                        Text("推送通知未开启")
                            .font(BrandFont.body(size: 16, weight: .medium))
                            .foregroundColor(BrandColor.danger)
                        
                        Text("开启通知后可以在事件前收到贴心（嘴贱）提醒哦～")
                            .font(BrandFont.body(size: 14, weight: .medium))
                            .foregroundColor(BrandColor.neutral500)
                        
                        Button("开启推送通知") {
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
                                Text("事件前1天提醒")
                                    .font(BrandFont.body(size: 16, weight: .medium))
                                Text("默认开启，提前一天叫醒你")
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
                                Text("事件前1周提醒")
                                    .font(BrandFont.body(size: 16, weight: .medium))
                                Text("提前一周开始准备，从容不迫")
                                    .font(BrandFont.body(size: 12, weight: .regular))
                                    .foregroundColor(BrandColor.neutral500)
                            }
                        }
                        .toggleStyle(SwitchToggleStyle(tint: BrandColor.primary))
                        
                        
                        // 测试推送按钮
                        Button("发送测试通知 🧪") {
                            pushManager.sendTestNotification()
                        }
                        .buttonStyle(MD3ButtonStyle(type: .outlined))
                        .font(BrandFont.body(size: 14, weight: .medium))
                    }
                }
            }
        }
    }
    
    
    // MARK: - Pro功能区域
    private var premiumSection: some View {
        MD3Card(type: .elevated) {
            VStack(spacing: BrandSpacing.lg) {
                // 头部区域
                HStack {
                    HStack(spacing: BrandSpacing.sm) {
                        // Pro图标
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [BrandColor.primaryYellow, BrandColor.primaryBlue],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 32, height: 32)

                            Text("⭐")
                                .font(.system(size: 16))
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(purchaseManager.isPremiumUnlocked ? "HiCalendar Pro" : "升级到 Pro")
                                .font(BrandFont.body(size: 18, weight: .bold))
                                .foregroundColor(BrandColor.neutral900)

                            Text(purchaseManager.isPremiumUnlocked ? "已解锁全部功能 🎉" : "解锁云同步和小组件")
                                .font(BrandFont.body(size: 14, weight: .medium))
                                .foregroundColor(BrandColor.neutral500)
                        }
                    }

                    Spacer()

                    if purchaseManager.isPremiumUnlocked {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(BrandColor.success)
                    } else {
                        Image(systemName: "arrow.right.circle")
                            .font(.title2)
                            .foregroundColor(BrandColor.primaryBlue)
                    }
                }

                if !purchaseManager.isPremiumUnlocked {
                    // 功能预览
                    VStack(spacing: BrandSpacing.sm) {
                        // 云同步功能
                        HStack(spacing: BrandSpacing.md) {
                            ZStack {
                                Circle()
                                    .fill(BrandColor.primaryBlue.opacity(0.1))
                                    .frame(width: 36, height: 36)

                                Text("☁️")
                                    .font(.system(size: 18))
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("云端同步")
                                    .font(BrandFont.body(size: 14, weight: .bold))
                                    .foregroundColor(BrandColor.neutral900)

                                Text("多设备同步，数据永不丢失")
                                    .font(BrandFont.body(size: 12, weight: .medium))
                                    .foregroundColor(BrandColor.neutral500)
                            }

                            Spacer()

                            Image(systemName: "lock.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(BrandColor.outline)
                        }

                        // 小组件功能
                        HStack(spacing: BrandSpacing.md) {
                            ZStack {
                                Circle()
                                    .fill(BrandColor.primaryYellow.opacity(0.1))
                                    .frame(width: 36, height: 36)

                                Text("📱")
                                    .font(.system(size: 18))
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("桌面小组件")
                                    .font(BrandFont.body(size: 14, weight: .bold))
                                    .foregroundColor(BrandColor.neutral900)

                                Text("主屏幕直接查看今日事项")
                                    .font(BrandFont.body(size: 12, weight: .medium))
                                    .foregroundColor(BrandColor.neutral500)
                            }

                            Spacer()

                            Image(systemName: "lock.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(BrandColor.outline)
                        }
                    }

                    // 升级按钮
                    Button(action: {
                        showingPremiumView = true
                    }) {
                        HStack(spacing: BrandSpacing.sm) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)

                            Text("立即升级")
                                .font(BrandFont.body(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, BrandSpacing.md)
                        .background(
                            LinearGradient(
                                colors: [BrandColor.primaryYellow, BrandColor.primaryBlue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(BrandRadius.md)
                        .neobrutalStyle(cornerRadius: BrandRadius.md, borderWidth: BrandBorder.regular)
                    }
                } else {
                    // 已购买用户显示状态管理按钮
                    VStack(spacing: BrandSpacing.sm) {
                        // 功能状态
                        VStack(spacing: BrandSpacing.xs) {
                            HStack {
                                Text("☁️ 云端同步")
                                    .font(BrandFont.body(size: 14, weight: .medium))
                                Spacer()
                                Text("已激活")
                                    .font(BrandFont.body(size: 12, weight: .medium))
                                    .foregroundColor(BrandColor.success)
                            }

                            HStack {
                                Text("📱 桌面小组件")
                                    .font(BrandFont.body(size: 14, weight: .medium))
                                Spacer()
                                Text("已激活")
                                    .font(BrandFont.body(size: 12, weight: .medium))
                                    .foregroundColor(BrandColor.success)
                            }
                        }

                        // 调试按钮组
                        VStack(spacing: BrandSpacing.sm) {
                            // 刷新状态按钮
                            Button(action: {
                                Task {
                                    print("🔄 用户手动刷新购买状态")

                                    // 先打印当前状态
                                    purchaseManager.debugPurchaseStatus()

                                    await purchaseManager.loadProducts()
                                    await purchaseManager.manualRefreshStatus()

                                    // 再次打印刷新后状态
                                    purchaseManager.debugPurchaseStatus()
                                }
                            }) {
                                HStack(spacing: BrandSpacing.xs) {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.system(size: 14, weight: .medium))

                                    Text("刷新状态")
                                        .font(BrandFont.body(size: 14, weight: .medium))
                                }
                                .foregroundColor(BrandColor.primaryBlue)
                                .padding(.vertical, BrandSpacing.sm)
                                .padding(.horizontal, BrandSpacing.md)
                                .background(
                                    RoundedRectangle(cornerRadius: BrandRadius.sm)
                                        .fill(BrandColor.primaryBlue.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: BrandRadius.sm)
                                                .stroke(BrandColor.primaryBlue.opacity(0.3), lineWidth: 1)
                                        )
                                )
                            }

                            // 恢复购买按钮
                            Button(action: {
                                Task {
                                    print("🔄 用户尝试恢复购买")
                                    await purchaseManager.restorePurchases()
                                }
                            }) {
                                HStack(spacing: BrandSpacing.xs) {
                                    Image(systemName: "arrow.down.circle")
                                        .font(.system(size: 14, weight: .medium))

                                    Text("恢复购买")
                                        .font(BrandFont.body(size: 14, weight: .medium))
                                }
                                .foregroundColor(BrandColor.success)
                                .padding(.vertical, BrandSpacing.sm)
                                .padding(.horizontal, BrandSpacing.md)
                                .background(
                                    RoundedRectangle(cornerRadius: BrandRadius.sm)
                                        .fill(BrandColor.success.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: BrandRadius.sm)
                                                .stroke(BrandColor.success.opacity(0.3), lineWidth: 1)
                                        )
                                )
                            }

                            // Widget状态测试按钮
                            Button(action: {
                                testWidgetStatusSync()
                            }) {
                                HStack(spacing: BrandSpacing.xs) {
                                    Image(systemName: "widget.large")
                                        .font(.system(size: 14, weight: .medium))

                                    Text("测试Widget同步")
                                        .font(BrandFont.body(size: 14, weight: .medium))
                                }
                                .foregroundColor(BrandColor.primaryYellow)
                                .padding(.vertical, BrandSpacing.sm)
                                .padding(.horizontal, BrandSpacing.md)
                                .background(
                                    RoundedRectangle(cornerRadius: BrandRadius.sm)
                                        .fill(BrandColor.primaryYellow.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: BrandRadius.sm)
                                                .stroke(BrandColor.primaryYellow.opacity(0.3), lineWidth: 1)
                                        )
                                )
                            }

                            // 清除测试数据按钮
                            Button(action: {
                                clearAppGroupsTestData()
                            }) {
                                HStack(spacing: BrandSpacing.xs) {
                                    Image(systemName: "trash.circle")
                                        .font(.system(size: 14, weight: .medium))

                                    Text("清除测试数据")
                                        .font(BrandFont.body(size: 14, weight: .medium))
                                }
                                .foregroundColor(BrandColor.danger)
                                .padding(.vertical, BrandSpacing.sm)
                                .padding(.horizontal, BrandSpacing.md)
                                .background(
                                    RoundedRectangle(cornerRadius: BrandRadius.sm)
                                        .fill(BrandColor.danger.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: BrandRadius.sm)
                                                .stroke(BrandColor.danger.opacity(0.3), lineWidth: 1)
                                        )
                                )
                            }
                        }
                    }
                }
            }
            .padding(BrandSpacing.lg)
        }
    }

    // MARK: - Apple登录区域
    private var signInSection: some View {
        MD3Card(type: .elevated) {
            VStack(spacing: BrandSpacing.lg) {
                HStack {
                    Text("快来登录呀 🎪")
                        .font(BrandFont.body(size: 18, weight: .bold))
                        .foregroundColor(BrandColor.neutral900)
                    
                    Spacer()
                    
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.title2)
                        .foregroundColor(BrandColor.primaryBlue)
                }
                
                VStack(spacing: BrandSpacing.md) {
                    Text("登录了就能在云端备份，妈妈再也不怕我丢数据了 ☁️")
                        .font(BrandFont.body(size: 14, weight: .medium))
                        .foregroundColor(BrandColor.neutral500)
                        .multilineTextAlignment(.center)
                    
                    // Apple登录按钮
                    AppleSignInButton {
                        // 点击登录时检查推送权限
                        checkPushPermissionBeforeLogin()
                    }
                    .padding(.top, BrandSpacing.sm)
                    
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
    
    // MARK: - Widget调试区域
    private var widgetDebugSection: some View {
        MD3Card(type: .elevated) {
            VStack(alignment: .leading, spacing: BrandSpacing.md) {
                HStack {
                    Image(systemName: "app.badge")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(BrandColor.primaryBlue)
                    
                    Text("Widget调试")
                        .font(BrandFont.body(size: 16, weight: .bold))
                        .foregroundColor(BrandColor.onSurface)
                    
                    Spacer()
                }
                
                if purchaseManager.canUseWidget {
                    Text("如果Widget没有显示最新数据，可以尝试手动同步")
                        .font(BrandFont.body(size: 14, weight: .regular))
                        .foregroundColor(BrandColor.onSurface.opacity(0.7))
                } else {
                    Text("Widget功能需要升级到Pro版本才能使用")
                        .font(BrandFont.body(size: 14, weight: .regular))
                        .foregroundColor(BrandColor.danger)
                }
                
                Button(action: {
                    if purchaseManager.canUseWidget {
                        // 手动强制同步Widget数据
                        EventStorageManager.shared.forceWidgetSync()

                        // 触发触觉反馈
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                    } else {
                        // 显示升级页面
                        showingPremiumView = true
                    }
                }) {
                    HStack {
                        Image(systemName: purchaseManager.canUseWidget ? "arrow.clockwise" : "lock")
                            .font(.system(size: 16, weight: .medium))
                        Text(purchaseManager.canUseWidget ? "同步Widget数据" : "升级解锁Widget")
                            .font(BrandFont.body(size: 16, weight: .medium))
                    }
                }
                .buttonStyle(MD3ButtonStyle(type: purchaseManager.canUseWidget ? .filled : .outlined))
                
                Button(action: {
                    if purchaseManager.canUseWidget {
                        // 强制刷新所有Widget
                        WidgetCenter.shared.reloadAllTimelines()

                        // 触发触觉反馈
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                    } else {
                        // 显示升级页面
                        showingPremiumView = true
                    }
                }) {
                    HStack {
                        Image(systemName: purchaseManager.canUseWidget ? "widget.small" : "lock")
                            .font(.system(size: 16, weight: .medium))
                        Text(purchaseManager.canUseWidget ? "刷新Widget显示" : "升级解锁Widget")
                            .font(BrandFont.body(size: 16, weight: .medium))
                    }
                }
                .buttonStyle(MD3ButtonStyle(type: .outlined))
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

    // MARK: - Widget调试方法
    private func testWidgetStatusSync() {
        print("🧪 开始测试Widget状态同步...")

        // 检查购买状态
        let isPremium = purchaseManager.isPremiumUnlocked
        print("📱 当前购买状态: \(isPremium)")

        // 检查App Groups
        if let sharedDefaults = UserDefaults(suiteName: "group.com.chenzhencong.HiCalendar") {
            let widgetStatus = sharedDefaults.bool(forKey: "premium_unlocked")
            let timestamp = sharedDefaults.double(forKey: "premium_status_updated_at")
            print("📱 Widget状态: \(widgetStatus)")
            print("⏰ 更新时间: \(Date(timeIntervalSince1970: timestamp))")

            // 强制刷新Widget
            if #available(iOS 14.0, *) {
                WidgetCenter.shared.reloadAllTimelines()
                print("🔄 已强制刷新Widget")
            }
        } else {
            print("❌ 无法访问App Groups")
        }
    }

    private func clearAppGroupsTestData() {
        print("🧹 开始清除App Groups测试数据...")

        guard let sharedDefaults = UserDefaults(suiteName: "group.com.chenzhencong.HiCalendar") else {
            print("❌ 无法访问App Groups")
            return
        }

        // 清除购买状态
        sharedDefaults.removeObject(forKey: "premium_unlocked")
        sharedDefaults.removeObject(forKey: "premium_status_updated_at")

        // 清除事件数据（如果有的话）
        sharedDefaults.removeObject(forKey: "shared_events")

        sharedDefaults.synchronize()
        print("✅ App Groups数据已清除")

        // 刷新Widget显示
        if #available(iOS 14.0, *) {
            WidgetCenter.shared.reloadAllTimelines()
            print("🔄 已刷新Widget显示")
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
                    Text("登录后解锁更多设置")
                        .font(BrandFont.body(size: 18, weight: .bold))
                        .foregroundColor(BrandColor.onSurface)
                    Spacer()
                }

                // 登录功能
                VStack(spacing: BrandSpacing.md) {
                    benefitItem(
                        icon: "🎨",
                        title: "个性化背景设置",
                        description: "自定义日历背景图片，让界面独一无二"
                    )
                }

                Divider()
                    .background(BrandColor.onSurface.opacity(0.2))

                // 会员功能标题
                HStack {
                    Text("⭐")
                        .font(.system(size: 20))
                    Text("成为会员解锁云端功能")
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
                        title: "桌面小组件",
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
}

#Preview {
    SettingsView()
}

