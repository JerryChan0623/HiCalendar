//
//  OverlayAIChatView.swift
//  HiCalendar
//
//  Created on 2024. 朦层式AI聊天界面 - 用完即走体验
//

import SwiftUI

// MARK: - 朦层式AI聊天主界面
struct OverlayAIChatView: View {
    @Binding var isPresented: Bool
    @State private var messageText: String = ""
    @State private var recentMessages: [QuickChatMessage] = []
    @State private var isProcessing = false
    @FocusState private var isInputFocused: Bool
    @StateObject private var storageManager = EventStorageManager.shared
    @StateObject private var voiceManager = AIVoiceManager.shared
    @State private var showVoiceInterface = false
    
    // 动画状态
    @State private var overlayOpacity: Double = 0
    @State private var chatPanelOffset: CGFloat = -100
    
    var body: some View {
        ZStack {
            // 半透明朦层
            overlayBackground
            
            // 聊天面板
            chatPanel
                .offset(y: chatPanelOffset)
        }
        .opacity(overlayOpacity)
        .onAppear {
            showInterface()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isInputFocused = true
            }
        }
        .onChange(of: isPresented) { _, newValue in
            if !newValue {
                hideInterface()
            }
        }
    }
    
    // MARK: - 朦层背景
    private var overlayBackground: some View {
        Color.black
            .opacity(0.3)
            .ignoresSafeArea()
            .onTapGesture {
                dismissChat()
            }
            .overlay(
                // 背景模糊效果
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea()
            )
    }
    
    // MARK: - 聊天面板
    private var chatPanel: some View {
        VStack(spacing: 0) {
            // 顶部拖拽指示器
            dragIndicator
            
            // 主聊天区域
            VStack(spacing: BrandSpacing.lg) {
                // 标题栏
                chatHeader
                
                // 快速建议或历史消息
                if !showVoiceInterface {
                    if recentMessages.isEmpty {
                        quickSuggestions
                    } else {
                        recentMessagesView
                    }
                } else {
                    voiceInterfaceView
                }
                
                // 输入区域
                if !showVoiceInterface {
                    inputSection
                } else {
                    voiceControlSection
                }
            }
            .padding(BrandSpacing.xl)
        }
        .background(
            RoundedRectangle(cornerRadius: BrandRadius.lg, style: .continuous)
                .fill(BrandColor.background)
                .overlay(
                    RoundedRectangle(cornerRadius: BrandRadius.lg, style: .continuous)
                        .stroke(BrandColor.outline.opacity(0.1), lineWidth: 1)
                )
        )
        .padding(.horizontal, BrandSpacing.lg)
        .padding(.top, 120) // 距离顶部更多空间
    }
    
    // MARK: - 拖拽指示器
    private var dragIndicator: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(BrandColor.outline.opacity(0.3))
            .frame(width: 36, height: 4)
            .padding(.top, BrandSpacing.sm)
    }
    
    // MARK: - 聊天标题栏
    private var chatHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: BrandSpacing.xs) {
                    Text("AI助手")
                        .font(BrandFont.body(size: 18, weight: .bold))
                        .foregroundColor(BrandColor.onSurface)
                    
                    // 状态指示器
                    if isProcessing {
                        ProgressView()
                            .scaleEffect(0.6)
                            .tint(BrandColor.primaryBlue)
                    } else if voiceManager.isListening {
                        Circle()
                            .fill(BrandColor.primaryBlue)
                            .frame(width: 6, height: 6)
                            .scaleEffect(voiceManager.isListening ? 1.5 : 1.0)
                            .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: voiceManager.isListening)
                    }
                }
                
                Text(currentStatusText)
                    .font(BrandFont.body(size: 12, weight: .regular))
                    .foregroundColor(BrandColor.outline)
            }
            .padding(.leading, BrandSpacing.sm)
            
            Spacer()
            
            // 语音/文字切换按钮
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showVoiceInterface.toggle()
                }
            }) {
                ColorfulIcon(showVoiceInterface ? .keyboard : .microphone, size: 20)
            }
            .padding(.trailing, BrandSpacing.xs)
            
            // 关闭按钮
            Button(action: dismissChat) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(BrandColor.outline.opacity(0.6))
            }
            .padding(.trailing, BrandSpacing.sm)
        }
    }
    
    private var currentStatusText: String {
        if voiceManager.isListening {
            return "正在聆听..."
        } else if isProcessing {
            return "AI思考中..."
        } else if showVoiceInterface {
            return "按住按钮开始语音对话"
        } else {
            return "说点什么，我来帮你安排"
        }
    }
    
    // MARK: - 快速建议
    private var quickSuggestions: some View {
        VStack(alignment: .leading, spacing: BrandSpacing.sm) {
            Text("试试这些：")
                .font(BrandFont.body(size: 14, weight: .medium))
                .foregroundColor(BrandColor.onSurface.opacity(0.8))
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: BrandSpacing.xs), count: 2), spacing: BrandSpacing.xs) {
                QuickSuggestionButton(text: "今天安排", icon: "calendar") {
                    sendQuickMessage("今天有什么安排？")
                }
                QuickSuggestionButton(text: "明天会议", icon: "person.2") {
                    sendQuickMessage("明天下午3点开会")
                }
                QuickSuggestionButton(text: "周末计划", icon: "sun.max") {
                    sendQuickMessage("这个周末有什么计划？")
                }
                QuickSuggestionButton(text: "快速提醒", icon: "bell") {
                    sendQuickMessage("提醒我买菜")
                }
            }
        }
    }
    
    // MARK: - 最近消息
    private var recentMessagesView: some View {
        VStack(alignment: .leading, spacing: BrandSpacing.sm) {
            HStack {
                Text("最近对话:")
                    .font(BrandFont.body(size: 14, weight: .medium))
                    .foregroundColor(BrandColor.onSurface.opacity(0.8))
                
                Spacer()
                
                Button("清空") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        recentMessages.removeAll()
                    }
                }
                .font(BrandFont.body(size: 12, weight: .medium))
                .foregroundColor(BrandColor.primaryBlue)
            }
            
            ScrollView {
                VStack(spacing: BrandSpacing.xs) {
                    ForEach(recentMessages.prefix(3)) { message in
                        QuickMessageBubble(message: message)
                    }
                }
            }
            .frame(maxHeight: 120)
        }
    }
    
    // MARK: - 语音界面
    private var voiceInterfaceView: some View {
        VStack(spacing: BrandSpacing.lg) {
            // 语音可视化
            HStack(spacing: 4) {
                ForEach(0..<5, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(BrandColor.primaryBlue.opacity(voiceManager.isListening ? 0.8 : 0.3))
                        .frame(width: 4, height: voiceManager.isListening ? 
                               CGFloat.random(in: 20...40) : 20)
                        .animation(
                            voiceManager.isListening ? 
                            .easeInOut(duration: 0.5).repeatForever(autoreverses: true).delay(Double(index) * 0.1) :
                            .easeInOut(duration: 0.3),
                            value: voiceManager.isListening
                        )
                }
            }
            
            // 识别文本显示
            if !voiceManager.recognizedText.isEmpty {
                Text(voiceManager.recognizedText)
                    .font(BrandFont.body(size: 16, weight: .medium))
                    .foregroundColor(BrandColor.onSurface)
                    .padding(BrandSpacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: BrandRadius.sm)
                            .fill(BrandColor.primaryBlue.opacity(0.1))
                    )
                    .multilineTextAlignment(.center)
            }
            
            // AI响应显示
            if !voiceManager.aiResponse.isEmpty && !isProcessing {
                Text(voiceManager.aiResponse)
                    .font(BrandFont.body(size: 14, weight: .regular))
                    .foregroundColor(BrandColor.onSurface.opacity(0.8))
                    .padding(BrandSpacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: BrandRadius.sm)
                            .fill(BrandColor.surface)
                    )
                    .multilineTextAlignment(.center)
            }
        }
        .frame(minHeight: 80)
    }
    
    // MARK: - 语音控制区域
    private var voiceControlSection: some View {
        HStack(spacing: BrandSpacing.lg) {
            // 停止播放按钮
            Button(action: {
                voiceManager.stopSpeaking()
            }) {
                Image(systemName: "speaker.slash.fill")
                    .font(.system(size: 18))
                    .foregroundColor(voiceManager.isSpeaking ? BrandColor.danger : BrandColor.outline.opacity(0.5))
            }
            .disabled(!voiceManager.isSpeaking)
            
            Spacer()
            
            // 主语音按钮
            Button(action: {
                if voiceManager.isListening {
                    voiceManager.stopListening()
                } else {
                    voiceManager.startListening()
                }
            }) {
                ZStack {
                    Circle()
                        .fill(voiceManager.isListening ? BrandColor.danger : BrandColor.primaryBlue)
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: voiceManager.isListening ? "stop.fill" : "mic.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .scaleEffect(voiceManager.isListening ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: voiceManager.isListening)
            
            Spacer()
            
            // 快速查询按钮
            Button(action: {
                sendQuickMessage("今天有什么安排？")
            }) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 18))
                    .foregroundColor(BrandColor.primaryBlue)
            }
        }
    }
    
    // MARK: - 输入区域
    private var inputSection: some View {
        HStack(spacing: BrandSpacing.sm) {
            TextField("说点什么...", text: $messageText, axis: .vertical)
                .font(BrandFont.body(size: 16, weight: .regular))
                .padding(.horizontal, BrandSpacing.md)
                .padding(.vertical, BrandSpacing.sm)
                .lineLimit(1...3)
                .background(
                    RoundedRectangle(cornerRadius: BrandRadius.lg)
                        .fill(BrandColor.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: BrandRadius.lg)
                                .stroke(isInputFocused ? BrandColor.primaryBlue : BrandColor.outline.opacity(0.3), lineWidth: 1)
                        )
                )
                .focused($isInputFocused)
                .onSubmit {
                    sendMessage()
                }
            
            Button(action: sendMessage) {
                Image(systemName: isProcessing ? "clock.arrow.circlepath" : "paperplane.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(messageCanSend ? BrandColor.primaryBlue : BrandColor.outline.opacity(0.5))
                    )
            }
            .disabled(!messageCanSend || isProcessing)
        }
    }
    
    private var messageCanSend: Bool {
        !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - 动画控制
    private func showInterface() {
        withAnimation(.easeOut(duration: 0.3)) {
            overlayOpacity = 1.0
            chatPanelOffset = 0
        }
    }
    
    private func hideInterface() {
        withAnimation(.easeIn(duration: 0.25)) {
            overlayOpacity = 0.0
            chatPanelOffset = -100
        }
        
        // 延迟重置状态
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            resetState()
        }
    }
    
    private func dismissChat() {
        isInputFocused = false
        voiceManager.stopListening()
        voiceManager.stopSpeaking()
        isPresented = false
    }
    
    private func resetState() {
        messageText = ""
        isProcessing = false
        showVoiceInterface = false
        voiceManager.recognizedText = ""
        voiceManager.aiResponse = ""
    }
    
    // MARK: - 消息发送
    private func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty && !isProcessing else { return }
        
        sendQuickMessage(text)
        messageText = ""
    }
    
    private func sendQuickMessage(_ text: String) {
        guard !isProcessing else { return }
        
        isProcessing = true
        
        // 添加用户消息到历史
        let userMessage = QuickChatMessage(content: text, isUser: true)
        recentMessages.insert(userMessage, at: 0)
        
        // 模拟AI处理（后续替换为Gemini API调用）
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            let aiResponse = generateQuickAIResponse(for: text)
            let aiMessage = QuickChatMessage(content: aiResponse, isUser: false)
            recentMessages.insert(aiMessage, at: 0)
            
            isProcessing = false
            
            // 短暂显示结果后自动关闭
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                if !isInputFocused && !voiceManager.isListening {
                    dismissChat()
                }
            }
        }
    }
    
    // 简化版AI响应生成
    private func generateQuickAIResponse(for message: String) -> String {
        let lowercased = message.lowercased()
        
        if lowercased.contains("今天") && lowercased.contains("安排") {
            let todayEvents = storageManager.events.filter { event in
                guard let startAt = event.startAt else { return false }
                return Calendar.current.isDateInToday(startAt)
            }
            return todayEvents.isEmpty ? "今天没有安排，可以自由支配时间！" : "今天有\(todayEvents.count)个安排等着你"
        } else if lowercased.contains("开会") || lowercased.contains("会议") {
            return "好的！已经安排了会议，记得准时参加"
        } else {
            return "收到！已经为你处理好了"
        }
    }
}

