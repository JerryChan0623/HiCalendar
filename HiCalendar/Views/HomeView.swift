//
//  HomeView.swift
//  HiCalendar
//
//  Created on 2024. Cute Calendar AI 首页（AI 对话）
//

import SwiftUI

struct HomeView: View {
    @State private var aiInput: String = ""
    @State private var isListening: Bool = false
    @State private var todayEvents: [Event] = Event.sampleEvents
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: BrandSpacing.xl) {
                    // 今日摘要卡片
                    todaySummarySection
                    
                    // AI 输入区域
                    aiInputSection
                    
                    // 最近事件卡片
                    recentEventsSection
                }
                .padding(.horizontal, BrandSpacing.lg)
                .padding(.vertical, BrandSpacing.xl)
            }
            .background(BrandSolid.background.ignoresSafeArea())
            .navigationTitle("AI 助手")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - 今日摘要卡片
    private var todaySummarySection: some View {
        TodaySummaryCard(
            title: "今天你有 2 个会 + 1 个摸鱼时段",
            emoji: "🐣",
            conflicts: [.none, .soft]
        )
    }
    
    // MARK: - AI 输入区域
    private var aiInputSection: some View {
        VStack(spacing: BrandSpacing.lg) {
            Text("说点啥，我帮你记下来 💬")
                .font(BrandFont.headlineSmall)
                .foregroundColor(BrandColor.neutral700)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: BrandSpacing.md) {
                // 文本输入框
                TextField("明天 3 点开会，跟 Alice 在 Zoom", text: $aiInput)
                    .font(BrandFont.bodyLarge)
                    .padding(.horizontal, BrandSpacing.lg)
                    .frame(height: BrandSize.inputHeight)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: BrandRadius.pill)
                            .stroke(BrandColor.neutral200, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: BrandRadius.pill))
                
                // 麦克风按钮
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isListening.toggle()
                    }
                }) {
                    Image(systemName: isListening ? "mic.fill" : "mic")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: BrandSize.buttonHeight, height: BrandSize.buttonHeight)
                        .background(
                            Circle().fill(isListening ? BrandColor.secondaryRed : BrandColor.primaryBlue)
                        )
                        .overlay(
                            Circle().stroke(BrandBorder.outline, lineWidth: BrandBorder.regular)
                        )
                        .scaleEffect(isListening ? 1.1 : 1.0)
                }
            }
            
            // 提交按钮
            Button("发送给 AI") {
                submitToAI()
            }
            .buttonStyle(MD3ButtonStyle(type: .filled, isFullWidth: true))
            .disabled(aiInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(aiInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1.0)
        }
    }
    
    // MARK: - 最近事件卡片
    private var recentEventsSection: some View {
        VStack(spacing: BrandSpacing.lg) {
            HStack {
                Text("最近要忙的事儿")
                    .font(BrandFont.headlineSmall)
                    .foregroundColor(BrandColor.neutral700)
                Spacer()
                Button("查看全部") {
                    // 跳转到事件列表页
                }
                .font(BrandFont.bodyMedium)
                .foregroundColor(BrandColor.secondaryRed)
            }
            
            LazyVStack(spacing: BrandSpacing.md) {
                ForEach(todayEvents.prefix(3)) { event in
                    EventCard(event: event)
                        .onTapGesture {
                            // 跳转到事件详情页
                        }
                }
            }
        }
    }
    
    // MARK: - Actions
    private func submitToAI() {
        // TODO: 处理 AI 输入
        // AI 输入处理
        
        // 模拟 AI 响应
        withAnimation {
            aiInput = ""
        }
    }
}

// MARK: - Event Card Component
struct EventCard: View {
    let event: Event
    
    var body: some View {
        MD3Card(type: .elevated) {
            VStack(alignment: .leading, spacing: BrandSpacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(event.title)
                            .font(BrandFont.body(size: 16, weight: .bold))
                            .foregroundColor(BrandColor.neutral900)
                        
                        Text(event.timeRangeString)
                            .font(BrandFont.bodyMedium)
                            .foregroundColor(BrandColor.neutral500)
                    }
                    
                    Spacer()
                    
                    ConflictBadge(status: conflictStatus)
                }
                
                if let details = event.details, !details.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 12))
                            .foregroundColor(BrandColor.neutral500)
                        Text(details)
                            .font(BrandFont.bodyMedium)
                            .foregroundColor(BrandColor.neutral500)
                    }
                }
            }
        }
    }
    
    private var backgroundColorForEvent: Color {
        switch conflictStatus {
        case .none: return BrandSolid.cardWhite
        case .soft: return BrandColor.warning
        case .hard: return BrandColor.danger
        }
    }
    
    private var conflictStatus: ConflictBadge.Status {
        // 简化版冲突检测逻辑
        // TODO: 实现真实的冲突检测
        return .none
    }
}

#Preview {
    HomeView()
}
