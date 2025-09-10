//
//  VoiceAssistantView.swift
//  HiCalendar
//
//  Created on 2024. AI语音助手界面组件
//

import SwiftUI

// MARK: - 语音助手主界面
struct VoiceAssistantView: View {
    @StateObject private var voiceManager = AIVoiceManager.shared
    @StateObject private var storageManager = EventStorageManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingPermissionAlert = false
    @State private var conversationHistory: [ConversationMessage] = []
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 自定义header
                customHeader
                
                // 对话历史区域
                conversationArea
                
                // 语音控制区域
                voiceControlArea
            }
            .background(
                LinearGradient(
                    colors: [
                        BrandColor.background,
                        BrandColor.background.opacity(0.9)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .alert("需要权限", isPresented: $showingPermissionAlert) {
                Button("设置") {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }
                Button("取消", role: .cancel) { }
            } message: {
                Text("语音助手需要麦克风和语音识别权限才能正常工作")
            }
        }
        .onAppear {
            checkPermissions()
        }
        .onChange(of: voiceManager.recognizedText) { _, newText in
            if !newText.isEmpty && !voiceManager.isListening {
                addMessage(ConversationMessage(content: newText, isUser: true))
            }
        }
        .onChange(of: voiceManager.aiResponse) { _, newResponse in
            if !newResponse.isEmpty {
                addMessage(ConversationMessage(content: newResponse, isUser: false))
            }
        }
    }
    
    // MARK: - 自定义Header
    private var customHeader: some View {
        VStack(spacing: BrandSpacing.sm) {
            HStack {
                Button("完成") {
                    dismiss()
                }
                .font(BrandFont.body(size: 16, weight: .medium))
                .foregroundColor(BrandColor.primaryBlue)
                
                Spacer()
                
                Text("AI语音助手")
                    .font(BrandFont.display(size: 20, weight: .bold))
                    .foregroundColor(BrandColor.onSurface)
                
                Spacer()
                
                Button(action: {
                    clearConversation()
                }) {
                    ColorfulIcon(.sparkles, size: 20)
                }
            }
            .padding(.horizontal, BrandSpacing.lg)
            .padding(.top, BrandSpacing.sm)
            
            // 状态指示器
            statusIndicator
                .padding(.horizontal, BrandSpacing.lg)
        }
        .padding(.bottom, BrandSpacing.md)
    }
    
    // MARK: - 状态指示器
    private var statusIndicator: some View {
        HStack(spacing: BrandSpacing.sm) {
            statusDot
            statusText
            Spacer()
            
            if voiceManager.isProcessing {
                ProgressView()
                    .scaleEffect(0.8)
                    .tint(BrandColor.primaryBlue)
            }
        }
        .padding(.horizontal, BrandSpacing.md)
        .padding(.vertical, BrandSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: BrandRadius.md)
                .fill(statusBackgroundColor)
        )
    }
    
    private var statusDot: some View {
        Circle()
            .fill(statusColor)
            .frame(width: 8, height: 8)
            .scaleEffect(voiceManager.isListening ? 1.5 : 1.0)
            .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: voiceManager.isListening)
    }
    
    private var statusText: some View {
        Text(currentStatusText)
            .font(BrandFont.body(size: 12, weight: .medium))
            .foregroundColor(statusColor)
    }
    
    private var currentStatusText: String {
        if !voiceManager.hasPermission {
            return "需要麦克风权限"
        } else if voiceManager.isListening {
            return "正在聆听..."
        } else if voiceManager.isProcessing {
            return "AI思考中..."
        } else if voiceManager.isSpeaking {
            return "AI回复中..."
        } else {
            return "准备就绪"
        }
    }
    
    private var statusColor: Color {
        if !voiceManager.hasPermission {
            return BrandColor.danger
        } else if voiceManager.isListening {
            return BrandColor.primaryBlue
        } else if voiceManager.isProcessing || voiceManager.isSpeaking {
            return BrandColor.primaryYellow
        } else {
            return BrandColor.success
        }
    }
    
    private var statusBackgroundColor: Color {
        statusColor.opacity(0.1)
    }
    
    // MARK: - 对话历史区域
    private var conversationArea: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: BrandSpacing.md) {
                    if conversationHistory.isEmpty {
                        emptyConversationState
                    } else {
                        ForEach(conversationHistory) { message in
                            ConversationBubble(message: message)
                                .id(message.id)
                        }
                    }
                }
                .padding(.horizontal, BrandSpacing.lg)
                .padding(.vertical, BrandSpacing.md)
            }
            .onChange(of: conversationHistory.count) { _, _ in
                if let lastMessage = conversationHistory.last {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }
    
    private var emptyConversationState: some View {
        VStack(spacing: BrandSpacing.lg) {
            AnimatedEmptyStateView(
                type: .noEvents,
                message: "按住按钮开始与AI对话\n你可以说: \"明天三点开会\" 或 \"今天有什么安排？\"",
                size: 100
            )
            
            // 快捷命令建议
            VStack(alignment: .leading, spacing: BrandSpacing.sm) {
                Text("试试这些语音命令:")
                    .font(BrandFont.body(size: 14, weight: .bold))
                    .foregroundColor(BrandColor.onSurface)
                
                ForEach(quickCommands, id: \.self) { command in
                    Button(action: {
                        simulateVoiceCommand(command)
                    }) {
                        HStack {
                            ColorfulIcon(.microphone, size: 14)
                            Text("\"\(command)\"")
                                .font(BrandFont.body(size: 13, weight: .medium))
                                .foregroundColor(BrandColor.onSurface.opacity(0.8))
                            Spacer()
                        }
                        .padding(.horizontal, BrandSpacing.sm)
                        .padding(.vertical, BrandSpacing.xs)
                        .background(
                            RoundedRectangle(cornerRadius: BrandRadius.sm)
                                .fill(BrandColor.outline.opacity(0.1))
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(BrandSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: BrandRadius.lg)
                    .fill(BrandColor.surface.opacity(0.5))
            )
        }
        .padding(.top, BrandSpacing.xxl)
    }
    
    // MARK: - 语音控制区域
    private var voiceControlArea: some View {
        VStack(spacing: BrandSpacing.lg) {
            // 当前识别文本显示
            if !voiceManager.recognizedText.isEmpty {
                recognizedTextDisplay
            }
            
            // 错误信息显示
            if let errorMessage = voiceManager.errorMessage {
                errorMessageDisplay(errorMessage)
            }
            
            // 主语音按钮
            voiceButton
            
            // 控制按钮组
            controlButtons
        }
        .padding(.horizontal, BrandSpacing.lg)
        .padding(.vertical, BrandSpacing.lg)
        .background(
            BrandColor.surface
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(BrandColor.outline.opacity(0.1)),
                    alignment: .top
                )
        )
    }
    
    private var recognizedTextDisplay: some View {
        VStack(alignment: .leading, spacing: BrandSpacing.xs) {
            Text("识别到:")
                .font(BrandFont.body(size: 12, weight: .medium))
                .foregroundColor(BrandColor.outline)
            
            Text(voiceManager.recognizedText)
                .font(BrandFont.body(size: 14, weight: .medium))
                .foregroundColor(BrandColor.onSurface)
                .padding(BrandSpacing.sm)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: BrandRadius.sm)
                        .fill(BrandColor.primaryBlue.opacity(0.1))
                )
        }
    }
    
    private func errorMessageDisplay(_ error: String) -> some View {
        HStack(spacing: BrandSpacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 16))
                .foregroundColor(BrandColor.danger)
            
            Text(error)
                .font(BrandFont.body(size: 13, weight: .medium))
                .foregroundColor(BrandColor.danger)
            
            Spacer()
        }
        .padding(BrandSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: BrandRadius.sm)
                .fill(BrandColor.danger.opacity(0.1))
        )
    }
    
    private var voiceButton: some View {
        Button(action: toggleVoiceRecording) {
            ZStack {
                // 外圈动画
                Circle()
                    .stroke(
                        voiceManager.isListening ? BrandColor.primaryBlue : BrandColor.outline.opacity(0.3),
                        lineWidth: 4
                    )
                    .frame(width: 120, height: 120)
                    .scaleEffect(voiceManager.isListening ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: voiceManager.isListening)
                
                // 内圈背景
                Circle()
                    .fill(
                        LinearGradient(
                            colors: voiceManager.isListening ? 
                            [BrandColor.danger, BrandColor.danger.opacity(0.8)] :
                            [BrandColor.primaryBlue, BrandColor.primaryYellow],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .shadow(color: BrandColor.primaryBlue.opacity(0.3), radius: 8, x: 0, y: 4)
                
                // 麦克风图标
                Image(systemName: voiceManager.isListening ? "stop.fill" : "mic.fill")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
                    .scaleEffect(voiceManager.isListening ? 0.9 : 1.0)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!voiceManager.hasPermission)
    }
    
    private var controlButtons: some View {
        HStack(spacing: BrandSpacing.xl) {
            // 停止播放按钮
            controlButton(
                icon: "speaker.slash.fill",
                title: "停止播放",
                action: { voiceManager.stopSpeaking() },
                isEnabled: voiceManager.isSpeaking
            )
            
            Spacer()
            
            // 快速查询按钮
            controlButton(
                icon: "calendar.badge.clock",
                title: "今天安排",
                action: { simulateVoiceCommand("今天有什么安排？") }
            )
        }
    }
    
    private func controlButton(icon: String, title: String, action: @escaping () -> Void, isEnabled: Bool = true) -> some View {
        Button(action: action) {
            VStack(spacing: BrandSpacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(isEnabled ? BrandColor.primaryBlue : BrandColor.outline.opacity(0.5))
                
                Text(title)
                    .font(BrandFont.body(size: 10, weight: .medium))
                    .foregroundColor(isEnabled ? BrandColor.onSurface : BrandColor.outline.opacity(0.5))
            }
        }
        .disabled(!isEnabled && icon.contains("speaker"))
    }
    
    // MARK: - 数据和逻辑
    private let quickCommands = [
        "今天有什么安排？",
        "明天下午三点开会",
        "提醒我买菜",
        "这周末有计划吗？"
    ]
    
    private func checkPermissions() {
        if !voiceManager.hasPermission {
            showingPermissionAlert = true
        }
    }
    
    private func toggleVoiceRecording() {
        if voiceManager.isListening {
            voiceManager.stopListening()
        } else {
            voiceManager.startListening()
        }
    }
    
    private func simulateVoiceCommand(_ command: String) {
        voiceManager.recognizedText = command
        addMessage(ConversationMessage(content: command, isUser: true))
        
        // 模拟AI处理
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let mockResponse = generateMockResponse(for: command)
            voiceManager.aiResponse = mockResponse
            voiceManager.speak(mockResponse)
        }
    }
    
    private func generateMockResponse(for command: String) -> String {
        if command.contains("今天") && command.contains("安排") {
            let todayEvents = storageManager.events.filter { event in
                guard let startAt = event.startAt else { return false }
                return Calendar.current.isDateInToday(startAt)
            }
            
            if todayEvents.isEmpty {
                return "今天你没有任何安排，可以好好休息一下！"
            } else {
                let eventList = todayEvents.map { "• \($0.title)" }.joined(separator: "\n")
                return "今天你有\(todayEvents.count)个安排：\n\(eventList)"
            }
        } else if command.contains("开会") || command.contains("会议") {
            return "好的！我已经帮你安排了这个会议。记得提前准备相关资料哦！"
        } else if command.contains("提醒") {
            return "没问题！我会在合适的时候提醒你的。"
        } else {
            return "我明白了，正在为你处理这个请求。"
        }
    }
    
    private func addMessage(_ message: ConversationMessage) {
        withAnimation(.easeInOut(duration: 0.3)) {
            conversationHistory.append(message)
        }
    }
    
    private func clearConversation() {
        withAnimation(.easeInOut(duration: 0.3)) {
            conversationHistory.removeAll()
            voiceManager.recognizedText = ""
            voiceManager.aiResponse = ""
            voiceManager.errorMessage = nil
        }
    }
}

// MARK: - 对话气泡组件
struct ConversationBubble: View {
    let message: ConversationMessage
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer(minLength: 50)
            }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: BrandSpacing.xs) {
                Text(message.content)
                    .font(BrandFont.body(size: 15, weight: .medium))
                    .foregroundColor(message.isUser ? .white : BrandColor.onSurface)
                    .padding(.horizontal, BrandSpacing.md)
                    .padding(.vertical, BrandSpacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: BrandRadius.lg, style: .continuous)
                            .fill(message.isUser ? BrandColor.primaryBlue : BrandColor.surface)
                            .neobrutalStyle(
                                cornerRadius: BrandRadius.lg,
                                borderWidth: message.isUser ? 0 : 2
                            )
                    )
                
                Text(formatMessageTime(message.timestamp))
                    .font(BrandFont.body(size: 10, weight: .regular))
                    .foregroundColor(BrandColor.outline)
                    .padding(.horizontal, BrandSpacing.sm)
            }
            
            if !message.isUser {
                Spacer(minLength: 50)
            }
        }
    }
    
    private func formatMessageTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - 对话消息数据模型
struct ConversationMessage: Identifiable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let timestamp: Date
    
    init(content: String, isUser: Bool) {
        self.content = content
        self.isUser = isUser
        self.timestamp = Date()
    }
}

// MARK: - Preview
#Preview {
    VoiceAssistantView()
}