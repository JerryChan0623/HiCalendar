//
//  AIChatView.swift
//  HiCalendar
//
//  Created on 2024. AI对话界面
//

import SwiftUI

struct AIChatView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var messageText: String = ""
    @State private var messages: [ChatMessage] = []
    @FocusState private var isInputFocused: Bool
    @StateObject private var storageManager = EventStorageManager.shared
    @State private var showingVoiceAssistant = false
    
    var body: some View {
        ZStack {
            // 渐变背景
            LinearGradient(
                gradient: Gradient(colors: [
                    BrandColor.background,
                    BrandColor.primaryBlue.opacity(0.05)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // 主体内容
            VStack(spacing: 0) {
                // Sheet顶部拖拽指示器区域
                VStack(spacing: 0) {
                    // 拖拽指示器
                    RoundedRectangle(cornerRadius: 2.5)
                        .fill(BrandColor.outline.opacity(0.3))
                        .frame(width: 36, height: 5)
                        .padding(.top, BrandSpacing.xs)
                    
                    // 优化的顶部栏
                    VStack(spacing: BrandSpacing.sm) {
                        HStack(spacing: BrandSpacing.sm) {
                            // AI头像
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [BrandColor.primaryYellow, BrandColor.primaryBlue],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Text("🤖")
                                        .font(.system(size: 18))
                                )
                                .padding(.leading, BrandSpacing.xs)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(L10n.aiAssistant)
                                    .font(BrandFont.display(size: 18, weight: .bold))
                                    .foregroundColor(BrandColor.onSurface)
                                Text("智能日历管家")
                                    .font(BrandFont.body(size: 12, weight: .medium))
                                    .foregroundColor(BrandColor.outline)
                            }
                            .padding(.leading, BrandSpacing.xs)
                            
                            Spacer()
                            
                            Button(action: { dismiss() }) {
                                Text(L10n.done)
                                    .font(BrandFont.body(size: 16, weight: .semibold))
                                    .foregroundColor(BrandColor.primaryBlue)
                                    .padding(.horizontal, BrandSpacing.md)
                                    .padding(.vertical, BrandSpacing.sm)
                                    .background(
                                        RoundedRectangle(cornerRadius: BrandRadius.pill)
                                            .fill(BrandColor.primaryBlue.opacity(0.1))
                                    )
                            }
                            .padding(.trailing, BrandSpacing.xs)
                        }
                        
                        // 状态指示器
                        HStack {
                            HStack(spacing: BrandSpacing.xs) {
                                Circle()
                                    .fill(BrandColor.success)
                                    .frame(width: 6, height: 6)
                                Text("在线")
                                    .font(BrandFont.body(size: 11, weight: .medium))
                                    .foregroundColor(BrandColor.success)
                            }
                            
                            Spacer()
                            
                            Text("\(messages.count / 2) 条对话")
                                .font(BrandFont.body(size: 11, weight: .medium))
                                .foregroundColor(BrandColor.outline)
                        }
                        .padding(.horizontal, BrandSpacing.lg)
                        .padding(.top, BrandSpacing.lg)
                        .padding(.bottom, BrandSpacing.md)
                    }
                }
                .background(
                    Rectangle()
                        .fill(BrandColor.background.opacity(0.9))
                        .blur(radius: 10)
                )

                // 优化的空状态和建议区
                if messages.isEmpty {
                    VStack(spacing: BrandSpacing.lg) {
                        // 欢迎消息
                        VStack(spacing: BrandSpacing.sm) {
                            Text("👋 你好！我是你的智能日历助手")
                                .font(BrandFont.display(size: 16, weight: .bold))
                                .foregroundColor(BrandColor.onSurface)
                                .multilineTextAlignment(.center)
                            
                            Text("我可以帮你创建事项、查询安排，还会适当吐槽你的拖延症 😏")
                                .font(BrandFont.body(size: 14, weight: .medium))
                                .foregroundColor(BrandColor.outline)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, BrandSpacing.lg)
                        }
                        .padding(.vertical, BrandSpacing.lg)
                        
                        // 功能介绍卡片
                        VStack(spacing: BrandSpacing.md) {
                            Text("✨ 试试这些功能")
                                .font(BrandFont.body(size: 14, weight: .bold))
                                .foregroundColor(BrandColor.onSurface)
                            
                            VStack(spacing: BrandSpacing.sm) {
                                QuickActionCard(
                                    icon: "bubble.left.and.text.bubble.right.fill",
                                    title: "创建事项",
                                    subtitle: "明天下午2点开会",
                                    color: BrandColor.primaryYellow
                                ) { sendMessage("明天下午2点开会") }
                                
                                QuickActionCard(
                                    icon: "calendar.circle.fill",
                                    title: "查询安排",
                                    subtitle: "这周有什么安排？",
                                    color: BrandColor.primaryBlue
                                ) { sendMessage("这周有什么安排？") }
                                
                                QuickActionCard(
                                    icon: "figure.run.circle.fill",
                                    title: "运动提醒",
                                    subtitle: "帮我安排周五的健身",
                                    color: BrandColor.secondary
                                ) { sendMessage("帮我安排周五的健身") }
                            }
                        }
                        .padding(.horizontal, BrandSpacing.lg)
                        
                        Spacer()
                    }
                    .padding(.top, BrandSpacing.xl)
                }

                // 消息列表（自动滚动到底部）
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: BrandSpacing.lg) {
                            if !messages.isEmpty {
                                // 消息开始分隔符
                                HStack {
                                    VStack { Divider().background(BrandColor.outlineVariant) }
                                    Text("开始对话")
                                        .font(BrandFont.body(size: 12, weight: .medium))
                                        .foregroundColor(BrandColor.outline)
                                        .padding(.horizontal, BrandSpacing.sm)
                                    VStack { Divider().background(BrandColor.outlineVariant) }
                                }
                                .padding(.horizontal, BrandSpacing.lg)
                                .padding(.top, BrandSpacing.md)
                            }
                            
                            ForEach(messages) { message in
                                ChatMessageView(message: message)
                                    .id(message.id)
                                    .transition(.asymmetric(
                                        insertion: .move(edge: message.isFromUser ? .trailing : .leading)
                                            .combined(with: .opacity),
                                        removal: .opacity
                                    ))
                            }
                            
                            // 占位用于滚动到底部
                            Color.clear.frame(height: 1).id("BOTTOM")
                        }
                        .padding(.horizontal, BrandSpacing.lg)
                        .padding(.bottom, 120) // 给输入栏预留更多空间
                    }
                    .onChange(of: messages.count) { _ in
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            proxy.scrollTo("BOTTOM", anchor: .bottom)
                        }
                    }
                    .onAppear {
                        proxy.scrollTo("BOTTOM", anchor: .bottom)
                    }
                }
            }
        }
        .background(BrandColor.background)
        // 底部安全区输入栏
        .safeAreaInset(edge: .bottom) { inputBar }
        .sheet(isPresented: $showingVoiceAssistant) { VoiceAssistantView() }
    }

    // MARK: - 组件：优化的底部输入栏
    private var inputBar: some View {
        VStack(spacing: 0) {
            // 渐变分隔线
            LinearGradient(
                colors: [Color.clear, BrandColor.outlineVariant, Color.clear],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 1)
            
            VStack(spacing: BrandSpacing.sm) {
                // 快速回复建议（仅在有消息时显示）
                if !messages.isEmpty && messageText.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: BrandSpacing.xs) {
                            QuickReplyButton(text: "再来一个") { sendMessage("再帮我安排一个事项") }
                            QuickReplyButton(text: "查看今天") { sendMessage("今天有什么安排？") }
                            QuickReplyButton(text: "明天呢？") { sendMessage("明天有什么安排？") }
                            QuickReplyButton(text: "清空计划") { messages.removeAll() }
                        }
                        .padding(.horizontal, BrandSpacing.lg)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                // 输入框区域
                HStack(spacing: BrandSpacing.sm) {
                    // 多媒体按钮
                    Button(action: { showingVoiceAssistant = true }) {
                        Image(systemName: "mic.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(BrandColor.primaryBlue)
                    }
                    
                    // 输入框
                    HStack(spacing: BrandSpacing.sm) {
                        TextField("说点什么...", text: $messageText, axis: .vertical)
                            .padding(.horizontal, BrandSpacing.md)
                            .padding(.vertical, BrandSpacing.sm)
                            .lineLimit(1...5)
                            .font(BrandFont.body(size: 16, weight: .medium))
                            .background(
                                RoundedRectangle(cornerRadius: BrandRadius.extraLarge)
                                    .fill(BrandColor.surface)
                                    .shadow(color: BrandColor.outline.opacity(0.1), radius: 2, x: 0, y: 1)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: BrandRadius.extraLarge)
                                    .stroke(
                                        isInputFocused ? BrandColor.primaryBlue.opacity(0.5) : BrandColor.outline.opacity(0.2),
                                        lineWidth: isInputFocused ? 2 : 1
                                    )
                            )
                            .focused($isInputFocused)
                            .onSubmit { sendMessage(nil) }
                            .toolbar { 
                                ToolbarItemGroup(placement: .keyboard) { 
                                    Spacer() 
                                    Button("发送") { sendMessage(nil) }
                                        .foregroundColor(BrandColor.primaryBlue)
                                        .font(BrandFont.body(size: 16, weight: .semibold))
                                    Button("收起") { isInputFocused = false }
                                        .foregroundColor(BrandColor.outline)
                                } 
                            }
                        
                        // 发送按钮
                        Button(action: { 
                            withAnimation(.spring(response: 0.3)) {
                                sendMessage(nil) 
                            }
                        }) {
                            Image(systemName: messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "arrow.up.circle" : "arrow.up.circle.fill")
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundColor(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? BrandColor.outline : BrandColor.primaryYellow)
                                .scaleEffect(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.9 : 1.1)
                        }
                        .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .animation(.spring(response: 0.3), value: messageText.isEmpty)
                    }
                }
                .padding(.horizontal, BrandSpacing.lg)
                .padding(.vertical, BrandSpacing.md)
            }
            .background(
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Rectangle()
                            .fill(BrandColor.background.opacity(0.8))
                    )
            )
        }
    }
    
    private func sendMessage(_ text: String? = nil) {
        let messageContent = text ?? messageText
        let trimmedMessage = messageContent.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty else { return }
        
        // 添加用户消息
        let userMessage = ChatMessage(
            id: UUID(),
            content: trimmedMessage,
            isFromUser: true,
            timestamp: Date()
        )
        messages.append(userMessage)
        
        // 清空输入框
        if text == nil {
            messageText = ""
        }
        
        // 模拟AI响应（后续替换为Supabase Function调用）
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let aiResponse = generateMockAIResponse(for: trimmedMessage)
            let aiMessage = ChatMessage(
                id: UUID(),
                content: aiResponse,
                isFromUser: false,
                timestamp: Date()
            )
            messages.append(aiMessage)
        }
    }
    
    // 临时的模拟AI响应
    private func generateMockAIResponse(for message: String) -> String {
        let lowercaseMessage = message.lowercased()
        
        // 简单的关键词匹配来模拟AI理解
        if lowercaseMessage.contains(L10n.tomorrow) || lowercaseMessage.contains("下午") || lowercaseMessage.contains("开会") {
            // 模拟创建事件
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
            let startTime = Calendar.current.date(bySettingHour: 14, minute: 0, second: 0, of: tomorrow)
            let endTime = Calendar.current.date(bySettingHour: 15, minute: 0, second: 0, of: tomorrow)
            
            let newEvent = Event(
                title: "开会 💼",
                startAt: startTime,
                endAt: endTime,
                details: "通过AI助手创建的事项",
                pushReminders: [.dayBefore]
            )
            storageManager.addEvent(newEvent)
            
            return "好的！我帮你安排了明天下午2点的开会，已经加到日历里了。记得别迟到哦 😏"
            
        } else if lowercaseMessage.contains("这周") || lowercaseMessage.contains("本周") || lowercaseMessage.contains("安排") {
            // 模拟查询功能
            let calendar = Calendar.current
            let today = Date()
            let weekRange = calendar.dateInterval(of: .weekOfYear, for: today)
            
            if let startOfWeek = weekRange?.start, let endOfWeek = weekRange?.end {
                let weekEvents = storageManager.events.filter { event in
                    guard let startAt = event.startAt else { return false }
                    return startAt >= startOfWeek && startAt < endOfWeek
                }
                
                if weekEvents.isEmpty {
                    return "这周看起来空空的呢～要不要安排点什么有意思的事？🤔"
                } else {
                    let eventTitles = weekEvents.prefix(3).map { "「\($0.title)」" }.joined(separator: "、")
                    return "这周你有\(weekEvents.count)个安排：\(eventTitles)等。看起来挺忙的嘛，记得劳逸结合哦 😌"
                }
            }
            
        } else if lowercaseMessage.contains("健身") || lowercaseMessage.contains("运动") {
            // 模拟创建健身事项
            let friday = Calendar.current.nextFriday() ?? Date()
            let startTime = Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: friday)
            
            let newEvent = Event(
                title: "健身 💪",
                startAt: startTime,
                endAt: nil,
                details: "通过AI助手创建的健身计划",
                pushReminders: [.dayBefore]
            )
            storageManager.addEvent(newEvent)
            
            return "帮你安排了周五6点的健身！别到时候又找借口说累不想去，身体是革命的本钱 💪"
        }
        
        // 默认的吐槽回复
        let sarcasmResponses = [
            "emmm...这个请求有点奇怪，你确定我理解对了吗？🤨",
            "让我想想...不过你能说得再具体一点吗？我又不是你肚子里的蛔虫 🙄",
            "我觉得你想说的和我理解的可能不太一样，要不重新说一遍？😅",
            "这个...我可能需要更多信息才能帮到你呢～"
        ]
        
        return sarcasmResponses.randomElement() ?? "收到！已经帮你处理好了～"
    }
}

