//
//  MainCalendarAIView.swift
//  HiCalendar
//
//  Created on 2024. Cute Calendar AI 主页面（日历+AI融合）
//

import SwiftUI
import UIKit

// 辅助结构体，用于 sheet(item:) 绑定
struct SheetDateItem: Identifiable {
    let id = UUID()
    let date: Date
}

struct MainCalendarAIView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedDate = Calendar.current.startOfDay(for: Date())
    @State private var currentMonthDate = Date() // 当前显示的月份
    @StateObject private var backgroundManager = BackgroundImageManager.shared
    @StateObject private var storageManager = EventStorageManager.shared
    @State private var eventToEdit: Event?
    @State private var showCreateEvent = false
    @State private var showMonthYearPicker = false // 月份选择器状态
    @State private var quickAddText = "" // 快速添加输入框文本
    @FocusState private var isQuickAddFocused: Bool // 输入框焦点状态

    private let calendar = Calendar.current

    // 响应式访问，会触发重新渲染
    private var allEvents: [Event] {
        storageManager.events
    }

    // 获取选中日期的事项列表
    private var selectedDateEvents: [Event] {
        storageManager.eventsForDate(selectedDate)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // 整体可滚动容器
                ScrollView {
                    VStack(spacing: 0) {
                        // 日历网格（移除了月份导航栏）
                        SingleMonthCalendarView(
                            monthDate: currentMonthDate,
                            selectedDate: $selectedDate,
                            allEvents: allEvents,
                            onDateTap: { date in
                                let normalizedDate = calendar.startOfDay(for: date)
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedDate = normalizedDate
                                }
                            }
                        )
                        .padding(.horizontal, BrandSpacing.md)
                        .padding(.vertical, BrandSpacing.sm)

                        Divider()
                            .background(BrandColor.outlineVariant)
                            .padding(.vertical, BrandSpacing.xs)

                        // 选中日期标题
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(selectedDate.formatted(.dateTime.month().day().weekday(.wide)))
                                    .font(BrandFont.body(size: 16, weight: .bold))
                                    .foregroundColor(BrandColor.onSurface)
                                Text(L10n.eventsWaitingForYou(selectedDateEvents.count))
                                    .font(BrandFont.body(size: 12, weight: .regular))
                                    .foregroundColor(BrandColor.outline)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, BrandSpacing.lg)
                        .padding(.vertical, BrandSpacing.sm)

                        // 事项列表或空状态
                        if selectedDateEvents.isEmpty {
                            // 空状态
                            VStack {
                                Spacer()
                                CuteEmptyCalendarView()
                                Spacer()
                            }
                            .frame(height: 250)
                        } else {
                            // 事项列表
                            LazyVStack(spacing: BrandSpacing.xs) {
                                ForEach(selectedDateEvents) { event in
                                    EventDetailCard(
                                        event: event,
                                        onDelete: {
                                            storageManager.deleteEvent(event)
                                        },
                                        onEdit: {
                                            eventToEdit = event
                                        }
                                    )
                                    .environmentObject(storageManager)
                                    .onTapGesture {
                                        eventToEdit = event
                                    }
                                }
                            }
                            .padding(.horizontal, BrandSpacing.lg)
                            .padding(.bottom, 80) // 底部留出空间给快速添加栏
                        }
                    }
                }

                // 底部快速添加栏 - 固定在底部
                VStack {
                    Spacer()
                    quickAddBar
                }
            }
            .background(
                ZStack {
                    // 背景图片或默认背景
                    if backgroundManager.hasCustomBackground, let image = backgroundManager.backgroundImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .ignoresSafeArea()
                            .overlay(
                                // 半透明遮罩确保内容可读（适配暗黑模式）
                                (colorScheme == .dark ? Color.black : Color.white)
                                    .opacity(colorScheme == .dark ? 0.6 : 0.7)
                                    .ignoresSafeArea()
                            )
                    } else {
                        // 主背景（适配暗黑模式）
                        BrandColor.background
                            .ignoresSafeArea()
                    }
                }
            )
            .toolbar {
                // 左侧：年月显示（可点击弹出选择器）
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showMonthYearPicker = true
                    }) {
                        HStack(spacing: 4) {
                            Text(yearMonthString(currentMonthDate))
                                .font(BrandFont.display(size: 18, weight: .bold))
                                .foregroundColor(BrandColor.onSurface)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(BrandColor.outline)
                        }
                    }
                }

                // 右侧：今天按钮
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        withAnimation {
                            selectedDate = Date()
                            currentMonthDate = Date()
                        }
                    }) {
                        Text("\(L10n.today) ⚡")
                            .font(BrandFont.body(size: 14, weight: .semibold))
                            .foregroundColor(BrandColor.onPrimary)
                            .padding(.horizontal, BrandSpacing.sm)
                            .frame(height: 32)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: BrandRadius.sm)
                            .fill(BrandColor.primary)
                    )
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // 设置导航栏外观为透明
                let appearance = UINavigationBarAppearance()
                appearance.configureWithTransparentBackground()
                appearance.backgroundColor = UIColor.clear
                appearance.shadowColor = UIColor.clear

                UINavigationBar.appearance().standardAppearance = appearance
                UINavigationBar.appearance().scrollEdgeAppearance = appearance
                UINavigationBar.appearance().compactAppearance = appearance
            }
            .sheet(item: $eventToEdit) { event in
                VStack(spacing: 0) {
                    NeobrutalismSheetHeader()
                    EventEditView(
                        mode: .edit(event),
                        initialDate: selectedDate,
                        onSave: {
                            eventToEdit = nil
                        }
                    )
                }
                .presentationDragIndicator(.hidden)
            }
            .sheet(isPresented: $showCreateEvent) {
                VStack(spacing: 0) {
                    NeobrutalismSheetHeader()
                    EventEditView(
                        mode: .create,
                        initialDate: selectedDate,
                        onSave: {
                            showCreateEvent = false
                        }
                    )
                }
                .presentationDragIndicator(.hidden)
            }
            .sheet(isPresented: $showMonthYearPicker) {
                MonthYearPickerView(
                    selectedDate: $currentMonthDate,
                    onDismiss: {
                        showMonthYearPicker = false
                    }
                )
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - 底部快速添加栏
    private var quickAddBar: some View {
        HStack(spacing: BrandSpacing.sm) {
            // 输入框
            HStack(spacing: BrandSpacing.sm) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(BrandColor.primary)

                TextField(L10n.quickAddPlaceholder, text: $quickAddText)
                    .font(BrandFont.body(size: 15, weight: .medium))
                    .foregroundColor(BrandColor.onSurface)
                    .focused($isQuickAddFocused)
                    .submitLabel(.done)
                    .onSubmit {
                        quickAddEvent()
                    }

                // 添加按钮（有文字时显示）
                if !quickAddText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Button(action: {
                        quickAddEvent()
                    }) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(BrandColor.primary)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, BrandSpacing.md)
            .padding(.vertical, BrandSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: BrandRadius.lg, style: .continuous)
                    .fill(BrandColor.surface)
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: -2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: BrandRadius.lg, style: .continuous)
                    .stroke(BrandColor.outline.opacity(0.2), lineWidth: 1)
            )
        }
        .padding(.horizontal, BrandSpacing.md)
        .padding(.bottom, BrandSpacing.md)
        .animation(.easeInOut(duration: 0.2), value: quickAddText)
    }

    // MARK: - 快速添加事项方法
    private func quickAddEvent() {
        let title = quickAddText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }

        // 创建事项（归属到当前选中的日期）
        let newEvent = Event(
            title: title,
            intendedDate: selectedDate,
            isSynced: false,
            isOnboarding: false
        )

        storageManager.addEvent(newEvent)

        // 清空输入框并收起键盘
        quickAddText = ""
        isQuickAddFocused = false

        // 触觉反馈
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    private func yearMonthString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = L10n.dateFormatYearMonth
        return formatter.string(from: date)
    }
    

    

    



    



}

