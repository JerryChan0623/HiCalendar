//
//  Models.swift
//  HiCalendar
//
//  Created on 2024. Cute Calendar AI 数据模型
//

import Foundation

// MARK: - User Model
struct User: Codable, Identifiable {
    let id: UUID
    let email: String
    var timezone: String
    var defaultPushDayBefore: Bool
    var defaultPushWeekBefore: Bool
    let createdAt: Date

    // 会员相关字段
    var isMember: Bool
    var membershipExpiresAt: Date?

    init(id: UUID = UUID(), email: String, timezone: String = "Asia/Shanghai", isMember: Bool = false, membershipExpiresAt: Date? = nil) {
        self.id = id
        self.email = email
        self.timezone = timezone
        self.defaultPushDayBefore = true
        self.defaultPushWeekBefore = false
        self.createdAt = Date()
        self.isMember = isMember
        self.membershipExpiresAt = membershipExpiresAt
    }
}

// MARK: - Device Model
struct UserDevice: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let deviceToken: String
    let platform: String // "ios"
    let createdAt: Date
    
    init(id: UUID = UUID(), userId: UUID, deviceToken: String) {
        self.id = id
        self.userId = userId
        self.deviceToken = deviceToken
        self.platform = "ios"
        self.createdAt = Date()
    }
}


// MARK: - Recurrence Options
enum RecurrenceType: String, CaseIterable, Codable {
    case none = "none"           // 不重复
    case daily = "daily"         // 每日
    case weekly = "weekly"       // 每周
    case monthly = "monthly"     // 每月
    case yearly = "yearly"       // 每年
    
    var displayName: String {
        switch self {
        case .none: return "不重复"
        case .daily: return "每天"
        case .weekly: return "每周"
        case .monthly: return "每月"
        case .yearly: return "每年"
        }
    }
    
    var emoji: String {
        switch self {
        case .none: return "⚪"
        case .daily: return "📅"
        case .weekly: return "🗓️"
        case .monthly: return "📆"
        case .yearly: return "🎂"
        }
    }
}

// MARK: - Push Reminder Options
enum PushReminderOption: String, CaseIterable, Codable {
    case none = "none"
    case atTime = "at_time"           // 准点提醒
    case minutes15 = "15_minutes"     // 15分钟前
    case minutes30 = "30_minutes"     // 30分钟前
    case hours1 = "1_hour"            // 1小时前
    case hours2 = "2_hours"           // 2小时前
    case dayBefore = "1_day"          // 1天前
    case weekBefore = "1_week"        // 1周前
    
    var displayName: String {
        switch self {
        case .none: return "不提醒"
        case .atTime: return "准点提醒"
        case .minutes15: return "15分钟前"
        case .minutes30: return "30分钟前"
        case .hours1: return "1小时前"
        case .hours2: return "2小时前"
        case .dayBefore: return "1天前"
        case .weekBefore: return "1周前"
        }
    }
    
    var emoji: String {
        switch self {
        case .none: return "🔕"
        case .atTime: return "⏰"
        case .minutes15: return "⏱️"
        case .minutes30: return "⏲️"
        case .hours1: return "🕐"
        case .hours2: return "🕑"
        case .dayBefore: return "📅"
        case .weekBefore: return "🗓️"
        }
    }
    
    // 获取提醒时间偏移（秒）
    var timeOffsetSeconds: TimeInterval {
        switch self {
        case .none: return 0
        case .atTime: return 0
        case .minutes15: return -15 * 60
        case .minutes30: return -30 * 60
        case .hours1: return -1 * 60 * 60
        case .hours2: return -2 * 60 * 60
        case .dayBefore: return -24 * 60 * 60
        case .weekBefore: return -7 * 24 * 60 * 60
        }
    }
}

