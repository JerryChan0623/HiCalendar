//
//  UIComponents.swift
//  HiCalendar
//
//  Created on 2024. Cute Calendar AI 可爱风组件
//

import SwiftUI

// MARK: - Capsule Button Style (Neobrutalism)
struct CapsuleButtonStyle: ButtonStyle {
    let backgroundColor: Color
    let isSecondary: Bool
    
    init(backgroundColor: Color = BrandColor.primaryYellow,
         isSecondary: Bool = false) {
        self.backgroundColor = backgroundColor
        self.isSecondary = isSecondary
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(BrandFont.body(size: 16, weight: .bold))
            .foregroundColor(isSecondary ? BrandColor.neutral900 : BrandColor.neutral900)
            .padding(.horizontal, BrandSpacing.xl)
            .frame(height: BrandSize.buttonHeight)
            .background(
                RoundedRectangle(cornerRadius: BrandRadius.sm)
                    .fill(isSecondary ? BrandColor.neutral100 : backgroundColor)
            )
            .neobrutalStyle(cornerRadius: BrandRadius.sm,
                           borderWidth: BrandBorder.thick)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.05), value: configuration.isPressed)
    }
}

// MARK: - Ghost Button Style  
struct GhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(BrandFont.body(size: 16, weight: .bold))
            .foregroundColor(BrandColor.neutral900)
            .padding(.horizontal, BrandSpacing.xl)
            .frame(height: BrandSize.buttonHeight)
            .background(BrandColor.neutral100)
            .neobrutalStyle(cornerRadius: BrandRadius.sm,
                           borderWidth: BrandBorder.thick)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.05), value: configuration.isPressed)
    }
}

// MARK: - Conflict Status Badge
struct ConflictBadge: View {
    enum Status {
        case none    // 无冲突
        case soft    // 软冲突
        case hard    // 硬冲突
        
        var config: (background: Color, foreground: Color, text: String, icon: String) {
            switch self {
            case .none:
                return (
                    BrandColor.success,
                    BrandColor.neutral900,
                    "无冲突",
                    "✅"
                )
            case .soft:
                return (
                    BrandColor.warning,
                    BrandColor.neutral900,
                    "软冲突", 
                    "⚠️"
                )
            case .hard:
                return (
                    BrandColor.danger,
                    BrandColor.neutral100,
                    "硬冲突",
                    "⛔"
                )
            }
        }
    }
    
    let status: Status
    
    var body: some View {
        let config = status.config
        
        HStack(spacing: 6) {
            Text(config.icon)
                .font(.system(size: 12))
            Text(config.text)
                .font(BrandFont.body(size: 14, weight: .bold))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(config.background)
        .foregroundColor(config.foreground)
        .neobrutalStyle(cornerRadius: BrandRadius.sm,
                       borderWidth: BrandBorder.regular)
    }
}

// MARK: - Neobrutalism Card
struct CuteCard<Content: View>: View {
    let backgroundColor: Color
    let content: Content
    
    init(backgroundColor: Color = BrandSolid.cardWhite, @ViewBuilder content: () -> Content) {
        self.backgroundColor = backgroundColor
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(BrandSpacing.xl)
            .background(
                RoundedRectangle(cornerRadius: BrandRadius.lg)
                    .fill(backgroundColor)
            )
            .neobrutalStyle(cornerRadius: BrandRadius.lg,
                           borderWidth: BrandBorder.thick)
    }
}

// MARK: - Neobrutalism Text Field
struct CuteTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let helper: String?
    
    init(_ title: String, text: Binding<String>, placeholder: String, helper: String? = nil) {
        self.title = title
        self._text = text
        self.placeholder = placeholder
        self.helper = helper
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: BrandSpacing.sm) {
            Text(title)
                .font(BrandFont.body(size: 14, weight: .bold))
                .foregroundColor(BrandColor.neutral900)
            
            TextField(placeholder, text: $text)
                .font(BrandFont.body(size: 16, weight: .medium))
                .padding(.horizontal, BrandSpacing.lg)
                .frame(height: BrandSize.inputHeight)
                .background(BrandColor.neutral100)
                .neobrutalStyle(cornerRadius: BrandRadius.sm,
                               borderWidth: BrandBorder.regular)
            
            if let helper = helper {
                Text(helper)
                    .font(BrandFont.bodySmall)
                    .foregroundColor(BrandColor.neutral500)
            }
        }
    }
}

// MARK: - Today Summary Card
struct TodaySummaryCard: View {
    let title: String
    let emoji: String
    let conflicts: [ConflictBadge.Status]
    