// MARK: - Single Month Calendar View
struct SingleMonthCalendarView: View {
    let monthDate: Date
    @Binding var selectedDate: Date
    let allEvents: [Event]
    let onDateTap: (Date) -> Void

    private let calendar = Calendar.current

    var body: some View {
        VStack(spacing: BrandSpacing.md) {
            // 星期标题
            weekdayHeaders

            // 日期网格
            MonthCalendarGrid(
                monthDate: monthDate,
                selectedDate: $selectedDate,
                events: allEvents,
                onDateTap: onDateTap
            )
        }
    }

    private var weekdayHeaders: some View {
        HStack {
            ForEach(["日", "一", "二", "三", "四", "五", "六"], id: \.self) { weekday in
                Text(weekday)
                    .font(BrandFont.body(size: 12, weight: .bold))
                    .foregroundColor(BrandColor.outline)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

// MARK: - Month Calendar Grid
struct MonthCalendarGrid: View {
    let monthDate: Date
    @Binding var selectedDate: Date
    let events: [Event]
    let onDateTap: (Date) -> Void

    private let calendar = Calendar.current

    var body: some View {
        calendarGrid
    }
    
    private var calendarGrid: some View {
        let monthDays = generateMonthDays()
        
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 6) {
            ForEach(monthDays, id: \.self) { date in
                if let date = date {
                    CalendarDayCell(
                        day: calendar.component(.day, from: date),
                        isToday: calendar.isDateInToday(date),
                        isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                        events: eventsForDate(date)
                    )
                    .onTapGesture {
                        onDateTap(date)
                    }
                } else {
                    Color.clear
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .aspectRatio(1, contentMode: .fit)
                }
            }
        }
    }
    
    private func generateMonthDays() -> [Date?] {
        let monthRange = calendar.range(of: .day, in: .month, for: monthDate)!
        let firstOfMonth = calendar.dateInterval(of: .month, for: monthDate)!.start
        let startingWeekday = calendar.component(.weekday, from: firstOfMonth) - 1
        
        var days: [Date?] = Array(repeating: nil, count: startingWeekday)
        
        for day in 1...monthRange.count {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                days.append(date)
            }
        }
        
        return days
    }
    
    private func eventsForDate(_ date: Date) -> [Event] {
        return events.filter { event in
            // 现在都是独立事件，不需要过滤容器事件
            if let startAt = event.startAt {
                // 有执行时间：按执行日期过滤
                return calendar.isDate(startAt, inSameDayAs: date)
            } else {
                // 无执行时间：优先使用intendedDate，如为空则回退到createdAt
                if let intendedDate = event.intendedDate {
                    return calendar.isDate(intendedDate, inSameDayAs: date)
                } else {
                    return calendar.isDate(event.createdAt, inSameDayAs: date)
                }
            }
        }
    }
}



// MARK: - Compact Event Card
struct CompactEventCard: View {
    let event: Event
    
    var body: some View {
        HStack(spacing: BrandSpacing.md) {
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(BrandFont.body(size: 14, weight: .bold))
                    .foregroundColor(BrandColor.onSurface)
                
                Text(event.timeRangeString)
                    .font(BrandFont.bodySmall)
                    .foregroundColor(BrandColor.outline)
            }
            
            Spacer()
            
            ConflictBadge(status: .none)
        }
        .padding(.horizontal, BrandSpacing.md)
        .padding(.vertical, BrandSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: BrandRadius.md, style: .continuous)
                .fill(Color.white.opacity(0.8))
        )
    }
}