// MARK: - Event Model
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
    var recurrenceCount: Int? // 重复次数（默认7次）
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
    
    var pushStatus: PushStatus  // 推送状态跟踪
    var isSynced: Bool          // 是否已同步到Supabase（默认false，创建时为未同步）
    var isOnboarding: Bool      // 是否为onboarding示例事项（不同步到云端）

    // 系统日历同步相关字段
    var systemCalendarEventID: String?  // 对应的系统日历事件ID
    var systemCalendarID: String?       // 系统日历ID
    var isFromSystemCalendar: Bool      // 是否来自系统日历导入
    
    init(id: UUID = UUID(), title: String, startAt: Date? = nil, endAt: Date? = nil, details: String? = nil,
         pushReminders: [PushReminderOption] = [.dayBefore], createdAt: Date = Date(), intendedDate: Date? = nil,
         recurrenceGroupId: UUID? = nil, originalRecurrenceType: RecurrenceType? = nil,
         recurrenceCount: Int? = nil, recurrenceEndDate: Date? = nil, isSynced: Bool = false, isOnboarding: Bool = false,
         systemCalendarEventID: String? = nil, systemCalendarID: String? = nil, isFromSystemCalendar: Bool = false) {
        self.id = id
        self.title = title
        self.startAt = startAt
        self.endAt = endAt
        self.details = details
        self.createdAt = createdAt
        self.intendedDate = intendedDate
        self.pushReminders = pushReminders
        self.recurrenceGroupId = recurrenceGroupId
        self.originalRecurrenceType = originalRecurrenceType
        self.recurrenceCount = recurrenceCount
        self.recurrenceEndDate = recurrenceEndDate
        self.pushStatus = PushStatus()
        self.isSynced = isSynced
        self.isOnboarding = isOnboarding
        self.systemCalendarEventID = systemCalendarEventID
        self.systemCalendarID = systemCalendarID
        self.isFromSystemCalendar = isFromSystemCalendar
    }
    
    // 旧版本兼容初始化方法
    init(id: UUID = UUID(), title: String, startAt: Date? = nil, endAt: Date? = nil, details: String? = nil,
         pushDayBefore: Bool = true, pushWeekBefore: Bool = false, intendedDate: Date? = nil, isOnboarding: Bool = false) {
        var reminders: [PushReminderOption] = []
        if pushDayBefore { reminders.append(.dayBefore) }
        if pushWeekBefore { reminders.append(.weekBefore) }

        self.init(id: id, title: title, startAt: startAt, endAt: endAt, details: details,
                 pushReminders: reminders, intendedDate: intendedDate, isSynced: false, isOnboarding: isOnboarding)
    }
}

// MARK: - Push Status Model
struct PushStatus: Codable {
    var dayBeforeSent: Bool = false     // 1天前推送是否已发送
    var weekBeforeSent: Bool = false    // 1周前推送是否已发送
    var lastNotificationId: String?    // 最后一次推送的ID（用于调试）
    
    enum CodingKeys: String, CodingKey {
        case dayBeforeSent = "day_before_sent"
        case weekBeforeSent = "week_before_sent"
        case lastNotificationId = "last_notification_id"
    }
}



// MARK: - Calendar View Models
enum CalendarViewType: String, CaseIterable {
    case month = "month"
    case week = "week"
    case day = "day"
    
    var displayName: String {
        switch self {
        case .month: return "月"
        case .week: return "周"
        case .day: return "日"
        }
    }
}

struct CalendarDay {
    let date: Date
    let events: [Event]
    let isToday: Bool
    let isCurrentMonth: Bool
    
    var hasMultipleEvents: Bool {
        return events.count > 1
    }
}

// MARK: - AI Response Model
struct AIResponse {
    let conclusion: String      // AI 分析结论
    let sarcasm: String        // 嘴贱吐槽
    let suggestion: String?    // 操作建议
    let actionType: AIActionType
    let extractedEvent: Event? // 提取的事件信息
    let message: String?       // 完整回复消息
    var userInfo: [String: Any]? // 额外信息存储
    
    enum AIActionType: String, CaseIterable {
        case createEvent = "create"
        case queryEvents = "query" 
        case modifyEvent = "modify"
        case deleteEvent = "delete"
        case checkConflict = "conflict"
        case unknown = "unknown"
    }
    
    init(conclusion: String, sarcasm: String, suggestion: String? = nil, 
         actionType: AIActionType, extractedEvent: Event? = nil, message: String? = nil) {
        self.conclusion = conclusion
        self.sarcasm = sarcasm  
        self.suggestion = suggestion
        self.actionType = actionType
        self.extractedEvent = extractedEvent
        self.message = message
        self.userInfo = nil
    }
}

// MARK: - Extensions
extension Event {
    var duration: TimeInterval? {
        guard let startAt = startAt, let endAt = endAt else { return nil }
        return endAt.timeIntervalSince(startAt)
    }
    
    var durationString: String {
        guard let duration = duration else { return "未设置时间" }
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? ""
    }
    