    var body: some View {
        CuteCard(backgroundColor: BrandColor.primaryBlue) {
            VStack(alignment: .leading, spacing: BrandSpacing.lg) {
                HStack {
                    Text(title)
                        .font(BrandFont.displayMedium)
                        .foregroundColor(BrandColor.neutral900)
                    Spacer()
                    Text(emoji)
                        .font(.system(size: 32))
                }
                
                if !conflicts.isEmpty {
                    HStack(spacing: BrandSpacing.sm) {
                        ForEach(Array(conflicts.enumerated()), id: \.offset) { _, status in
                            ConflictBadge(status: status)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Calendar Day Cell
struct CalendarDayCell: View {
    let day: Int
    let isToday: Bool
    let isSelected: Bool
    let events: [Event]
    
    init(day: Int, isToday: Bool, isSelected: Bool = false, events: [Event]) {
        self.day = day
        self.isToday = isToday
        self.isSelected = isSelected
        self.events = events
    }
    
    var body: some View {
        VStack(spacing: 4) {
            // 日期数字
            Text("\(day)")
                .font(BrandFont.body(size: 16, weight: .bold))
                .foregroundColor(textColor)
            
            // 事项预览
            eventPreview
            
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 60)
        .aspectRatio(1, contentMode: .fit)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(backgroundFill)
        )

    }
    
    @ViewBuilder
    private var eventPreview: some View {
        if !events.isEmpty {
            VStack(spacing: 1) {
                eventDots
                moreEventsIndicator
            }
        }
    }
    
    @ViewBuilder
    private var eventDots: some View {
        HStack(spacing: 3) {
            Spacer()
            ForEach(Array(events.prefix(3).enumerated()), id: \.offset) { _, event in
                Circle()
                    .fill(eventDotColor(for: event))
                    .frame(width: 4, height: 4)
            }
            Spacer()
        }
        .padding(.horizontal, 6)
    }
    
    @ViewBuilder
    private var moreEventsIndicator: some View {
        if events.count > 3 {
            HStack {
                Spacer()
                Text("+\(events.count - 3)")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(BrandColor.neutral700)
                Spacer()
            }
            .padding(.horizontal, 6)
        }
    }
    
    private func eventDotColor(for event: Event) -> Color {
        // 根据事项类型返回高对比度颜色
        switch event.title.first?.lowercased() {
        case "工", "w":
            return BrandColor.secondaryRed     // 工作-警示红
        case "会", "m":
            return BrandColor.primaryBlue      // 会议-电光蓝
        case "生", "l":
            return BrandColor.warning          // 生活-橙色
        default:
            return BrandColor.secondaryGreen   // 默认-霓虹绿
        }
    }
    
    private var backgroundFill: Color {
        if isSelected {
            return BrandColor.primaryYellow    // 选中-鲜艳黄
        } else if isToday {
            return BrandColor.primaryBlue      // 今天-电光蓝
        } else {
            return Color.clear                 // 普通日期-透明背景
        }
    }
    

    
    private var textColor: Color {
        if isSelected || isToday {
            return BrandColor.neutral900       // 选中/今天-纯黑
        } else {
            return BrandColor.neutral700       // 普通-深灰
        }
    }

}

// MARK: - Button Presets (Neobrutalism)
extension Button where Label == Text {
    static func neoButton(_ title: String, backgroundColor: Color = BrandColor.primaryYellow, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .buttonStyle(CapsuleButtonStyle(backgroundColor: backgroundColor))
    }
    
    static func neoSecondaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .buttonStyle(CapsuleButtonStyle(backgroundColor: BrandColor.primaryBlue, isSecondary: true))
    }
    
    static func neoGhostButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .buttonStyle(GhostButtonStyle())
    }
}

// MARK: - Neobrutalism Alert
struct NeobrutalismAlert<Content: View>: View {
    let title: String
    let message: String?
    let content: Content
    @Binding var isPresented: Bool
    
    init(title: String, message: String? = nil, isPresented: Binding<Bool>, @ViewBuilder content: () -> Content) {
        self.title = title
        self.message = message
        self._isPresented = isPresented
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            // 半透明背景
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
            
            // Alert容器
            VStack(spacing: BrandSpacing.xl) {
                // 标题
                Text(title)
                    .font(BrandFont.display(size: 20, weight: .bold))
                    .foregroundColor(BrandColor.neutral900)
                    .multilineTextAlignment(.center)
                
                // 消息
                if let message = message {
                    Text(message)
                        .font(BrandFont.body(size: 16, weight: .medium))
                        .foregroundColor(BrandColor.neutral700)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                }
                
                // 按钮内容
                content
            }
            .padding(BrandSpacing.xl)
            .background(BrandColor.neutral100)
            .neobrutalStyle(cornerRadius: BrandRadius.lg,
                           borderWidth: BrandBorder.thick)
            .padding(.horizontal, BrandSpacing.xl)
            .scaleEffect(isPresented ? 1.0 : 0.8)
            .opacity(isPresented ? 1.0 : 0.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isPresented)
        }
    }
}

// MARK: - Neobrutalism Sheet Header
struct NeobrutalismSheetHeader: View {
    var body: some View {
        VStack(spacing: BrandSpacing.md) {
            // 自定义拖拽指示器
            RoundedRectangle(cornerRadius: BrandRadius.sm)
                .fill(BrandColor.neutral900)
                .frame(width: 50, height: 6)
                .neobrutalStyle(cornerRadius: BrandRadius.sm,
                               borderWidth: BrandBorder.regular)
        }
        .padding(.top, BrandSpacing.md)
        .padding(.bottom, BrandSpacing.sm)
    }
}

// MARK: - Alert Button Styles for Neobrutalism
struct AlertButtonStyle: ButtonStyle {
    let isDestructive: Bool
    
    init(isDestructive: Bool = false) {
        self.isDestructive = isDestructive
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(BrandFont.body(size: 16, weight: .bold))
            .foregroundColor(isDestructive ? .white : BrandColor.neutral900)
            .padding(.horizontal, BrandSpacing.lg)
            .frame(height: BrandSize.buttonHeight - 8)
            .frame(minWidth: 80)
            .background(
                RoundedRectangle(cornerRadius: BrandRadius.sm)
                    .fill(isDestructive ? BrandColor.danger : BrandColor.neutral100)
            )
            .neobrutalStyle(cornerRadius: BrandRadius.sm,
                           borderWidth: BrandBorder.regular,
                           borderColor: isDestructive ? BrandColor.neutral900 : BrandColor.neutral900)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.05), value: configuration.isPressed)
    }
}