// MARK: - 聊天消息模型
struct ChatMessage: Identifiable {
    let id: UUID
    let content: String
    let isFromUser: Bool
    let timestamp: Date
}

// MARK: - 优化的消息气泡组件
struct ChatMessageView: View {
    let message: ChatMessage
    @State private var showTimestamp = false
    
    var body: some View {
        HStack(alignment: .bottom, spacing: BrandSpacing.sm) {
            if message.isFromUser {
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: BrandSpacing.xs) {
                        if showTimestamp {
                            Text(message.timestamp.formatted(.dateTime.hour().minute()))
                                .font(BrandFont.body(size: 11, weight: .medium))
                                .foregroundColor(BrandColor.outline)
                                .transition(.scale.combined(with: .opacity))
                        }
                        
                        Text(message.content)
                            .font(BrandFont.body(size: 15, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, BrandSpacing.md)
                            .padding(.vertical, BrandSpacing.sm)
                            .background(
                                RoundedRectangle(cornerRadius: BrandRadius.lg, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [BrandColor.primaryYellow, BrandColor.primaryYellow.opacity(0.8)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: BrandColor.primaryYellow.opacity(0.3), radius: 4, x: 0, y: 2)
                            )
                    }
                }
                .frame(maxWidth: .infinity * 0.75, alignment: .trailing)
                .onTapGesture {
                    withAnimation(.spring(response: 0.3)) {
                        showTimestamp.toggle()
                    }
                }
                
            } else {
                HStack(alignment: .bottom, spacing: BrandSpacing.xs) {
                    // AI头像
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [BrandColor.primaryBlue.opacity(0.8), BrandColor.primaryBlue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 24, height: 24)
                        .overlay(
                            Text("🤖")
                                .font(.system(size: 12))
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: BrandSpacing.xs) {
                            Text(message.content)
                                .font(BrandFont.body(size: 15, weight: .medium))
                                .foregroundColor(BrandColor.onSurface)
                                .padding(.horizontal, BrandSpacing.md)
                                .padding(.vertical, BrandSpacing.sm)
                                .background(
                                    RoundedRectangle(cornerRadius: BrandRadius.lg, style: .continuous)
                                        .fill(BrandColor.surface)
                                        .shadow(color: BrandColor.outline.opacity(0.1), radius: 2, x: 0, y: 1)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: BrandRadius.lg, style: .continuous)
                                                .stroke(BrandColor.outline.opacity(0.15), lineWidth: 1)
                                        )
                                )
                            
                            if showTimestamp {
                                Text(message.timestamp.formatted(.dateTime.hour().minute()))
                                    .font(BrandFont.body(size: 11, weight: .medium))
                                    .foregroundColor(BrandColor.outline)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                    }
                    .frame(maxWidth: .infinity * 0.75, alignment: .leading)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3)) {
                            showTimestamp.toggle()
                        }
                    }
                }
                
                Spacer()
            }
        }
    }
}

