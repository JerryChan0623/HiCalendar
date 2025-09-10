//
//  ContentView.swift
//  HiCalendar
//
//  Created by Jerry  on 2025/8/8.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var isSettingsPresented = false
    @State private var showAIChatSheet = false
    @State private var showVoiceRecordingOverlay = false
    @State private var showGlobalEventAdd = false
    @StateObject private var voiceManager = AIVoiceManager.shared
    @StateObject private var pushManager = PushNotificationManager.shared
    @Environment(\.colorScheme) var colorScheme
    
    // 权限弹框状态
    @State private var showPushPermissionAlert = false
    @State private var isFirstLaunch = true
    
    var body: some View {
        ZStack {
            // 使用 TabView 实现滑动切换
            TabView(selection: $selectedTab) {
                NavigationStack {
                    MainCalendarAIView()
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button {
                                    isSettingsPresented = true
                                } label: {
                                    ColorfulIcon(.settings, size: 22)
                                }
                            }
                        }
                }
                .tag(0)
                .fullScreenCover(isPresented: $isSettingsPresented) {
                    SettingsView()
                }
                
                EverythingsView()
                    .tag(1)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never)) // 隐藏页面指示器
            .animation(.easeInOut(duration: 0.3), value: selectedTab)
            
            // 底部栏：Tab切换 + 添加按钮
            VStack {
                Spacer()
                HStack(spacing: BrandSpacing.md) {
                    // 左侧：Tab切换组
                    CustomTabBar(
                        selectedTab: $selectedTab
                    )
                    
                    // 右侧：全局添加按钮
                    GlobalAddButton(
                        showGlobalEventAdd: $showGlobalEventAdd
                    )
                }
                .padding(.horizontal, BrandSpacing.xl)
                .padding(.bottom, BrandSpacing.lg)
            }
            .ignoresSafeArea(.keyboard)
        }
        .ignoresSafeArea() // 忽略所有安全区域
        // 改为整页AI聊天页面，避免浮层定位问题
        .sheet(isPresented: $showAIChatSheet) {
            AIChatView()
                .presentationDragIndicator(.visible)
                .presentationDetents([.large])
        }
        .overlay(
            // 录音蒙层
            showVoiceRecordingOverlay ?
            VoiceRecordingOverlay(
                isPresented: $showVoiceRecordingOverlay,
                voiceManager: voiceManager
            )
                .transition(.opacity) : nil
        )
        .onAppear {
            // 首次启动时请求推送权限
            if isFirstLaunch {
                checkAndRequestPushPermission()
                isFirstLaunch = false
            }
        }
        .sheet(isPresented: $showGlobalEventAdd) {
            VStack(spacing: 0) {
                // 自定义Sheet Header
                NeobrutalismSheetHeader()
                
                EventEditView(
                    mode: .create,
                    initialDate: Calendar.current.startOfDay(for: Date()),
                    onSave: {
                        showGlobalEventAdd = false
                    }
                )
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
        }
        .alert("开启推送通知", isPresented: $showPushPermissionAlert) {
            Button("开启") {
                Task {
                    let granted = await pushManager.requestPermission()
                    if !granted {
                        // 可以考虑显示设置引导
                        print("用户拒绝了推送权限")
                    }
                }
            }
            Button("稍后") {
                // 用户选择稍后，不做额外处理
                print("用户选择稍后开启推送")
            }
        } message: {
            Text("为了及时提醒你的重要事项，HiCalendar需要推送通知权限。我们的推送文案很有趣哦～")
        }
    }
    
    // MARK: - 权限管理方法
    private func checkAndRequestPushPermission() {
        // 检查推送权限状态
        pushManager.checkNotificationPermission()
        
        // 延迟一秒后检查是否需要显示权限弹框
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if !pushManager.isPermissionGranted {
                showPushPermissionAlert = true
            }
        }
    }
    
    private func requestVoicePermissionAndStartRecording() {
        Task {
            // 请求语音权限
            voiceManager.requestPermissions()
            
            // 给一点时间让权限弹框处理完毕
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5秒
            
            // 检查权限是否授予，如果是则开始录音
            if voiceManager.hasPermission {
                DispatchQueue.main.async {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
                    impactFeedback.impactOccurred()
                    showVoiceRecordingOverlay = true
                    
                    // 延迟开始录音
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        if showVoiceRecordingOverlay {
                            voiceManager.startListening()
                        }
                    }
                }
            } else {
                // 权限被拒绝，显示文字聊天界面
                DispatchQueue.main.async {
                    showAIChatSheet = true
                }
            }
        }
    }
}

// 简化的 TabBar 组件（只包含Tab切换）
struct CustomTabBar: View {
    @Binding var selectedTab: Int
    @Environment(\.colorScheme) var colorScheme
    @Namespace private var animation
    
    let tabs: [(title: String, iconType: ColorfulIcon.IconType)] = [
        ("看日子", .calendar),
        ("全部安排", .list)
    ]
    
    var body: some View {
        HStack(spacing: BrandSpacing.sm) {
            // 第一个Tab按钮
            TabBarButton(
                title: tabs[0].title,
                iconType: tabs[0].iconType,
                isSelected: selectedTab == 0,
                animation: animation
            ) {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                    selectedTab = 0
                }
            }
            
            // 第二个Tab按钮
            TabBarButton(
                title: tabs[1].title,
                iconType: tabs[1].iconType,
                isSelected: selectedTab == 1,
                animation: animation
            ) {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                    selectedTab = 1
                }
            }
        }
        .padding(.horizontal, BrandSpacing.md)
        .padding(.vertical, BrandSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: BrandRadius.lg, style: .continuous)
                .fill(BrandColor.surface.opacity(colorScheme == .dark ? 0.95 : 0.95))
                .background(
                    RoundedRectangle(cornerRadius: BrandRadius.lg, style: .continuous)
                        .fill(.regularMaterial)
                )
                .shadow(
                    color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.05),
                    radius: 12,
                    x: 0,
                    y: -2
                )
        )
    }
}