// MARK: - 快速建议按钮
struct QuickSuggestionButton: View {
    let text: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: BrandSpacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(BrandColor.primaryBlue)
                
                Text(text)
                    .font(BrandFont.body(size: 12, weight: .medium))
                    .foregroundColor(BrandColor.onSurface)
                
                Spacer()
            }
            .padding(.horizontal, BrandSpacing.sm)
            .padding(.vertical, BrandSpacing.xs)
            .background(
                RoundedRectangle(cornerRadius: BrandRadius.sm)
                    .fill(BrandColor.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: BrandRadius.sm)
                            .stroke(BrandColor.outline.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 快速消息气泡
struct QuickMessageBubble: View {
    let message: QuickChatMessage
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
            }
            
            Text(message.content)
                .font(BrandFont.body(size: 13, weight: .regular))
                .foregroundColor(message.isUser ? BrandColor.onPrimary : BrandColor.onSurface)
                .padding(.horizontal, BrandSpacing.sm)
                .padding(.vertical, BrandSpacing.xs)
                .background(
                    RoundedRectangle(cornerRadius: BrandRadius.sm)
                        .fill(message.isUser ? BrandColor.primaryBlue : BrandColor.surface.opacity(0.8))
                )
                .frame(maxWidth: .infinity * 0.8, alignment: message.isUser ? .trailing : .leading)
            
            if !message.isUser {
                Spacer()
            }
        }
    }
}

// MARK: - 快速聊天消息模型
struct QuickChatMessage: Identifiable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let timestamp = Date()
}

// MARK: - Preview
#Preview {
    ZStack {
        // 模拟背景内容
        Color.blue.opacity(0.3)
            .ignoresSafeArea()
            .overlay(
                Text("背景内容")
                    .font(.title)
                    .foregroundColor(.white)
            )
        
        OverlayAIChatView(isPresented: .constant(true))
    }
}