// MARK: - Event List Section（固定显示在日历下方）
struct EventListSection: View {
    let selectedDate: Date
    let events: [Event]
    let onEventTap: (Event) -> Void
    let onCreateEvent: () -> Void

    @State private var newEventTitle: String = ""
    @FocusState private var isInputFocused: Bool
    @StateObject private var storageManager = EventStorageManager.shared

    var body: some View {
        VStack(spacing: 0) {
            // 日期标题 - 不显示添加按钮
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(selectedDate.formatted(.dateTime.month().day().weekday(.wide)))
                        .font(BrandFont.body(size: 16, weight: .bold))
                        .foregroundColor(BrandColor.onSurface)
                    Text(L10n.eventsWaitingForYou(events.count))
                        .font(BrandFont.body(size: 12, weight: .regular))
                        .foregroundColor(BrandColor.outline)
                }

                Spacer()
            }
            .padding(.horizontal, BrandSpacing.lg)
            .padding(.vertical, BrandSpacing.sm)

            // 事项列表或空状态
            if events.isEmpty {
                // 空状态
                VStack {
                    Spacer()
                    CuteEmptyCalendarView()
                    Spacer()
                }
                .frame(maxHeight: .infinity)
            } else {
                // 事项列表 - 支持滚动
                ScrollView {
                    LazyVStack(spacing: BrandSpacing.xs) {
                        ForEach(events) { event in
                            EventDetailCard(
                                event: event,
                                onDelete: {
                                    storageManager.deleteEvent(event)
                                },
                                onEdit: {
                                    onEventTap(event)
                                }
                            )
                            .environmentObject(storageManager)
                            .onTapGesture {
                                onEventTap(event)
                            }
                        }
                    }
                    .padding(.horizontal, BrandSpacing.lg)
                    .padding(.bottom, BrandSpacing.xxl) // 底部留出空间避免被浮动按钮遮挡
                }
            }
        }
        .frame(maxHeight: .infinity)
    }
}