    var timeRangeString: String {
        guard let startAt = startAt, let endAt = endAt else { return "未设置时间" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: startAt)) - \(formatter.string(from: endAt))"
    }
    
    // MARK: - Recurrence Event Helpers
    
    /// 是否为重复事件
    var isRecurrenceEvent: Bool {
        return recurrenceGroupId != nil
    }
    
    /// 获取显示标题
    var displayTitle: String {
        return title
    }
    
    /// 是否与其他事件属于同一重复组
    func isSameRecurrenceGroup(as otherEvent: Event) -> Bool {
        guard let groupId = self.recurrenceGroupId,
              let otherGroupId = otherEvent.recurrenceGroupId else {
            return false
        }
        return groupId == otherGroupId
    }
    
    /// 生成重复事件组 - 简化版本
    static func generateRecurrenceGroup(
        title: String,
        baseDate: Date,
        startAt: Date? = nil,
        endAt: Date? = nil,
        details: String? = nil,
        pushReminders: [PushReminderOption] = [.dayBefore],
        recurrenceType: RecurrenceType,
        recurrenceCount: Int? = 7,
        recurrenceEndDate: Date? = nil
    ) -> [Event] {
        guard recurrenceType != .none else {
            // 非重复事件，直接返回单个事件
            return [Event(
                title: title,
                startAt: startAt,
                endAt: endAt,
                details: details,
                pushReminders: pushReminders,
                intendedDate: startAt == nil ? baseDate : nil
            )]
        }
        
        let groupId = UUID() // 为这组重复事件生成唯一组ID
        var events: [Event] = []
        let calendar = Calendar.current
        
        // 决定生成多少事件
        let maxEvents: Int
        if let endDate = recurrenceEndDate {
            // 如果设置了结束日期，计算最多需要生成多少个事件
            let components = calendar.dateComponents([.day], from: baseDate, to: endDate)
            let days = max(0, components.day ?? 0)
            
            // 根据重复类型计算事件数量
            switch recurrenceType {
            case .daily:
                maxEvents = days + 1  // 包括开始和结束日期
            case .weekly:
                maxEvents = (days / 7) + 2  // 多生成一些以确保覆盖结束日期
            case .monthly:
                maxEvents = (days / 30) + 2
            case .yearly:
                maxEvents = (days / 365) + 2
            case .none:
                maxEvents = 0
            }
        } else {
            // 没有结束日期，使用重复次数或默认值（一周）
            maxEvents = recurrenceCount ?? 7
        }
        
        // 生成事件
        for i in 0..<maxEvents {
            // 计算每个事件的日期
            var eventDate = baseDate
            
            switch recurrenceType {
            case .daily:
                eventDate = calendar.date(byAdding: .day, value: i, to: baseDate) ?? baseDate
            case .weekly:
                eventDate = calendar.date(byAdding: .weekOfYear, value: i, to: baseDate) ?? baseDate
            case .monthly:
                eventDate = calendar.date(byAdding: .month, value: i, to: baseDate) ?? baseDate
            case .yearly:
                eventDate = calendar.date(byAdding: .year, value: i, to: baseDate) ?? baseDate
            case .none:
                continue
            }
            
            // 如果设置了结束日期，超过就停止
            if let endDate = recurrenceEndDate {
                let eventDay = calendar.startOfDay(for: eventDate)
                let endDay = calendar.startOfDay(for: endDate)
                if eventDay > endDay {
                    break
                }
            }
            
            // 创建事件
            let event: Event
            
            if let originalStartAt = startAt {
                // 有时间的事件：调整时间到新日期
                let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: originalStartAt)
                let newStartAt = calendar.date(bySettingHour: timeComponents.hour ?? 0,
                                              minute: timeComponents.minute ?? 0,
                                              second: 0,
                                              of: eventDate)
                
                var newEndAt: Date? = nil
                if let originalEndAt = endAt, let validStartAt = newStartAt {
                    let duration = originalEndAt.timeIntervalSince(originalStartAt)
                    newEndAt = validStartAt.addingTimeInterval(duration)
                }
                
                event = Event(
                    title: title,
                    startAt: newStartAt,
                    endAt: newEndAt,
                    details: details,
                    pushReminders: pushReminders,
                    intendedDate: nil,
                    recurrenceGroupId: groupId,
                    originalRecurrenceType: recurrenceType,
                    recurrenceCount: recurrenceCount,
                    recurrenceEndDate: recurrenceEndDate
                )
            } else {
                // 无时间的事件：使用intendedDate
                event = Event(
                    title: title,
                    startAt: nil,
                    endAt: nil,
                    details: details,
                    pushReminders: pushReminders,
                    intendedDate: eventDate,
                    recurrenceGroupId: groupId,
                    originalRecurrenceType: recurrenceType,
                    recurrenceCount: recurrenceCount,
                    recurrenceEndDate: recurrenceEndDate
                )
            }
            
            events.append(event)
        }
        
        print("🔄 生成重复事件组: \(recurrenceType.displayName), 共\(events.count)个事件")
        return events
    }
}

