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
    var sarcasmLevel: Int // 0-3 (温和到重嘴贱)
    var defaultPushDayBefore: Bool
    var defaultPushWeekBefore: Bool
    let createdAt: Date
    
    init(id: UUID = UUID(), email: String, timezone: String = "Asia/Shanghai", sarcasmLevel: Int = 1) {
        self.id = id
        self.email = email
        self.timezone = timezone
        self.sarcasmLevel = sarcasmLevel
        self.defaultPushDayBefore = true
        self.defaultPushWeekBefore = false
        self.createdAt = Date()
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

// MARK: - Event Model
struct Event: Codable, Identifiable {
    let id: UUID
    var title: String
    var startAt: Date?    // 时间：默认为空
    var endAt: Date?      // 时间：默认为空
    var details: String?  // 详情：默认为空
    let createdAt: Date
    
    init(id: UUID = UUID(), title: String, startAt: Date? = nil, endAt: Date? = nil, details: String? = nil) {
        self.id = id
        self.title = title
        self.startAt = startAt
        self.endAt = endAt
        self.details = details
        self.createdAt = Date()
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
struct AIResponse: Codable {
    let conclusion: String      // AI 分析结论
    let sarcasm: String        // 嘴贱吐槽
    let suggestion: String?    // 操作建议
    let actionType: AIActionType
    let extractedEvent: Event? // 提取的事件信息
    
    enum AIActionType: String, Codable {
        case createEvent = "create"
        case queryEvents = "query"
        case modifyEvent = "modify"
        case deleteEvent = "delete"
        case checkConflict = "conflict"
        case unknown = "unknown"
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

// MARK: - Sample Data (开发用)
#if DEBUG
extension Event {
    static let sampleEvents: [Event] = [
        Event(
            title: "晨会 ☀️",
            startAt: Calendar.current.date(byAdding: .hour, value: 9, to: Calendar.current.startOfDay(for: Date())),
            endAt: Calendar.current.date(byAdding: .hour, value: 10, to: Calendar.current.startOfDay(for: Date())),
            details: "日常团队晨会，讨论今日工作安排"
        ),
        Event(
            title: "产品评审 📋",
            startAt: Calendar.current.date(byAdding: .hour, value: 14, to: Calendar.current.startOfDay(for: Date())),
            endAt: Calendar.current.date(byAdding: .hour, value: 16, to: Calendar.current.startOfDay(for: Date())),
            details: "新版本产品功能评审，地点：Zoom"
        ),
        Event(
            title: "摸鱼时间 🐟",
            startAt: Calendar.current.date(byAdding: .hour, value: 16, to: Calendar.current.startOfDay(for: Date())),
            endAt: Calendar.current.date(byAdding: .hour, value: 17, to: Calendar.current.startOfDay(for: Date())),
            details: "放松一下，聊聊天看看新闻"
        ),
        // 明天的事项
        Event(
            title: "客户拜访 🤝",
            startAt: Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date()))?.addingTimeInterval(10*3600),
            endAt: Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date()))?.addingTimeInterval(12*3600),
            details: "重要客户会面，地点：客户办公室"
        ),
        // 后天的事项
        Event(
            title: "团队建设 🎯",
            startAt: Calendar.current.date(byAdding: .day, value: 2, to: Calendar.current.startOfDay(for: Date()))?.addingTimeInterval(14*3600),
            endAt: Calendar.current.date(byAdding: .day, value: 2, to: Calendar.current.startOfDay(for: Date()))?.addingTimeInterval(18*3600),
            details: "团队户外活动，地点：户外基地"
        ),
        // 昨天的事项
        Event(
            title: "工作总结 📊",
            startAt: Calendar.current.date(byAdding: .day, value: -1, to: Calendar.current.startOfDay(for: Date()))?.addingTimeInterval(15*3600),
            endAt: Calendar.current.date(byAdding: .day, value: -1, to: Calendar.current.startOfDay(for: Date()))?.addingTimeInterval(17*3600),
            details: "回顾本周工作内容和进展"
        )
    ]
}

extension User {
    static let sampleUser = User(
        email: "test@example.com",
        timezone: "Asia/Shanghai",
        sarcasmLevel: 2
    )
}
#endif