// MARK: - Event Drawer View (Deprecated - 已移除Sheet弹窗方式)

// MARK: - Extensions
extension Color {
    var asLinearGradient: LinearGradient {
        LinearGradient(colors: [self], startPoint: .top, endPoint: .bottom)
    }
}

// 动态高度修饰器：根据给定的总高度与比例设置内容高度；比例为空时不限制高度
struct CalendarHeightModifier: ViewModifier {
    let totalHeight: CGFloat
    let fraction: CGFloat?
    
    func body(content: Content) -> some View {
        if let fraction, fraction > 0, fraction < 1 {
            content.frame(height: totalHeight * fraction)
        } else {
            content
        }
    }
}


// MARK: - 事项详情卡片
struct EventDetailCard: View {
    let event: Event
    let onDelete: () -> Void
    let onEdit: () -> Void
    var showTimePrompt: Bool = false  // 是否显示时间提示（如"就是今天！"）

    @EnvironmentObject var storageManager: EventStorageManager

    var body: some View {
        // 卡片内容（移除左滑完成状态功能）
        cardContent
    }

    private var cardContent: some View {
        HStack(alignment: .center, spacing: BrandSpacing.sm) {
            // 完成按钮
            Button(action: {
                // 触觉反馈
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()

                withAnimation(.easeInOut(duration: 0.2)) {
                    storageManager.toggleEventCompletion(event)
                }
            }) {
                Image(systemName: event.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(event.isCompleted ? BrandColor.success : BrandColor.neutral300)
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())

            // 事项内容
            eventContentView
                .opacity(event.isCompleted ? 0.5 : 1.0)
        }
        .padding(.horizontal, BrandSpacing.sm)
        .padding(.vertical, BrandSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: BrandRadius.md, style: .continuous)
                .fill(BrandColor.surface)
                .neobrutalStyle(cornerRadius: BrandRadius.md,
                               borderWidth: BrandBorder.regular)
        )
    }

