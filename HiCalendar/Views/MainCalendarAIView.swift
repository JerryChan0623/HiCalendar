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
    @State private var sheetDateItem: SheetDateItem? = nil  // 使用SheetDateItem进行sheet绑定
    @State private var scrollToToday: Bool = false
    @StateObject private var backgroundManager = BackgroundImageManager.shared
    @StateObject private var storageManager = EventStorageManager.shared
    
    // 响应式访问，会触发重新渲染
    private var allEvents: [Event] {
        storageManager.events
    }
    
    var body: some View {
        NavigationStack {
            InfiniteMonthCalendarView(
                selectedDate: $selectedDate,
                allEvents: allEvents,
                onDateTap: { date in
                    // 确保使用正确的日期格式 - 使用 startOfDay 来避免时区问题
                    let calendar = Calendar.current
                    let normalizedDate = calendar.startOfDay(for: date)
                    
                    // 确保状态更新在主线程上按正确顺序执行
                    DispatchQueue.main.async {
                        // 先更新选中日期
                        selectedDate = normalizedDate
                        // 设置sheet日期项并显示
                        sheetDateItem = SheetDateItem(date: normalizedDate)
                    }
                }
            )

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
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        selectedDate = Date()
                    }) {
                        Text("今天 ⚡")
                            .font(BrandFont.body(size: 14, weight: .semibold))
                            .foregroundColor(BrandColor.onPrimary)
                            .frame(width: 60, height: 32)
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
        }
        .sheet(item: $sheetDateItem) { dateItem in
            EventDrawerView(selectedDate: dateItem.date)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
    }
    

    

    



    



}

// MARK: - Infinite Month Calendar View
struct InfiniteMonthCalendarView: View {
    @Binding var selectedDate: Date
    let allEvents: [Event]
    let onDateTap: (Date) -> Void
    
    @State private var visibleMonths: [Date] = []
    
    private let calendar = Calendar.current
    
