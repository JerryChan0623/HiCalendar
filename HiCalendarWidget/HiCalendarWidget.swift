import WidgetKit
import SwiftUI
import Foundation

// MARK: - Widget Entry
struct HiCalendarEntry: TimelineEntry {
    let date: Date
    let todayEvents: [WidgetEvent]
    let tomorrowEvents: [WidgetEvent]
    let weekEvents: [WidgetEvent]
    let isPremiumUnlocked: Bool // 添加付费状态
}

// MARK: - Widget Event Model
struct WidgetEvent {
    let id: String
    let title: String
    let time: Date?
    let isAllDay: Bool
    let color: Color
    
    init(from event: Event) {
        self.id = UUID().uuidString // 为每个WidgetEvent创建独立的ID
        self.title = event.title
        self.time = event.startAt
        // 判断是否为全天事件：没有开始时间则为全天事件
        self.isAllDay = event.startAt == nil
        
        // 根据事件类型设置颜色
        if event.isRecurring {
            self.color = .blue
        } else if event.startAt == nil {
            self.color = .green
        } else {
            self.color = .orange
        }
    }
}

// MARK: - Timeline Provider
struct HiCalendarProvider: TimelineProvider {
    func placeholder(in context: Context) -> HiCalendarEntry {
        print("🎭 Widget显示placeholder")
        return HiCalendarEntry(
            date: Date(),
            todayEvents: getSampleEvents(),
            tomorrowEvents: getSampleEvents(),
            weekEvents: getSampleEvents(),
            isPremiumUnlocked: false // placeholder使用未付费状态
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (HiCalendarEntry) -> ()) {
        print("📸 Widget请求快照")
        let entry = createEntry(for: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        print("📅 Widget请求Timeline")
        let currentDate = Date()
        let entry = createEntry(for: currentDate)
        
        // 每15分钟刷新一次
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    private func createEntry(for date: Date) -> HiCalendarEntry {
        print("🔍 Widget创建Entry - \(date)")
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: date)
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? today
        let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)!

        // 检查付费状态
        let isPremiumUnlocked = checkPremiumStatus()

        // 如果未付费，返回锁定状态的Widget
        if !isPremiumUnlocked {
            print("💰 Widget功能未解锁，显示付费提示")
            return HiCalendarEntry(
                date: date,
                todayEvents: [],
                tomorrowEvents: [],
                weekEvents: [],
                isPremiumUnlocked: false
            )
        }

        let events = loadEventsFromUserDefaults()
        print("📊 Widget总共加载了 \(events.count) 个事件")
        print("📅 今天日期: \(today)")

        // 调试：打印所有事件的日期信息
        for (index, event) in events.enumerated() {
            print("📋 事件 \(index + 1): \(event.title)")
            print("  - startAt: \(event.startAt?.description ?? "nil")")
            print("  - intendedDate: \(event.intendedDate?.description ?? "nil")")
            print("  - createdAt: \(event.createdAt)")
        }

        let todayEvents = events.filter { event in
            let isToday: Bool
            if let startAt = event.startAt {
                isToday = calendar.isDate(startAt, inSameDayAs: today)
                print("  📅 检查startAt: \(startAt) vs today: \(today) = \(isToday)")
            } else if let intendedDate = event.intendedDate {
                isToday = calendar.isDate(intendedDate, inSameDayAs: today)
                print("  📅 检查intendedDate: \(intendedDate) vs today: \(today) = \(isToday)")
            } else {
                isToday = calendar.isDate(event.createdAt, inSameDayAs: today)
                print("  📅 检查createdAt: \(event.createdAt) vs today: \(today) = \(isToday)")
            }

            if isToday {
                print("✅ 事件 '\(event.title)' 被选为今天的事件")
            }

            return isToday
        }.map { WidgetEvent(from: $0) }
        
        let tomorrowEvents = events.filter { event in
            if let startAt = event.startAt {
                return calendar.isDate(startAt, inSameDayAs: tomorrow)
            } else if let intendedDate = event.intendedDate {
                return calendar.isDate(intendedDate, inSameDayAs: tomorrow)
            } else {
                return calendar.isDate(event.createdAt, inSameDayAs: tomorrow)
            }
        }.map { WidgetEvent(from: $0) }
        
        let weekEvents = events.filter { event in
            let eventDate: Date
            if let startAt = event.startAt {
                eventDate = startAt
            } else if let intendedDate = event.intendedDate {
                eventDate = intendedDate
            } else {
                eventDate = event.createdAt
            }
            return eventDate >= weekStart && eventDate < weekEnd
        }.map { WidgetEvent(from: $0) }
        
        let finalEntry = HiCalendarEntry(
            date: date,
            todayEvents: Array(todayEvents.prefix(5)), // 最多显示5个
            tomorrowEvents: Array(tomorrowEvents.prefix(5)),
            weekEvents: Array(weekEvents.prefix(10)),
            isPremiumUnlocked: true // 已付费用户看到正常内容
        )
        
        print("📱 Widget最终Entry - 今天:\(finalEntry.todayEvents.count), 明天:\(finalEntry.tomorrowEvents.count), 本周:\(finalEntry.weekEvents.count)")
        
        return finalEntry
    }

    /// 检查付费状态（Widget扩展中简化实现）
    private func checkPremiumStatus() -> Bool {
        print("💰 Widget开始检查付费状态...")

        // 从App Groups UserDefaults检查付费状态
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.chenzhencong.HiCalendar") else {
            print("❌ Widget无法访问App Groups: group.com.chenzhencong.HiCalendar")
            return false
        }

        // 检查是否有付费标记
        let isPremium = sharedDefaults.bool(forKey: "premium_unlocked")
        let timestamp = sharedDefaults.double(forKey: "premium_status_updated_at")
        let timestampDate = Date(timeIntervalSince1970: timestamp)

        print("💰 Widget付费状态检查结果: \(isPremium)")
        print("⏰ 状态更新时间: \(timestampDate)")

        // 调试：列出App Groups中的所有键值
        let allKeys = sharedDefaults.dictionaryRepresentation().keys
        print("🔍 App Groups中所有可用键: \(Array(allKeys))")

        return isPremium
    }