    private var eventContentView: some View {
        VStack(alignment: .leading, spacing: BrandSpacing.xs) {
            // 时间提示（如"就是今天！"）- 显示在卡片左上方
            if showTimePrompt, let prompt = timePrompt {
                HStack {
                    if prompt.isUrgent {
                        Text(prompt.text)
                            .font(BrandFont.body(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, BrandSpacing.xs)
                            .padding(.vertical, 2)
                            .background(prompt.color)
                            .cornerRadius(BrandRadius.sm)
                    } else {
                        Text(prompt.text)
                            .font(BrandFont.body(size: 10, weight: .medium))
                            .foregroundColor(prompt.color)
                    }

                    Spacer()
                }
            }

            // 标题行：标题 + 时间 + 闹铃图标
            HStack {
                Text(event.title)
                    .font(BrandFont.body(size: 14, weight: .bold))
                    .foregroundColor(BrandColor.onSurface)
                    .strikethrough(event.isCompleted, color: BrandColor.neutral500)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: BrandSpacing.xs) {
                    // 闹铃图标（有短期提醒时显示）
                    if hasShortTermReminder {
                        ColorfulIcon(.bell, size: 11)
                    }

                    // 时间信息（右对齐）
                    if let timeString = timeDisplayString, !timeString.isEmpty {
                        Text(timeString)
                            .font(BrandFont.body(size: 12, weight: .medium))
                            .foregroundColor(BrandColor.onSurface.opacity(0.7))
                    }
                }
            }

            // 详情信息
            if let details = event.details, !details.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(details)
                    .font(BrandFont.body(size: 12, weight: .regular))
                    .foregroundColor(BrandColor.onSurface.opacity(0.6))
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var timeDisplayString: String? {
        // 只显示执行时间点（startAt），不显示时间段
        if let startAt = event.startAt {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: startAt)
        } else {
            return nil  // 没有设置时间时不显示时间信息
        }
    }
    
    // 判断是否有短期提醒（非1天前/1周前的提醒）
    private var hasShortTermReminder: Bool {
        let shortTermReminders: [PushReminderOption] = [.atTime, .minutes15, .minutes30, .hours1, .hours2]
        return event.pushReminders.contains { shortTermReminders.contains($0) }
    }
    
    // 时间提示计算
    private var timePrompt: (text: String, color: Color, isUrgent: Bool)? {
        guard showTimePrompt, let startAt = event.startAt else { return nil }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let targetDate = calendar.startOfDay(for: startAt)
        let components = calendar.dateComponents([.day], from: today, to: targetDate)
        let days = components.day ?? 0

        switch days {
        case ..<0:
            return (L10n.expiredEvent, BrandColor.neutral500, false)
        case 0:
            return (L10n.eventToday, BrandColor.danger, true)
        case 1:
            return (L10n.eventTomorrow, BrandColor.warning, true)
        case 2:
            return (L10n.eventDayAfterTomorrow, BrandColor.warning, true)
        case 3...7:
            return (L10n.eventDaysLater(days), BrandColor.primaryYellow, false)
        case 8...30:
            return (L10n.eventDaysLater(days), BrandColor.primaryBlue, false)
        default:
            let weeks = days / 7
            if weeks < 4 {
                return (L10n.eventWeeksLater(weeks), BrandColor.primaryBlue, false)
            } else {
                return (L10n.eventVeryFarFuture, BrandColor.neutral700, false)
            }
        }
    }



}

// MARK: - 月份年份选择器
struct MonthYearPickerView: View {
    @Binding var selectedDate: Date
    let onDismiss: () -> Void

    @State private var selectedYear: Int
    @State private var selectedMonth: Int

    private let calendar = Calendar.current
    private let years: [Int]
    private let months = Array(1...12)

    init(selectedDate: Binding<Date>, onDismiss: @escaping () -> Void) {
        self._selectedDate = selectedDate
        self.onDismiss = onDismiss

        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: selectedDate.wrappedValue)
        let currentMonth = calendar.component(.month, from: selectedDate.wrappedValue)

        self._selectedYear = State(initialValue: currentYear)
        self._selectedMonth = State(initialValue: currentMonth)

        // 生成年份范围：前后10年
        let thisYear = calendar.component(.year, from: Date())
        self.years = Array((thisYear - 10)...(thisYear + 10))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: BrandSpacing.lg) {
                // 年月选择器
                HStack(spacing: 0) {
                    // 年份选择
                    Picker("Year", selection: $selectedYear) {
                        ForEach(years, id: \.self) { year in
                            Text("\(year)年")
                                .tag(year)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)

                    // 月份选择
                    Picker("Month", selection: $selectedMonth) {
                        ForEach(months, id: \.self) { month in
                            Text("\(month)月")
                                .tag(month)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)
                }
                .frame(height: 200)

                // 确认按钮
                Button(action: {
                    applySelection()
                }) {
                    Text(L10n.confirm)
                        .font(BrandFont.body(size: 16, weight: .bold))
                        .foregroundColor(BrandColor.onPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: BrandRadius.md, style: .continuous)
                                .fill(BrandColor.primary)
                        )
                }
                .padding(.horizontal, BrandSpacing.lg)

                Spacer()
            }
            .padding(.top, BrandSpacing.lg)
            .navigationTitle(L10n.selectMonth)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L10n.cancel) {
                        onDismiss()
                    }
                    .foregroundColor(BrandColor.primaryBlue)
                }
            }
        }
    }

    private func applySelection() {
        var components = DateComponents()
        components.year = selectedYear
        components.month = selectedMonth
        components.day = 1

        if let newDate = calendar.date(from: components) {
            withAnimation {
                selectedDate = newDate
            }
        }
        onDismiss()
    }
}

#Preview {
    MainCalendarAIView()
}
