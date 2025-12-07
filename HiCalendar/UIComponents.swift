//
//  UIComponents.swift
//  HiCalendar
//
//  Created on 2024. Material Design 3 组件
//

import SwiftUI

// MARK: - MD3 Button Style
struct MD3ButtonStyle: ButtonStyle {
    enum ButtonType {
        case filled
        case tonal
        case outlined
        case text
        case elevated
    }
    
    let type: ButtonType
    let isFullWidth: Bool
    
    init(type: ButtonType = .filled, isFullWidth: Bool = false) {
        self.type = type
        self.isFullWidth = isFullWidth
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(BrandFont.labelLarge)
            .foregroundColor(foregroundColor)
            .padding(.horizontal, BrandSpacing.lg)
            .frame(height: BrandSize.buttonHeight)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .background(backgroundView(isPressed: configuration.isPressed))
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
    
    @ViewBuilder
    private func backgroundView(isPressed: Bool) -> some View {
        switch type {
        case .filled:
            RoundedRectangle(cornerRadius: BrandRadius.lg, style: .continuous)
                .fill(BrandColor.primary)
                .overlay(
                    Color.white.opacity(isPressed ? 0.12 : 0)
                        .clipShape(RoundedRectangle(cornerRadius: BrandRadius.lg, style: .continuous))
                )
        case .tonal:
            RoundedRectangle(cornerRadius: BrandRadius.lg, style: .continuous)
                .fill(BrandColor.secondaryContainer)
                .overlay(
                    BrandColor.onSurface.opacity(isPressed ? 0.12 : 0)
                        .clipShape(RoundedRectangle(cornerRadius: BrandRadius.lg, style: .continuous))
                )
        case .elevated:
            RoundedRectangle(cornerRadius: BrandRadius.lg, style: .continuous)
                .fill(BrandColor.surface)
                .shadow(color: Color.black.opacity(BrandElevation.level1.shadowOpacity),
                       radius: BrandElevation.level1.shadowRadius,
                       x: 0, y: BrandElevation.level1.shadowRadius / 2)
                .overlay(
                    BrandColor.primary.opacity(isPressed ? 0.12 : 0)
                        .clipShape(RoundedRectangle(cornerRadius: BrandRadius.lg, style: .continuous))
                )
        case .outlined:
            RoundedRectangle(cornerRadius: BrandRadius.lg, style: .continuous)
                .stroke(BrandColor.outline, lineWidth: 1)
                .background(
                    BrandColor.primary.opacity(isPressed ? 0.12 : 0)
                        .clipShape(RoundedRectangle(cornerRadius: BrandRadius.lg, style: .continuous))
                )
        case .text:
            BrandColor.primary.opacity(isPressed ? 0.12 : 0)
                .clipShape(RoundedRectangle(cornerRadius: BrandRadius.lg, style: .continuous))
        }
    }
    
    private var foregroundColor: Color {
        switch type {
        case .filled:
            return BrandColor.onPrimary
        case .tonal:
            return BrandColor.onPrimaryContainer
        case .elevated, .outlined, .text:
            return BrandColor.primary
        }
    }
}

// MARK: - MD3 FAB (Floating Action Button)
struct MD3FAB: View {
    let icon: String
    let action: () -> Void
    let extended: Bool
    let label: String?
    
    init(icon: String, label: String? = nil, extended: Bool = false, action: @escaping () -> Void) {
        self.icon = icon
        self.label = label
        self.extended = extended || label != nil
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: extended ? BrandSpacing.sm : 0) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                
                if extended, let label = label {
                    Text(label)
                        .font(BrandFont.labelLarge)
                }
            }
            .foregroundColor(BrandColor.onPrimaryContainer)
            .padding(extended ? BrandSpacing.md : 0)
            .frame(width: extended ? nil : BrandSize.fabSize,
                   height: extended ? 56 : BrandSize.fabSize)
            .background(
                RoundedRectangle(cornerRadius: extended ? BrandRadius.lg : BrandRadius.lg,
                                style: .continuous)
                    .fill(BrandColor.primaryContainer)
                    .shadow(color: Color.black.opacity(BrandElevation.level3.shadowOpacity),
                           radius: BrandElevation.level3.shadowRadius,
                           x: 0, y: BrandElevation.level3.shadowRadius / 2)
            )
        }
    }
}