    private func loadEventsFromUserDefaults() -> [Event] {
        // 从App Groups UserDefaults加载事件
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.chenzhencong.HiCalendar") else {
            print("❌ Widget无法访问App Groups UserDefaults，使用示例数据")
            return getSampleEvents().map { Event(title: $0.title, startAt: $0.time, details: $0.title) }
        }
        
        guard let data = sharedDefaults.data(forKey: "shared_events") else {
            print("❌ Widget在App Groups中未找到shared_events数据，使用示例数据")
            return getSampleEvents().map { Event(title: $0.title, startAt: $0.time, details: $0.title) }
        }
        
        do {
            let events = try JSONDecoder().decode([Event].self, from: data)
            print("✅ Widget成功加载了 \(events.count) 个事件")
            
            // 调试信息：打印今天的事件
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let todayEvents = events.filter { event in
                if let startAt = event.startAt {
                    return calendar.isDate(startAt, inSameDayAs: today)
                } else if let intendedDate = event.intendedDate {
                    return calendar.isDate(intendedDate, inSameDayAs: today)
                } else {
                    return calendar.isDate(event.createdAt, inSameDayAs: today)
                }
            }
            print("📅 Widget发现今天有 \(todayEvents.count) 个事件")
            for event in todayEvents {
                print("  - \(event.title)")
            }
            
            return events
        } catch {
            print("❌ Widget解码事件数据失败: \(error)")
            return getSampleEvents().map {
                Event(
                    title: $0.title,
                    startAt: $0.time,
                    details: $0.title,
                    intendedDate: $0.time == nil ? Calendar.current.startOfDay(for: Date()) : nil
                )
            }
        }
    }
    
    private func getSampleEvents() -> [WidgetEvent] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return [
            WidgetEvent(from: Event(
                title: "团队会议",
                startAt: calendar.date(byAdding: .hour, value: 10, to: today) // 今天上午10点
            )),
            WidgetEvent(from: Event(
                title: "项目汇报",
                intendedDate: today // 明确设为今天的无时间事项
            ))
        ]
    }
}

// MARK: - Widget Views
struct HiCalendarWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: HiCalendarProvider.Entry

    var body: some View {
        if entry.isPremiumUnlocked {
            // 付费用户显示正常内容
            switch family {
            case .systemSmall:
                SmallWidgetView(entry: entry)
            case .systemMedium:
                MediumWidgetView(entry: entry)
            case .systemLarge:
                LargeWidgetView(entry: entry)
            default:
                SmallWidgetView(entry: entry)
            }
        } else {
            // 未付费用户显示锁定界面
            switch family {
            case .systemSmall:
                LockedSmallWidgetView()
            case .systemMedium:
                LockedMediumWidgetView()
            case .systemLarge:
                LockedLargeWidgetView()
            default:
                LockedSmallWidgetView()
            }
        }
    }
}

