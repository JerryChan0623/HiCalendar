//
//  SettingsView.swift
//  HiCalendar
//
//  Created on 2024. Cute Calendar AI 设置页
//

import SwiftUI
import PhotosUI

struct SettingsView: View {
    @StateObject private var backgroundManager = BackgroundImageManager.shared
    @StateObject private var supabaseManager = SupabaseManager.shared
    @StateObject private var pushManager = PushNotificationManager.shared
    @State private var showingPhotoPicker = false
    @State private var selectedImage: UIImage?
    @State private var showingRemoveAlert = false
    @State private var showingCropView = false
    @State private var croppedImage: UIImage?
    @State private var showingSignOutAlert = false
    @Environment(\.dismiss) private var dismiss
    
    @ViewBuilder
    private var mainContent: some View {
        VStack(spacing: BrandSpacing.xl) {
            // 用户信息/登录区域
            if supabaseManager.isAuthenticated {
                userSection
            } else {
                signInSection
            }
            
            // 推送通知设置区域
            pushNotificationSection
            
            // 背景设置区域
            backgroundSection
            
            // 登出按钮（仅登录后显示）
            if supabaseManager.isAuthenticated {
                signOutSection
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
                    AppleSignInButton()
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
    
    // MARK: - 登出方法
    private func signOut() {
        Task {
            try? await supabaseManager.signOut()
            await MainActor.run {
                showingSignOutAlert = false
            }
        }
    }
}

#Preview {
    SettingsView()
}