// MARK: - MD3 Chip
struct MD3Chip: View {
    let title: String
    let isSelected: Bool
    let icon: String?
    let action: () -> Void
    
    init(title: String, icon: String? = nil, isSelected: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.isSelected = isSelected
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: BrandSpacing.xs) {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .medium))
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .medium))
                }
                
                Text(title)
                    .font(BrandFont.labelLarge)
            }
            .padding(.horizontal, BrandSpacing.md)
            .padding(.vertical, BrandSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: BrandRadius.sm, style: .continuous)
                    .fill(isSelected ? BrandColor.secondaryContainer : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: BrandRadius.sm, style: .continuous)
                            .stroke(isSelected ? Color.clear : BrandColor.outline, lineWidth: 1)
                    )
            )
            .foregroundColor(isSelected ? BrandColor.onPrimaryContainer : BrandColor.onSurface)
        }
    }
}

// MARK: - MD3 Card
struct MD3Card<Content: View>: View {
    enum CardType {
        case elevated
        case filled
        case outlined
    }
    
    let type: CardType
    let content: Content
    
    init(type: CardType = .elevated, @ViewBuilder content: () -> Content) {
        self.type = type
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(BrandSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: BrandRadius.card, style: .continuous))
            .overlay(cardOverlay)
    }
    
    @ViewBuilder
    private var cardBackground: some View {
        switch type {
        case .elevated:
            BrandColor.surface
                .shadow(color: Color.black.opacity(BrandElevation.level1.shadowOpacity),
                       radius: BrandElevation.level1.shadowRadius,
                       x: 0, y: BrandElevation.level1.shadowRadius / 2)
        case .filled:
            BrandColor.surfaceVariant
        case .outlined:
            BrandColor.surface
        }
    }
    
    @ViewBuilder
    private var cardOverlay: some View {
        if type == .outlined {
            RoundedRectangle(cornerRadius: BrandRadius.card, style: .continuous)
                .stroke(BrandColor.outlineVariant, lineWidth: 1)
        }
    }
}

// MARK: - MD3 Text Field
struct MD3TextField: View {
    let label: String
    @Binding var text: String
    let icon: String?
    let helper: String?
    let error: String?
    @FocusState private var isFocused: Bool
    
    init(_ label: String, text: Binding<String>, icon: String? = nil, helper: String? = nil, error: String? = nil) {
        self.label = label
        self._text = text
        self.icon = icon
        self.helper = helper
        self.error = error
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: BrandSpacing.xs) {
            // 输入框容器
            VStack(alignment: .leading, spacing: 4) {
                // 浮动标签
                if !text.isEmpty || isFocused {
                    Text(label)
                        .font(BrandFont.bodySmall)
                        .foregroundColor(error != nil ? BrandColor.error : 
                                       (isFocused ? BrandColor.primary : BrandColor.onSurfaceVariant))
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                // 输入框
                HStack {
                    if let icon = icon {
                        Image(systemName: icon)
                            .foregroundColor(BrandColor.onSurfaceVariant)
                            .font(.system(size: 20))
                    }
                    
                    TextField(isFocused || !text.isEmpty ? "" : label, text: $text)
                        .font(BrandFont.bodyLarge)
                        .foregroundColor(BrandColor.onSurface)
                        .focused($isFocused)
                }
            }
            .padding(.vertical, BrandSpacing.md)
            .padding(.horizontal, BrandSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: BrandRadius.extraSmall, style: .continuous)
                    .fill(BrandColor.surfaceVariant)
            )
            .overlay(
                RoundedRectangle(cornerRadius: BrandRadius.extraSmall, style: .continuous)
                    .stroke(
                        error != nil ? BrandColor.error :
                        (isFocused ? BrandColor.primary : Color.clear),
                        lineWidth: isFocused || error != nil ? 2 : 1
                    )
            )
            
            // Helper/Error 文本
            if let error = error {
                Text(error)
                    .font(BrandFont.bodySmall)
                    .foregroundColor(BrandColor.error)
            } else if let helper = helper {
                Text(helper)
                    .font(BrandFont.bodySmall)
                    .foregroundColor(BrandColor.onSurfaceVariant)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isFocused)
        .animation(.easeInOut(duration: 0.2), value: text.isEmpty)
    }
}