extension Date {
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
    
    var isThisWeek: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .weekOfYear)
    }
    
    var dayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: self)
    }
}

// MARK: - Sample Data (引导数据)
extension Event {
    // MARK: - Onboarding Sample Events (引导用户掌握核心功能)
    static let sampleEvents: [Event] = [
        // === 今天的核心引导事项 ===
        
        // 1. AI交互引导 - 最重要的功能
        Event(
            title: "长按AI按钮录音，短按文字对话 🎤",
            startAt: Calendar.current.date(byAdding: .hour, value: 10, to: Calendar.current.startOfDay(for: Date())),
            endAt: Calendar.current.date(byAdding: .hour, value: 10, to: Calendar.current.startOfDay(for: Date()))?.addingTimeInterval(15*60),
            details: "这是HiCalendar的核心功能！长按底部AI按钮0.5秒开始录音，松开后AI会智能创建事项。也可以单击进行文字对话。试着说：'明天上午9点开会'",
            pushDayBefore: false,
            pushWeekBefore: false,
            isOnboarding: true
        ),
        
        // 2. 真实使用习惯建立
        Event(
            title: "创建你的第一个真实事项 🌟",
            startAt: nil,
            endAt: nil,
            details: "现在试着创建一个真实的事项吧！可以用AI语音快速创建，也可以点击+号手动添加。建立使用HiCalendar管理日程的好习惯！",
            pushDayBefore: false,
            pushWeekBefore: false,
            intendedDate: Date(), // 设置为今天，确保Widget能正确显示
            isOnboarding: true
        ),
        
        // 3. 个性化设置引导
        Event(
            title: "去设置页面换个好看背景 🎨",
            startAt: Calendar.current.date(byAdding: .hour, value: 14, to: Calendar.current.startOfDay(for: Date())),
            endAt: nil,
            details: "点击右上角设置按钮，可以上传自定义背景图片，让你的日历独一无二！还可以在设置中调整其他偏好。",
            pushDayBefore: false,
            pushWeekBefore: false,
            isOnboarding: true
        ),
        
        // 4. 推送设置引导
        Event(
            title: "调整推送偏好让提醒更合适 🔔",
            startAt: nil,
            endAt: nil,
            details: "在设置页面可以调整默认推送偏好，选择最适合你的提醒时间。记得开启通知权限，不然收不到我们有趣的推送文案哦～",
            pushDayBefore: false,
            pushWeekBefore: false,
            intendedDate: Date(), // 设置为今天，确保Widget能正确显示
            isOnboarding: true
        ),
        
        // === 后天的推送演示事项 (明天收到推送) ===
        
        // 5. 推送功能演示事项
        Event(
            title: "明天会收到我的推送提醒 📬",
            startAt: Calendar.current.date(byAdding: .day, value: 2, to: Calendar.current.startOfDay(for: Date()))?.addingTimeInterval(10*60*60), // 后天上午10点
            endAt: Calendar.current.date(byAdding: .day, value: 2, to: Calendar.current.startOfDay(for: Date()))?.addingTimeInterval(11*60*60),
            details: "这是演示推送功能的事项！明天你会收到提醒推送，体验HiCalendar的智能提醒系统。我们的推送文案很有趣，点击通知还能快速回到应用！",
            pushDayBefore: true,
            pushWeekBefore: false,
            isOnboarding: true
        ),
        
        // 6. 无时间事项推送演示
        Event(
            title: "推送文案很有趣，点击体验 😄",
            startAt: nil,
            endAt: nil,
            details: "无时间事项也能推送提醒！明天你会收到这个待办的推送通知，体验我们独特的吐槽风格文案。记得点击通知回到应用查看～",
            pushDayBefore: true,
            pushWeekBefore: false,
            intendedDate: Calendar.current.date(byAdding: .day, value: 2, to: Calendar.current.startOfDay(for: Date())), // 后天归属
            isOnboarding: true
        )
    ]
}

// MARK: - Sample Data (开发用)
#if DEBUG
extension User {
    static let sampleUser = User(
        email: "test@example.com",
        timezone: "Asia/Shanghai"
    )
}
#endif