// MARK: - Small Widget (今天任务)
struct SmallWidgetView: View {
    let entry: HiCalendarEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // 标题
            HStack {
                // 使用条件渲染：尝试加载applogo，失败则显示系统图标
                if let logoImage = UIImage(named: "applogo") {
                    Image(uiImage: logoImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                } else {
                    // 如果applogo加载失败，使用品牌色系的系统图标
                    Image(systemName: "calendar.circle.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.orange)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(.orange.opacity(0.1))
                                .frame(width: 20, height: 20)
                        )
                }
                Text("今日安排")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
                Spacer()
                Text("\(entry.todayEvents.count)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // 事件列表
            if entry.todayEvents.isEmpty {
                Text("今天没有安排")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                Spacer()
            } else {
                ForEach(entry.todayEvents.prefix(3), id: \.id) { event in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(event.color)
                            .frame(width: 8, height: 8)
                        
                        VStack(alignment: .leading, spacing: 1) {
                            Text(event.title)
                                .font(.system(size: 11, weight: .medium))
                                .lineLimit(1)
                            
                            if let time = event.time, !shouldShowAsAllDay(time: time, isAllDay: event.isAllDay) {
                                Text(time.formatted(.dateTime.hour().minute()))
                                    .font(.system(size: 9))
                                    .foregroundColor(.secondary)
                            } else {
                                Text("全天")
                                    .font(.system(size: 9))
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer(minLength: 0)
                    }
                }
                
                if entry.todayEvents.count > 3 {
                    Text("还有 \(entry.todayEvents.count - 3) 个安排...")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
        .padding(0)
    }
}

// MARK: - Medium Widget (今天+明天)
struct MediumWidgetView: View {
    let entry: HiCalendarEntry
    
    var body: some View {
        HStack(spacing: 16) {
            // 今天
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    if let logoImage = UIImage(named: "applogo") {
                        Image(uiImage: logoImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 18, height: 18)
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                    } else {
                        Image(systemName: "calendar.circle.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.orange)
                            .background(
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(.orange.opacity(0.1))
                                    .frame(width: 18, height: 18)
                            )
                    }
                    Text("今天")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.primary)
                    Spacer()
                    Text("\(entry.todayEvents.count)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                if entry.todayEvents.isEmpty {
                    Text("无安排")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Spacer()
                } else {
                    ForEach(entry.todayEvents.prefix(3), id: \.id) { event in
                        EventRowView(event: event)
                    }
                    Spacer()
                }
            }
            
            // 分隔线
            Rectangle()
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 1)
            
            // 明天
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("明天")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.primary)
                    Spacer()
                    Text("\(entry.tomorrowEvents.count)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                if entry.tomorrowEvents.isEmpty {
                    Text("无安排")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Spacer()
                } else {
                    ForEach(entry.tomorrowEvents.prefix(3), id: \.id) { event in
                        EventRowView(event: event)
                    }
                    Spacer()
                }
            }
        }
        .padding(0)
    }
}

// MARK: - Large Widget (本周概览)
struct LargeWidgetView: View {
    let entry: HiCalendarEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 标题
            HStack {
                if let logoImage = UIImage(named: "applogo") {
                    Image(uiImage: logoImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 22, height: 22)
                        .clipShape(RoundedRectangle(cornerRadius: 7))
                } else {
                    Image(systemName: "calendar.circle.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.orange)
                        .background(
                            RoundedRectangle(cornerRadius: 7)
                                .fill(.orange.opacity(0.1))
                                .frame(width: 22, height: 22)
                        )
                }
                Text("本周安排")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("共 \(entry.weekEvents.count) 个安排")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // 今天和明天的快速预览
            HStack(spacing: 12) {
                QuickDayView(title: "今天", events: entry.todayEvents)
                    .frame(maxWidth: .infinity, alignment: .leading)
                QuickDayView(title: "明天", events: entry.tomorrowEvents)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            Divider()
            
            // 本周所有事件
            Text("本周全部安排")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)
            
            if entry.weekEvents.isEmpty {
                Text("本周暂无安排")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                Spacer()
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(entry.weekEvents.prefix(6), id: \.id) { event in
                        EventRowView(event: event, showDate: true)
                    }
                    if entry.weekEvents.count > 6 {
                        Text("还有 \(entry.weekEvents.count - 6) 个安排...")
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
            }
        }
        .padding(0)
    }
}

// MARK: - Helper Views
struct EventRowView: View {
    let event: WidgetEvent
    let showDate: Bool
    