// MARK: - Conflict Status Badge (MD3 Style)
struct ConflictBadge: View {
    enum Status {
        case none    // 无冲突
        case soft    // 软冲突
        case hard    // 硬冲突
        
        var config: (background: Color, foreground: Color, text: String, icon: String) {
            switch self {
            case .none:
                return (
                    BrandColor.success.opacity(0.2),
                    BrandColor.success,
                    "无冲突",
                    "checkmark.circle.fill"
                )
            case .soft:
                return (
                    BrandColor.warning.opacity(0.2),
                    BrandColor.warning,
                    "软冲突",
                    "exclamationmark.triangle.fill"
                )
            case .hard:
                return (
                    BrandColor.errorContainer,
                    BrandColor.error,
                    "硬冲突",
                    "xmark.octagon.fill"
                )
            }
        }
    }
    
    let status: Status
    
    var body: some View {
        let config = status.config
        
        HStack(spacing: 6) {
            Image(systemName: config.icon)
                .font(.system(size: 12, weight: .medium))
            Text(config.text)
                .font(BrandFont.labelMedium)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: BrandRadius.sm, style: .continuous)
                .fill(config.background)
        )
        .foregroundColor(config.foreground)
    }
}

// MARK: - Today Summary Card (MD3 Style)
struct TodaySummaryCard: View {
    let title: String
    let emoji: String
    let conflicts: [ConflictBadge.Status]
    