// TabBar 按钮组件
struct TabBarButton: View {
    let title: String
    let iconType: ColorfulIcon.IconType
    let isSelected: Bool
    let animation: Namespace.ID
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                ColorfulTabIcon(iconType, isSelected: isSelected, size: 18)
                
                Text(title)
                    .font(.system(size: 10, weight: isSelected ? .medium : .regular))
                    .foregroundColor(isSelected ? BrandColor.onPrimaryContainer : BrandColor.onSurfaceVariant.opacity(0.5))
                    .animation(.easeInOut(duration: 0.15), value: isSelected)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background {
                if isSelected {
                    // 选中背景 - 包含整个按钮区域
                    RoundedRectangle(cornerRadius: BrandRadius.md, style: .continuous)
                        .fill(BrandColor.primaryContainer.opacity(0.8))
                        .matchedGeometryEffect(id: "TAB", in: animation)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// 独立的AI助手按钮组件
struct IndependentAIButton: View {
    @Binding var showAIChatSheet: Bool
    @Binding var showVoiceRecordingOverlay: Bool
    @ObservedObject var voiceManager: AIVoiceManager
    let requestVoicePermission: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                // 动态背景
                if voiceManager.isListening || voiceManager.isProcessing {
                    Capsule()
                        .fill(voiceManager.isListening ? BrandColor.danger.opacity(0.15) : BrandColor.primaryBlue.opacity(0.15))
                        .frame(width: 54, height: 32)
                        .animation(.easeInOut(duration: 0.2), value: voiceManager.isListening)
                }
                
                // AI图标 - 保持一致风格
                if voiceManager.isListening {
                    ColorfulIcon(.microphone, size: 22, weight: .bold)
                } else if voiceManager.isProcessing {
                    ColorfulIcon(.sparkles, size: 22, weight: .bold)
                        .opacity(0.7)
                } else {
                    ColorfulIcon(.sparkles, size: 20, weight: .semibold)
                }
            }
            .frame(height: 32)
            .scaleEffect(voiceManager.isListening ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: voiceManager.isListening)
            
            // 状态标签
            Group {
                if voiceManager.isListening {
                    Text("录音中")
                        .foregroundColor(BrandColor.danger)
                } else if voiceManager.isProcessing {
                    Text("处理中")
                        .foregroundColor(BrandColor.primaryBlue)
                } else {
                    Text("AI助手")
                        .foregroundColor(BrandColor.onSurfaceVariant.opacity(0.7))
                }
            }
            .font(.system(size: 10, weight: .medium))
            .animation(.easeInOut(duration: 0.15), value: voiceManager.isListening || voiceManager.isProcessing)
        }
        .frame(width: 72, height: 60)
        .background(
            RoundedRectangle(cornerRadius: BrandRadius.lg, style: .continuous)
                .fill(BrandColor.surface.opacity(colorScheme == .dark ? 0.95 : 0.95))
                .background(
                    RoundedRectangle(cornerRadius: BrandRadius.lg, style: .continuous)
                        .fill(.regularMaterial)
                )
                .shadow(
                    color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.05),
                    radius: 12,
                    x: 0,
                    y: -2
                )
        )
        .onTapGesture {
            // 单击 - 显示输入框
            if !voiceManager.isListening {
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                showAIChatSheet = true
            }
        }
        .onLongPressGesture(minimumDuration: 0.5, maximumDistance: 50) {
            // 长按处理
        } onPressingChanged: { isPressing in
            if isPressing {
                // 开始长按 - 检查语音权限
                if voiceManager.hasPermission {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
                    impactFeedback.impactOccurred()
                    showVoiceRecordingOverlay = true
                    
                    // 延迟0.5s后开始录音
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        if showVoiceRecordingOverlay {
                            voiceManager.startListening()
                        }
                    }
                } else {
                    // 请求语音权限
                    requestVoicePermission()
                }
            } else {
                // 松开长按
                showVoiceRecordingOverlay = false
                if voiceManager.isListening {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                    voiceManager.stopListening()
                }
            }
        }
    }
}

// 全局添加按钮组件
struct GlobalAddButton: View {
    @Binding var showGlobalEventAdd: Bool
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: {
            showGlobalEventAdd = true
        }) {
            VStack(spacing: 2) {
                ColorfulIcon(.plus, size: 22)
                    .frame(height: 32)
                
                Text("添加")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(BrandColor.onSurfaceVariant.opacity(0.7))
            }
        }
        .frame(width: 72, height: 60)
        .background(
            RoundedRectangle(cornerRadius: BrandRadius.lg, style: .continuous)
                .fill(BrandColor.surface.opacity(colorScheme == .dark ? 0.95 : 0.95))
                .background(
                    RoundedRectangle(cornerRadius: BrandRadius.lg, style: .continuous)
                        .fill(.regularMaterial)
                )
                .shadow(
                    color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.05),
                    radius: 12,
                    x: 0,
                    y: -2
                )
        )
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ContentView()
}
