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
    @State private var selectedDate = Calendar.current.startOfDay(for: Date())
    @State private var sheetDate: Date? = nil  // 使用可选类型，当有值时显示sheet
    @State private var scrollToToday: Bool = false
    @StateObject private var backgroundManager = BackgroundImageManager.shared
    
    // 只读访问，不会触发重新渲染
    private var allEvents: [Event] {
        EventStorageManager.shared.events
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
                        // 立即设置sheet日期来触发显示
                        sheetDate = normalizedDate
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
                                // 半透明遮罩确保内容可读
                                Color.white.opacity(0.7)
                                    .ignoresSafeArea()
                            )
                    } else {
                        // Neobrutalism 主背景 - 纯白色
                        BrandColor.neutral100
                            .ignoresSafeArea()
                    }
                }
            )
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        selectedDate = Date()
                    }) {
                        Text("今日")
                            .font(BrandFont.body(size: 12, weight: .bold))
                            .foregroundColor(BrandColor.neutral900)
                            .frame(minWidth: 40)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, BrandSpacing.md)
                    .padding(.vertical, BrandSpacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: BrandRadius.sm)
                            .fill(BrandColor.primaryYellow)
                            .neobrutalStyle(cornerRadius: BrandRadius.sm,
                                          borderWidth: BrandBorder.regular)
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
        .sheet(item: Binding<SheetDateItem?>(
            get: { sheetDate.map(SheetDateItem.init) },
            set: { _ in sheetDate = nil }
        )) { dateItem in
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
            .onChange(of: selectedDate) { _ in
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
            .foregroundColor(BrandColor.neutral900)
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
                    .foregroundColor(BrandColor.neutral500)
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
            if let startAt = event.startAt {
                return calendar.isDate(startAt, inSameDayAs: date)
            } else {
                // 理论上不应该存在没有 startAt 的事项
                return false
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
                    .foregroundColor(BrandColor.neutral900)
                
                Text(event.timeRangeString)
                    .font(BrandFont.bodySmall)
                    .foregroundColor(BrandColor.neutral500)
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
    @State private var showEventEdit = false
    
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
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(selectedDate.formatted(.dateTime.month().day().weekday(.wide)))
                                .font(BrandFont.displayMedium)
                                .foregroundColor(BrandColor.neutral900)
                            Text("\(localEvents.count)个事项")
                                .font(BrandFont.bodySmall)
                                .foregroundColor(BrandColor.neutral500)
                        }
                        Spacer()
                        
                        // 装饰性图标
                        Image(systemName: localEvents.isEmpty ? "calendar" : "calendar.badge.clock")
                            .font(.title2)
                            .foregroundColor(BrandColor.primaryBlue)
                    }
                }
                .padding(BrandSpacing.lg)
                
                // 主内容区域
                if localEvents.isEmpty {
                    // 空状态：中间显示空状态图标
                    VStack {
                        Spacer()
                        VStack(spacing: BrandSpacing.md) {
                            Text("📅")
                                .font(.system(size: 48))
                            Text("这天还没有安排")
                                .font(BrandFont.body(size: 16, weight: .medium))
                                .foregroundColor(BrandColor.neutral500)
                        }
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
                                        showEventEdit = true
                                    }
                                )
                                .onTapGesture {
                                    eventToEdit = event
                                    showEventEdit = true
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
                        .background(BrandColor.neutral300)
                    
                    HStack(spacing: BrandSpacing.sm) {
                        TextField("快速添加事项...", text: $newEventTitle)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: BrandRadius.sm)
                                    .fill(BrandColor.neutral100)
                                    .neobrutalStyle(cornerRadius: BrandRadius.sm,
                                                   borderWidth: BrandBorder.regular)
                            )
                            .focused($isInputFocused)
                            .onSubmit {
                                createNewEvent()
                            }
                        
                        HStack(spacing: BrandSpacing.sm) {
                            // 快速添加按钮
                            Button(action: createNewEvent) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(BrandColor.primaryYellow)
                            }
                            .disabled(newEventTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            
                            // 详细编辑按钮
                            Button(action: {
                                eventToEdit = nil  // 创建新事项
                                showEventEdit = true
                            }) {
                                Image(systemName: "calendar.badge.plus")
                                    .font(.title2)
                                    .foregroundColor(BrandColor.primaryBlue)
                            }
                        }
                    }
                    .padding(.horizontal, BrandSpacing.lg)
                    .padding(.bottom, BrandSpacing.sm)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                Color.white
                    .ignoresSafeArea(.container, edges: .bottom)
            )
            .navigationTitle("日程安排")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // 视图出现时立即刷新数据
                refreshEvents()
            }
            .sheet(isPresented: $showEventEdit) {
                VStack(spacing: 0) {
                    // 自定义Sheet Header
                    NeobrutalismSheetHeader()
                    
                    if let event = eventToEdit {
                        EventEditView(
                            mode: .edit(event),
                            initialDate: selectedDate
                        )
                    } else {
                        EventEditView(
                            mode: .create,
                            initialDate: selectedDate
                        )
                    }
                }
                .presentationDragIndicator(.hidden)
            }
            .onChange(of: showEventEdit) { isPresented in
                // 当 sheet 关闭时刷新数据
                if !isPresented {
                    refreshEvents()
                }
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
    
    var body: some View {
        VStack(spacing: BrandSpacing.md) {
            HStack(spacing: BrandSpacing.md) {
                // 时间指示器
                VStack {
                    Circle()
                        .fill(eventColor)
                        .frame(width: 12, height: 12)
                    Rectangle()
                        .fill(eventColor.opacity(0.3))
                        .frame(width: 2, height: 40)
                }
                
                // 事项内容
                VStack(alignment: .leading, spacing: BrandSpacing.sm) {
                    // 标题和编辑按钮
                    HStack {
                        Text(event.title)
                            .font(BrandFont.body(size: 16, weight: .bold))
                            .foregroundColor(BrandColor.neutral900)
                        Spacer()
                        
                        // 编辑按钮（放大）
                        Button(action: onEdit) {
                            Image(systemName: "pencil.circle.fill")
                                .font(.title)
                                .foregroundColor(BrandColor.primaryBlue)
                        }
                    }
                    
                    // 时间信息
                    HStack(spacing: 8) {
                        Image(systemName: "clock")
                            .font(.caption)
                            .foregroundColor(eventColor)
                        Text(timeDisplayString)
                            .font(BrandFont.body(size: 14, weight: .medium))
                            .foregroundColor(event.startAt != nil ? BrandColor.neutral700 : BrandColor.neutral500)
                    }
                    
                    // 详情信息
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "text.alignleft")
                            .font(.caption)
                            .foregroundColor(eventColor)
                        Text(detailsDisplayString)
                            .font(BrandFont.body(size: 14, weight: .medium))
                            .foregroundColor(event.details != nil ? BrandColor.neutral700 : BrandColor.neutral500)
                            .multilineTextAlignment(.leading)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(BrandSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: BrandRadius.lg, style: .continuous)
                .fill(BrandColor.neutral100)
                .neobrutalStyle(cornerRadius: BrandRadius.lg,
                               borderWidth: BrandBorder.regular)
        )
    }
    
    private var timeDisplayString: String {
        if let startAt = event.startAt, let endAt = event.endAt {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return "\(formatter.string(from: startAt)) - \(formatter.string(from: endAt))"
        } else {
            return "未设置时间"
        }
    }
    
    private var detailsDisplayString: String {
        return event.details?.isEmpty == false ? event.details! : "暂无详情说明"
    }
    
    private var eventColor: Color {
        // 根据事项标题首字母分配颜色
        let firstChar = event.title.first?.lowercased() ?? "a"
        switch firstChar {
        case "工", "w", "m": // 工作/会议
            return BrandColor.secondaryRed  // 警示红
        case "生", "l": // 生活
            return BrandColor.primaryBlue   // 电光蓝
        case "运", "s": // 运动
            return BrandColor.secondaryGreen // 霓虹绿
        default:
            return BrandColor.primaryYellow  // 鲜艳黄
        }
    }
    

}

#Preview {
    MainCalendarAIView()
}