    var body: some View {
        MD3Card(type: .filled) {
            VStack(alignment: .leading, spacing: BrandSpacing.md) {
                HStack {
                    Text(title)
                        .font(BrandFont.headlineSmall)
                        .foregroundColor(BrandColor.onSurface)
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

// MARK: - Calendar Day Cell (MD3 Style)
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
        VStack(spacing: 1) {
            // 日期数字
            Text("\(day)")
                .font(BrandFont.bodyMedium)
                .fontWeight(isToday ? .medium : .regular)
                .foregroundColor(textColor)

            // 事项指示（高度缩小后改为1个事项+点状提示）
            if !events.isEmpty {
                VStack(spacing: 1) {
                    // 只显示第一个事项
                    Text(events[0].title)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(eventTextColor)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .padding(.horizontal, 2)
                        .padding(.vertical, 1)
                        .background(
                            RoundedRectangle(cornerRadius: 2, style: .continuous)
                                .fill(eventBackgroundColor(for: 0))
                        )

                    // 如果超过1个事项，显示点状指示
                    if events.count > 1 {
                        HStack(spacing: 2) {
                            ForEach(0..<min(events.count - 1, 3), id: \.self) { _ in
                                Circle()
                                    .fill(BrandColor.outline.opacity(0.5))
                                    .frame(width: 3, height: 3)
                            }
                        }
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 44)
        .padding(2)
        .background(backgroundView)
        .clipShape(RoundedRectangle(cornerRadius: BrandRadius.md, style: .continuous))
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        if isSelected {
            BrandColor.primary
        } else if isToday {
            BrandColor.primaryContainer
        } else {
            Color.clear
        }
    }
    
    private var textColor: Color {
        if isSelected {
            return BrandColor.onPrimary
        } else if isToday {
            return BrandColor.onPrimaryContainer
        } else {
            return BrandColor.onSurface
        }
    }
    
    private var eventTextColor: Color {
        if isSelected {
            return BrandColor.onPrimary
        } else if isToday {
            return BrandColor.onPrimaryContainer
        } else {
            return BrandColor.onSurfaceVariant
        }
    }
    
    private func eventBackgroundColor(for index: Int) -> Color {
        let colors: [Color] = [
            BrandColor.primaryYellow.opacity(0.3),
            BrandColor.primaryBlue.opacity(0.3),
            BrandColor.success.opacity(0.3),
            BrandColor.warning.opacity(0.3)
        ]
        return colors[index % colors.count]
    }
}

// MARK: - MD3 Dialog/Alert
struct MD3Dialog<Content: View>: View {
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
            // Scrim
            Color.black.opacity(0.32)
                .ignoresSafeArea()
                .onTapGesture {
                    // MD3 dialogs don't dismiss on scrim tap by default
                }
            
            // Dialog container
            VStack(alignment: .leading, spacing: BrandSpacing.lg) {
                // Title
                Text(title)
                    .font(BrandFont.headlineSmall)
                    .foregroundColor(BrandColor.onSurface)
                
                // Message
                if let message = message {
                    Text(message)
                        .font(BrandFont.bodyMedium)
                        .foregroundColor(BrandColor.onSurfaceVariant)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                // Actions
                HStack(spacing: BrandSpacing.sm) {
                    Spacer()
                    content
                }
            }
            .padding(BrandSpacing.lg)
            .frame(minWidth: 280, maxWidth: 560)
            .background(
                RoundedRectangle(cornerRadius: BrandRadius.extraLarge, style: .continuous)
                    .fill(BrandColor.surface)
            )
            .shadow(color: Color.black.opacity(BrandElevation.level3.shadowOpacity),
                   radius: BrandElevation.level3.shadowRadius,
                   x: 0, y: BrandElevation.level3.shadowRadius / 2)
            .padding(.horizontal, BrandSpacing.xl)
            .scaleEffect(isPresented ? 1.0 : 0.9)
            .opacity(isPresented ? 1.0 : 0.0)
            .animation(.easeInOut(duration: 0.2), value: isPresented)
        }
    }
}

// MARK: - MD3 Bottom Sheet Header
struct MD3SheetHeader: View {
    let title: String?
    let onDismiss: (() -> Void)?
    
    init(title: String? = nil, onDismiss: (() -> Void)? = nil) {
        self.title = title
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Drag handle
            RoundedRectangle(cornerRadius: 2)
                .fill(BrandColor.onSurfaceVariant.opacity(0.4))
                .frame(width: 32, height: 4)
                .padding(.top, BrandSpacing.sm)
                .padding(.bottom, BrandSpacing.md)
            
            // Title bar
            if let title = title {
                HStack {
                    Text(title)
                        .font(BrandFont.titleLarge)
                        .foregroundColor(BrandColor.onSurface)
                    
                    Spacer()
                    
                    if let onDismiss = onDismiss {
                        Button(action: onDismiss) {
                            Image(systemName: "xmark")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(BrandColor.onSurfaceVariant)
                                .frame(width: 24, height: 24)
                        }
                    }
                }
                .padding(.horizontal, BrandSpacing.lg)
                .padding(.bottom, BrandSpacing.md)
            }
        }
    }
}

// MARK: - Navigation Rail Item (MD3 Style)
struct MD3NavigationRailItem: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: BrandRadius.lg, style: .continuous)
                            .fill(BrandColor.secondaryContainer)
                            .frame(width: 56, height: 32)
                    }
                    
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(isSelected ? BrandColor.onSecondaryContainer : BrandColor.onSurfaceVariant)
                }
                
                Text(label)
                    .font(BrandFont.labelMedium)
                    .foregroundColor(isSelected ? BrandColor.onSurface : BrandColor.onSurfaceVariant)
            }
            .frame(width: 80, height: 80)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Button Presets (MD3 Style)
extension Button where Label == Text {
    static func md3Button(_ title: String, type: MD3ButtonStyle.ButtonType = .filled, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .buttonStyle(MD3ButtonStyle(type: type))
    }
    
    static func md3TonalButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .buttonStyle(MD3ButtonStyle(type: .tonal))
    }
    
    static func md3TextButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .buttonStyle(MD3ButtonStyle(type: .text))
    }
}

// MARK: - Backward Compatibility Aliases
typealias CuteCard = MD3Card
typealias CuteTextField = MD3TextField
typealias NeobrutalismAlert = MD3Dialog
typealias NeobrutalismSheetHeader = MD3SheetHeader
typealias CapsuleButtonStyle = MD3ButtonStyle
typealias GhostButtonStyle = MD3ButtonStyle
typealias AlertButtonStyle = MD3ButtonStyle

// MARK: - 彩色图标系统
struct ColorfulIcon: View {
    enum IconType {
        case calendar
        case sparkles
        case bell
        case plus
        case settings
        case list
        case today
        case alarm
        case microphone
        case keyboard
        