    init(event: WidgetEvent, showDate: Bool = false) {
        self.event = event
        self.showDate = showDate
    }
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(event.color)
                .frame(width: 6, height: 6)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(event.title)
                    .font(.system(size: 10, weight: .medium))
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    if let time = event.time, !shouldShowAsAllDay(time: time, isAllDay: event.isAllDay) {
                        if showDate {
                            Text(time.formatted(.dateTime.month(.abbreviated).day()))
                                .font(.system(size: 8))
                                .foregroundColor(.secondary)
                        }
                        Text(time.formatted(.dateTime.hour().minute()))
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)
                    } else {
                        Text("全天")
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer(minLength: 0)
        }
    }
}

struct QuickDayView: View {
    let title: String
    let events: [WidgetEvent]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
            
            if events.isEmpty {
                Text("无安排")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            } else {
                ForEach(events.prefix(2), id: \.id) { event in
                    EventRowView(event: event)
                }
                if events.count > 2 {
                    Text("还有 \(events.count - 2) 个...")
                        .font(.system(size: 8))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(0)
    }
}

// MARK: - Widget Definition
struct HiCalendarWidget: Widget {
    let kind: String = "HiCalendarWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HiCalendarProvider()) { entry in
            if #available(iOS 17.0, *) {
                HiCalendarWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                HiCalendarWidgetEntryView(entry: entry)
            }
        }
        .configurationDisplayName("HiCalendar 任务预览")
        .description("查看今天、明天和本周的任务安排")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Widget Extension Models (与主App完全一致的Event模型)
struct Event: Codable, Identifiable {
    let id: UUID
    var title: String
    var startAt: Date?    // 时间：默认为空
    var endAt: Date?      // 时间：默认为空
    var details: String?  // 详情：默认为空
    let createdAt: Date
    var intendedDate: Date?  // 归属日期：用于无时间事项的日期归属
    
    // 推送通知设置 - 支持多个提醒时间
    var pushReminders: [PushReminderOption] // 推送提醒选项数组
    
    // 重复事件组ID（同一重复规则创建的事件共享此ID）
    var recurrenceGroupId: UUID? // 重复组ID，nil表示非重复事件
    var originalRecurrenceType: RecurrenceType? // 原始重复类型（用于显示和修改检测）
    
    // 周期性重复设置（已弃用，保留兼容性）
    var recurrenceType: RecurrenceType { // 保持向后兼容
        get { originalRecurrenceType ?? .none }
        set { originalRecurrenceType = newValue != .none ? newValue : nil }
    }
    var recurrenceCount: Int? // 重复次数（nil表示无限重复）
    var recurrenceEndDate: Date? // 重复结束日期
    
    // 兼容性字段（保持向后兼容）
    var pushDayBefore: Bool {
        get { pushReminders.contains(.dayBefore) }
        set { 
            if newValue && !pushReminders.contains(.dayBefore) {
                pushReminders.append(.dayBefore)
            } else if !newValue {
                pushReminders.removeAll { $0 == .dayBefore }
            }
        }
    }
    
    var pushWeekBefore: Bool {
        get { pushReminders.contains(.weekBefore) }
        set { 
            if newValue && !pushReminders.contains(.weekBefore) {
                pushReminders.append(.weekBefore)
            } else if !newValue {
                pushReminders.removeAll { $0 == .weekBefore }
            }
        }
    }
    
    // Supabase同步字段
    var isSynced: Bool = false
    
    var isRecurring: Bool {
        return recurrenceGroupId != nil
    }
    