// MARK: - 建议按钮组件
struct ChatSuggestionButton: View {
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(BrandFont.body(size: 14, weight: .medium))
                .foregroundColor(BrandColor.primaryBlue)
                .padding(.horizontal, BrandSpacing.md)
                .padding(.vertical, BrandSpacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: BrandRadius.sm, style: .continuous)
                        .fill(BrandColor.primaryBlue.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: BrandRadius.sm, style: .continuous)
                                .stroke(BrandColor.primaryBlue.opacity(0.3), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 快速操作卡片组件
struct QuickActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: BrandSpacing.sm) {
                // 图标区域
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(color)
                }
                
                // 文字区域
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(BrandFont.body(size: 14, weight: .bold))
                        .foregroundColor(BrandColor.onSurface)
                        .lineLimit(1)
                    
                    Text(subtitle)
                        .font(BrandFont.body(size: 12, weight: .medium))
                        .foregroundColor(BrandColor.outline)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // 箭头指示
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(BrandColor.outline.opacity(0.5))
            }
            .padding(.horizontal, BrandSpacing.md)
            .padding(.vertical, BrandSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: BrandRadius.md, style: .continuous)
                    .fill(BrandColor.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: BrandRadius.md, style: .continuous)
                            .stroke(color.opacity(0.2), lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 快速回复按钮组件
struct QuickReplyButton: View {
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(BrandFont.body(size: 13, weight: .medium))
                .foregroundColor(BrandColor.primaryBlue)
                .padding(.horizontal, BrandSpacing.md)
                .padding(.vertical, BrandSpacing.xs)
                .background(
                    RoundedRectangle(cornerRadius: BrandRadius.extraLarge, style: .continuous)
                        .fill(BrandColor.primaryBlue.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: BrandRadius.extraLarge, style: .continuous)
                                .stroke(BrandColor.primaryBlue.opacity(0.3), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Calendar扩展
extension Calendar {
    func nextFriday() -> Date? {
        let today = Date()
        let weekday = component(.weekday, from: today)
        let daysUntilFriday = (6 - weekday + 7) % 7 // 周五是weekday 6
        let fridayDate = date(byAdding: .day, value: daysUntilFriday == 0 ? 7 : daysUntilFriday, to: today)
        return fridayDate
    }
}

#Preview {
    AIChatView()
}