        var systemName: String {
            switch self {
            case .calendar: return "calendar.day.timeline.left"
            case .sparkles: return "sparkles"
            case .bell: return "bell.badge.fill"
            case .plus: return "plus.circle.fill"
            case .settings: return "gearshape.circle.fill"
            case .list: return "list.bullet.circle.fill"
            case .today: return "calendar.badge.clock"
            case .alarm: return "alarm.fill"
            case .microphone: return "mic.circle.fill"
            case .keyboard: return "keyboard.fill"
            }
        }
        
        var colors: [Color] {
            switch self {
            // 主要功能 - 品牌色系（蓝色系）
            case .calendar:
                return [BrandColor.primary, BrandColor.primary.opacity(0.8)]
            case .list:
                return [BrandColor.primaryBlue, BrandColor.primaryBlue.opacity(0.8)]
            case .sparkles:
                return [BrandColor.primaryYellow, BrandColor.primaryYellow.opacity(0.8)]
                
            // 功能性图标 - 中性灰色系
            case .settings:
                return [BrandColor.onSurfaceVariant, BrandColor.onSurfaceVariant.opacity(0.7)]
            case .plus:
                return [BrandColor.onSurfaceVariant, BrandColor.onSurfaceVariant.opacity(0.7)]
            case .today:
                return [BrandColor.onSurfaceVariant, BrandColor.onSurfaceVariant.opacity(0.7)]
                
            // 提醒/通知类 - 暖色系（温和）
            case .bell:
                return [BrandColor.primaryYellow, BrandColor.primaryYellow.opacity(0.8)]
            case .alarm:
                return [BrandColor.primaryYellow, BrandColor.primaryYellow.opacity(0.8)]
                
            // 交互类 - 保持适当对比
            case .microphone:
                return [BrandColor.danger, BrandColor.danger.opacity(0.8)]
            case .keyboard:
                return [BrandColor.primary, BrandColor.primary.opacity(0.8)]
            }
        }
    }
    
    let type: IconType
    let size: CGFloat
    let weight: Font.Weight
    
    init(_ type: IconType, size: CGFloat = 20, weight: Font.Weight = .bold) {
        self.type = type
        self.size = size
        self.weight = weight
    }
    
    var body: some View {
        Image(systemName: type.systemName)
            .font(.system(size: size, weight: weight))
            .foregroundStyle(
                LinearGradient(
                    colors: type.colors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }
}

// MARK: - 彩色按钮图标
struct ColorfulIconButton: View {
    let type: ColorfulIcon.IconType
    let size: CGFloat
    let action: () -> Void
    
    init(_ type: ColorfulIcon.IconType, size: CGFloat = 24, action: @escaping () -> Void) {
        self.type = type
        self.size = size
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            ColorfulIcon(type, size: size)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 彩色TabBar图标
struct ColorfulTabIcon: View {
    let type: ColorfulIcon.IconType
    let isSelected: Bool
    let size: CGFloat
    
    init(_ type: ColorfulIcon.IconType, isSelected: Bool, size: CGFloat = 18) {
        self.type = type
        self.isSelected = isSelected
        self.size = size
    }
    
    var body: some View {
        ColorfulIcon(
            type, 
            size: isSelected ? size + 2 : size, 
            weight: isSelected ? .bold : .semibold
        )
        .opacity(isSelected ? 1.0 : 0.6) // 未选中时稍微透明
        .scaleEffect(isSelected ? 1.05 : 1.0) // 减小缩放幅度
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}


// MARK: - 事件类型标识
struct EventTypeBadge: View {
    let event: Event
    
    var body: some View {
        HStack(spacing: 4) {
            Text(isRecurringEvent ? "🔄" : "📋")
                .font(BrandFont.body(size: 10))
            
            Text(isRecurringEvent ? "重复事件" : "普通事件")
                .font(BrandFont.body(size: 10, weight: .medium))
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(badgeColor.opacity(0.2))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(badgeColor, lineWidth: 1)
        )
        .foregroundColor(badgeColor)
    }
    
    private var isRecurringEvent: Bool {
        return event.recurrenceGroupId != nil
    }
    
    private var badgeColor: Color {
        return isRecurringEvent ? BrandColor.primaryYellow : BrandColor.onSurfaceVariant
    }
}