    var body: some View {
        ScrollViewReader { proxy in
                    ScrollView {
                LazyVStack(spacing: BrandSpacing.xl) {
                    ForEach(visibleMonths, id: \.self) { monthDate in
                        VStack(spacing: BrandSpacing.md) {
                            // 月份标题
                            monthHeader(for: monthDate)
                            
                            // 月历
                            MonthCalendarGrid(
                                monthDate: monthDate,
                                selectedDate: $selectedDate,
                                events: allEvents,
                                onDateTap: onDateTap
                            )
                            .padding(.horizontal, BrandSpacing.sm)
                        }
                        .id(monthDate)
                    }
                }
                .padding(.vertical, BrandSpacing.lg)
            }
            .onAppear {
                setupVisibleMonths()
                let currentDate = Date()
                let currentMonthStart = calendar.dateInterval(of: .month, for: currentDate)!.start
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                    proxy.scrollTo(currentMonthStart, anchor: .top)
                }
            }
            .onChange(of: selectedDate) {
                let selectedMonthStart = calendar.dateInterval(of: .month, for: selectedDate)!.start
                withAnimation(.easeInOut(duration: 0.5)) {
                    proxy.scrollTo(selectedMonthStart, anchor: .top)
                }
            }
        }
    }
    
    private func monthHeader(for date: Date) -> some View {
        Text(yearMonthString(date))
            .font(BrandFont.display(size: 20, weight: .bold))
            .foregroundColor(BrandColor.onSurface)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, BrandSpacing.sm)
    }
    
    private func setupVisibleMonths() {
        let currentDate = Date()
        var months: [Date] = []
        
        // 生成前后12个月，总共25个月
        for i in -12...12 {
            if let monthDate = calendar.date(byAdding: .month, value: i, to: currentDate) {
                months.append(calendar.dateInterval(of: .month, for: monthDate)!.start)
            }
        }
        
        visibleMonths = months
    }
    


    private func yearMonthString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh-Hans_CN")
        formatter.dateFormat = "yyyy年M月"
        return formatter.string(from: date)
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
        VStack(spacing: BrandSpacing.sm) {
            // 星期标题
            weekdayHeaders
            
            // 日期网格
            calendarGrid
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
                        .frame(maxWidth: .infinity, minHeight: 60)
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

// MARK: - Event Drawer View
struct EventDrawerView: View {
    let selectedDate: Date
    
    @State private var newEventTitle: String = ""
    @FocusState private var isInputFocused: Bool
    @State private var eventToEdit: Event?
    @State private var showCreateEvent = false
    
    // 本地事件状态，完全自己管理数据
    @State private var localEvents: [Event] = []
    @StateObject private var storageManager = EventStorageManager.shared
    
    // 简化初始化，完全独立管理数据
    init(selectedDate: Date) {
        self.selectedDate = selectedDate
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 自定义Sheet Header
                NeobrutalismSheetHeader()
                
                // 日期标题区域 - 固定在顶部
                VStack(alignment: .leading, spacing: BrandSpacing.lg) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(selectedDate.formatted(.dateTime.month().day().weekday(.wide)))
                            .font(BrandFont.displayMedium)
                            .foregroundColor(BrandColor.onSurface)
                        Text("\(localEvents.count)件事儿等着你")
                            .font(BrandFont.bodySmall)
                            .foregroundColor(BrandColor.outline)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(BrandSpacing.lg)
                
                // 主内容区域
                if localEvents.isEmpty {
                    // 空状态：使用可爱动画
                    VStack {
                        Spacer()
                        CuteEmptyCalendarView()
                        Spacer()
                    }
                } else {
                    // 有事项时：显示事项列表
                    ScrollView {
                        LazyVStack(spacing: BrandSpacing.md) {
                            ForEach(localEvents) { event in
                                EventDetailCard(
                                    event: event,
                                    onDelete: {
                                        // 直接调用 storageManager，避免通过外部回调触发父视图重新渲染
                                        storageManager.deleteEvent(event)
                                        refreshEvents() // 删除后立即刷新本地数据
                                    },
                                    onEdit: {
                                        eventToEdit = event
                                    }
                                )
                                .onTapGesture {
                                    eventToEdit = event
                                }
                            }
                        }
                        .padding(.horizontal, BrandSpacing.lg)
                        .padding(.top, BrandSpacing.md)
                        .padding(.bottom, BrandSpacing.sm)
                    }
                }
                
                // 输入框区域
                VStack(spacing: BrandSpacing.sm) {
                    Divider()
                        .background(BrandColor.outlineVariant)
                    
                    HStack(spacing: BrandSpacing.sm) {
                        TextField("快速添加事项...", text: $newEventTitle)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: BrandRadius.sm)
                                    .fill(BrandColor.surface)
                                    .neobrutalStyle(cornerRadius: BrandRadius.sm,
                                                   borderWidth: BrandBorder.regular)
                            )
                            .focused($isInputFocused)
                            .onSubmit {
                                createNewEvent()
                            }
                            .toolbar {
                                ToolbarItemGroup(placement: .keyboard) {
                                    Spacer()
                                    Button("收起") {
                                        isInputFocused = false
                                    }
                                    .foregroundColor(BrandColor.primaryBlue)
                                }
                            }
                        
                        // 快速添加按钮
                        ColorfulIconButton(.plus, size: 24, action: createNewEvent)
                        .disabled(newEventTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    .padding(.horizontal, BrandSpacing.lg)
                    .padding(.bottom, isInputFocused ? BrandSpacing.xl : BrandSpacing.sm)
                    .animation(.easeInOut(duration: 0.25), value: isInputFocused)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                BrandColor.background
                    .ignoresSafeArea(.container, edges: .bottom)
            )
            .navigationBarHidden(true)
            .onAppear {
                // 视图出现时立即刷新数据
                refreshEvents()
            }
            .sheet(item: $eventToEdit) { event in
                VStack(spacing: 0) {
                    // 自定义Sheet Header
                    NeobrutalismSheetHeader()
                    
                    EventEditView(
                        mode: .edit(event),
                        initialDate: selectedDate,
                        onSave: {
                            // 编辑完成后关闭编辑sheet，清空eventToEdit，刷新数据
                            eventToEdit = nil
                            refreshEvents()
                        }
                    )
                }
                .presentationDragIndicator(.hidden)
            }
            .sheet(isPresented: $showCreateEvent) {
                VStack(spacing: 0) {
                    // 自定义Sheet Header
                    NeobrutalismSheetHeader()
                    
                    EventEditView(
                        mode: .create,
                        initialDate: selectedDate,
                        onSave: {
                            // 创建完成后关闭创建sheet，刷新数据
                            showCreateEvent = false
                            refreshEvents()
                        }
                    )
                }
                .presentationDragIndicator(.hidden)
            }
        }
    }
    
    private func createNewEvent() {
        let trimmedTitle = newEventTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        
        // 直接调用 storageManager，避免通过外部回调触发父视图重新渲染
        _ = storageManager.createEvent(title: trimmedTitle, date: selectedDate)
        
        newEventTitle = ""
        isInputFocused = false
        
        // 直接刷新本地数据
        refreshEvents()
    }
    
    // 刷新本地事件数据
    private func refreshEvents() {
        localEvents = storageManager.eventsForDate(selectedDate)
    }
}

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
    
    var body: some View {
        VStack(alignment: .leading, spacing: BrandSpacing.sm) {
            // 时间提示（如"就是今天！"）- 显示在卡片左上方
            if showTimePrompt, let prompt = timePrompt {
                HStack {
                    if prompt.isUrgent {
                        Text(prompt.text)
                            .font(BrandFont.body(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, BrandSpacing.xs)
                            .padding(.vertical, 2)
                            .background(prompt.color)
                            .cornerRadius(BrandRadius.sm)
                    } else {
                        Text(prompt.text)
                            .font(BrandFont.body(size: 12, weight: .medium))
                            .foregroundColor(prompt.color)
                    }
                    
                    Spacer()
                }
            }
            
            // 标题行：标题 + 时间 + 闹铃图标
            HStack {
                Text(event.title)
                    .font(BrandFont.body(size: 16, weight: .bold))
                    .foregroundColor(BrandColor.onSurface)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack(spacing: BrandSpacing.xs) {
                    // 闹铃图标（有短期提醒时显示）
                    if hasShortTermReminder {
                        ColorfulIcon(.bell, size: 13)
                    }
                    
                    // 时间信息（右对齐）
                    if let timeString = timeDisplayString, !timeString.isEmpty {
                        Text(timeString)
                            .font(BrandFont.body(size: 14, weight: .medium))
                            .foregroundColor(BrandColor.onSurface.opacity(0.7))
                    }
                }
            }
            
            // 详情信息
            if let details = event.details, !details.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(details)
                    .font(BrandFont.body(size: 14, weight: .regular))
                    .foregroundColor(BrandColor.onSurface.opacity(0.6))
                    .multilineTextAlignment(.leading)
            }
        }
        .padding(BrandSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: BrandRadius.lg, style: .continuous)
                .fill(BrandColor.surface)
                .neobrutalStyle(cornerRadius: BrandRadius.lg,
                               borderWidth: BrandBorder.regular)
        )
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
            return ("过期啦 💀", BrandColor.neutral500, false)
        case 0:
            return ("就是今天！", BrandColor.danger, true)
        case 1:
            return ("明儿见", BrandColor.warning, true)
        case 2:
            return ("后天啦", BrandColor.warning, true)
        case 3...7:
            return ("\(days) 天后", BrandColor.primaryYellow, false)
        case 8...30:
            return ("\(days) 天后", BrandColor.primaryBlue, false)
        default:
            let weeks = days / 7
            if weeks < 4 {
                return ("\(weeks) 周后", BrandColor.primaryBlue, false)
            } else {
                return ("遥遥无期 🌙", BrandColor.neutral700, false)
            }
        }
    }
    
    

}

#Preview {
    MainCalendarAIView()
}