    init(title: String, startAt: Date? = nil, endAt: Date? = nil, details: String? = nil, 
         pushReminders: [PushReminderOption] = [.dayBefore], createdAt: Date = Date(), 
         intendedDate: Date? = nil, recurrenceGroupId: UUID? = nil, originalRecurrenceType: RecurrenceType? = nil,
         recurrenceCount: Int? = nil, recurrenceEndDate: Date? = nil) {
        self.id = UUID()
        self.title = title
        self.startAt = startAt
        self.endAt = endAt
        self.details = details
        self.pushReminders = pushReminders
        self.createdAt = createdAt
        self.intendedDate = intendedDate
        self.recurrenceGroupId = recurrenceGroupId
        self.originalRecurrenceType = originalRecurrenceType
        self.recurrenceCount = recurrenceCount
        self.recurrenceEndDate = recurrenceEndDate
    }
}

enum PushReminderOption: String, CaseIterable, Codable {
    case none = "none"
    case atTime = "at_time"
    case minutes15 = "15_minutes"
    case minutes30 = "30_minutes"
    case hours1 = "1_hour"
    case hours2 = "2_hours"
    case dayBefore = "1_day"
    case weekBefore = "1_week"
}

enum RecurrenceType: String, CaseIterable, Codable {
    case none = "none"
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    case yearly = "yearly"
}

// MARK: - Helper Functions
private func shouldShowAsAllDay(time: Date?, isAllDay: Bool) -> Bool {
    // 如果标记为全天事件，则显示为全天
    if isAllDay {
        return true
    }
    
    // 如果时间为空，则显示为全天
    guard let time = time else {
        return true
    }
    
    // 如果时间是00:00，也显示为全天（隐藏12:00AM）
    let calendar = Calendar.current
    let hour = calendar.component(.hour, from: time)
    let minute = calendar.component(.minute, from: time)
    return hour == 0 && minute == 0
}

// MARK: - Locked Widget Views (未付费状态)
struct LockedSmallWidgetView: View {
    var body: some View {
        VStack(spacing: 8) {
            // 锁定图标
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color.yellow.opacity(0.8), Color.blue.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 40, height: 40)

                Image(systemName: "lock.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
            }

            Text("升级解锁")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.primary)

            Text("点击升级到Pro\n查看日历内容")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
        .widgetURL(URL(string: "hicalendar://premium")!) // 深链接到付费页面
    }
}

struct LockedMediumWidgetView: View {
    var body: some View {
        HStack(spacing: 16) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [Color.yellow.opacity(0.8), Color.blue.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 50, height: 50)

                    Image(systemName: "lock.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                }

                Text("Widget已锁定")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("升级到 HiCalendar Pro")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)

                Text("• 桌面小组件\n• 云端同步备份\n• 多设备数据同步")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineSpacing(2)

                Text("点击立即升级 →")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.blue)
                    .padding(.top, 4)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
        .widgetURL(URL(string: "hicalendar://premium")!)
    }
}

struct LockedLargeWidgetView: View {
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [Color.yellow.opacity(0.8), Color.blue.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 60, height: 60)

                    Image(systemName: "lock.fill")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Widget功能已锁定")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)

                    Text("升级到Pro版本解锁完整功能")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Pro版本功能：")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)

                VStack(alignment: .leading, spacing: 6) {
                    FeatureRow(icon: "widget.small", text: "桌面小组件 - 主屏幕直接查看今日事项")
                    FeatureRow(icon: "icloud", text: "云端同步 - 多设备数据同步，永不丢失")
                    FeatureRow(icon: "bell", text: "智能提醒 - 贴心（嘴贱）推送通知")
                    FeatureRow(icon: "calendar", text: "无限事项 - 创建任意数量的日历事项")
                }
            }

            Spacer()

            Text("点击升级到 HiCalendar Pro")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.blue)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue.opacity(0.1))
                )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
        .widgetURL(URL(string: "hicalendar://premium")!)
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.blue)
                .frame(width: 16)

            Text(text)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
                .lineLimit(1)

            Spacer()
        }
    }
}

#Preview(as: .systemSmall) {
    HiCalendarWidget()
} timeline: {
    HiCalendarEntry(
        date: Date(),
        todayEvents: [
            WidgetEvent(from: Event(title: "团队会议", startAt: Date())),
            WidgetEvent(from: Event(title: "项目汇报"))
        ],
        tomorrowEvents: [],
        weekEvents: [],
        isPremiumUnlocked: true
    )

    // 未付费状态预览
    HiCalendarEntry(
        date: Date(),
        todayEvents: [],
        tomorrowEvents: [],
        weekEvents: [],
        isPremiumUnlocked: false
    )
}
