//
//  EventStorageManager.swift
//  HiCalendar
//
//  Local storage manager for events using UserDefaults
//

import Foundation
import Supabase
import UserNotifications

class EventStorageManager: ObservableObject {
    static let shared = EventStorageManager()
    
    private let userDefaults = UserDefaults.standard
    private let eventsKey = "SavedEvents"
    private let supabase = SupabaseManager.shared.client
    
    @Published var events: [Event] = []
    
    private init() {
        loadEvents()
    }
    
    // MARK: - Public Methods
    
    /// 加载所有事项
    func loadEvents() {
        if let data = userDefaults.data(forKey: eventsKey),
           let decodedEvents = try? JSONDecoder().decode([Event].self, from: data) {
            self.events = decodedEvents
        } else {
            // 如果没有本地数据，使用示例数据（标记为已同步，避免上传到云端）
            var samples = Event.sampleEvents
            for i in samples.indices { samples[i].isSynced = true }
            self.events = samples
            saveEvents()
        }
    }
    
    /// 保存所有事项
    private func saveEvents() {
        if let data = try? JSONEncoder().encode(events) {
            userDefaults.set(data, forKey: eventsKey)
        }
    }
    
    /// 添加新事项（支持单个或批量）
    func addEvent(_ event: Event) {
        addEvents([event])
    }
    
    /// 批量添加事项
    func addEvents(_ newEvents: [Event]) {
        events.append(contentsOf: newEvents)
        saveEvents()
        
        print("📝 添加了\(newEvents.count)个事项")
        
        // 为每个事件调度本地通知和同步
        for event in newEvents {
            scheduleLocalNotifications(for: event)
            Task {
                await syncEventToSupabase(event)
            }
        }
    }
    
    /// 添加重复事件 - 保留此方法以兼容旧代码
    func addRecurringEvents(_ baseEvent: Event) {
        // 直接调用addEvent，因为重复事件生成已经在调用方完成
        addEvent(baseEvent)
    }
    
    /// 删除事项
    func deleteEvent(_ event: Event) {
        // 取消本地通知
        cancelLocalNotifications(for: event)
        
        events.removeAll { $0.id == event.id }
        saveEvents()
    }
    
    /// 删除重复事件组
    func deleteRecurrenceGroup(_ event: Event) {
        guard let groupId = event.recurrenceGroupId else {
            deleteEvent(event)
            return
        }
        
        // 找到同组的所有事件并删除
        let groupEvents = events.filter { $0.recurrenceGroupId == groupId }
        for groupEvent in groupEvents {
            cancelLocalNotifications(for: groupEvent)
        }
        
        events.removeAll { $0.recurrenceGroupId == groupId }
        saveEvents()
        
        print("🗑️ 删除重复事件组：\(groupEvents.count)个事件")
    }
    
    /// 同步修改重复事件组中的所有事件
    private func updateRecurrenceGroup(groupId: UUID, updatedEvent: Event) {
        // 获取该组中除了当前事件外的所有其他事件
        let groupEvents = events.filter { $0.recurrenceGroupId == groupId && $0.id != updatedEvent.id }
        
        for i in events.indices {
            if let eventGroupId = events[i].recurrenceGroupId,
               eventGroupId == groupId,
               events[i].id != updatedEvent.id {
                
                // 保持原有的日期时间信息，但更新其他属性
                let originalStartAt = events[i].startAt
                let originalEndAt = events[i].endAt
                let originalIntendedDate = events[i].intendedDate
                
                // 更新标题、详情、推送设置等
                events[i].title = updatedEvent.title
                events[i].details = updatedEvent.details
                events[i].pushReminders = updatedEvent.pushReminders
                
                // 如果修改了时间设置（从有时间变无时间，或从无时间变有时间）
                if updatedEvent.startAt != nil && originalStartAt != nil {
                    // 两者都有时间：调整时间部分，保持日期不变
                    if let newStartAt = updatedEvent.startAt,
                       let originalDate = originalStartAt {
                        let calendar = Calendar.current
                        let newTimeComponents = calendar.dateComponents([.hour, .minute, .second], from: newStartAt)
                        events[i].startAt = calendar.date(bySettingHour: newTimeComponents.hour!,
                                                         minute: newTimeComponents.minute!,
                                                         second: newTimeComponents.second!,
                                                         of: originalDate)
                        
                        // 同时调整结束时间
                        if let newEndAt = updatedEvent.endAt,
                           let originalEndDate = originalEndAt {
                            let endTimeComponents = calendar.dateComponents([.hour, .minute, .second], from: newEndAt)
                            events[i].endAt = calendar.date(bySettingHour: endTimeComponents.hour!,
                                                           minute: endTimeComponents.minute!,
                                                           second: endTimeComponents.second!,
                                                           of: originalEndDate)
                        } else if let startAt = events[i].startAt {
                            // 如果原来没有结束时间，设为开始时间1小时后
                            events[i].endAt = startAt.addingTimeInterval(3600)
                        }
                    }
                } else if updatedEvent.startAt != nil && originalStartAt == nil {
                    // 从无时间变有时间：将时间部分应用到原归属日期
                    if let newStartAt = updatedEvent.startAt,
                       let targetDate = originalIntendedDate {
                        let calendar = Calendar.current
                        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: newStartAt)
                        events[i].startAt = calendar.date(bySettingHour: timeComponents.hour!,
                                                         minute: timeComponents.minute!,
                                                         second: timeComponents.second!,
                                                         of: targetDate)
                        events[i].endAt = events[i].startAt?.addingTimeInterval(3600)
                        events[i].intendedDate = nil // 清空归属日期，因为现在有具体时间了
                    }
                } else if updatedEvent.startAt == nil && originalStartAt != nil {
                    // 从有时间变无时间：设置归属日期为原开始时间的日期部分
                    if let originalDate = originalStartAt {
                        let calendar = Calendar.current
                        events[i].intendedDate = calendar.startOfDay(for: originalDate)
                    }
                    events[i].startAt = nil
                    events[i].endAt = nil
                } else {
                    // 都是无时间事项：保持不变
                    events[i].startAt = originalStartAt
                    events[i].endAt = originalEndAt
                    events[i].intendedDate = originalIntendedDate
                }
                
                // 保持ID不变，创建时间无法修改（let常量）
                events[i].isSynced = false // 需要重新同步
            }
        }
        
        print("🔄 同步修改重复事件组：\(groupEvents.count)个事件已更新")
    }
    
    /// 删除事项（通过ID）
    func deleteEvent(withId id: UUID) {
        events.removeAll { $0.id == id }
        saveEvents()
    }
    
    /// 更新事项（支持重复事件组同步修改）
    func updateEvent(_ updatedEvent: Event) {
        if let index = events.firstIndex(where: { $0.id == updatedEvent.id }) {
            // 保持同步状态不变（已同步的事项更新后仍需重新同步）
            var eventToUpdate = updatedEvent
            eventToUpdate.isSynced = false  // 更新后需要重新同步
            
            events[index] = eventToUpdate
            
            // 如果是重复事件，同步修改该组中的所有其他事件
            if let groupId = updatedEvent.recurrenceGroupId {
                updateRecurrenceGroup(groupId: groupId, updatedEvent: eventToUpdate)
            }
            
            saveEvents()
            
            // 同步到Supabase
            Task {
                await syncEventToSupabase(eventToUpdate)
                
                // 如果是重复事件组，同步所有组内事件
                if let groupId = updatedEvent.recurrenceGroupId {
                    let groupEvents = events.filter { $0.recurrenceGroupId == groupId && $0.id != updatedEvent.id }
                    for groupEvent in groupEvents {
                        await syncEventToSupabase(groupEvent)
                    }
                }
            }
        }
    }
    
    /// 获取指定日期的事项
    func eventsForDate(_ date: Date) -> [Event] {
        // 使用 Calendar.current.startOfDay 来确保日期比较的一致性
        let calendar = Calendar.current
        let targetDay = calendar.startOfDay(for: date)
        
        let filteredEvents = events.filter { event in
            // 现在都是独立事件，不需要过滤容器事件
            if let startAt = event.startAt {
                // 有执行时间：按执行日期过滤
                let eventDay = calendar.startOfDay(for: startAt)
                let isMatch = calendar.isDate(eventDay, inSameDayAs: targetDay)
                return isMatch
            } else {
                // 无执行时间：优先使用intendedDate，如果为空则回退到createdAt
                let referenceDate = event.intendedDate ?? event.createdAt
                let eventDay = calendar.startOfDay(for: referenceDate)
                let isMatch = calendar.isDate(eventDay, inSameDayAs: targetDay)
                return isMatch
            }
        }.sorted { event1, event2 in
            // 按创建时间倒序排列（新建的在顶部）
            return event1.createdAt > event2.createdAt
        }
        
        // 调试信息（可以在发布时注释掉）
        if filteredEvents.count > 0 {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            print("📅 获取\(formatter.string(from: date))的事项: 找到\(filteredEvents.count)个事项")
        }
        
        return filteredEvents
    }
    
    /// 创建新事项
    func createEvent(title: String, date: Date) -> Event {
        // 为无时间事项设置intendedDate为指定日期，createdAt为当前时间
        let newEvent = Event(
            title: title,
            startAt: nil,    // 快速创建时不自动设置时间
            endAt: nil,      // 结束时间默认为空
            details: nil,    // 详情默认为空
            pushReminders: [.dayBefore], // 明确设置默认推送提醒
            createdAt: Date(), // 使用当前时间作为创建时间
            intendedDate: date  // 使用用户选择的日期作为事件归属日期
        )
        
        addEvent(newEvent)
        return newEvent
    }
    
    /// 创建新事项（完整版本）
    func createEvent(title: String, date: Date, startAt: Date?, endAt: Date?, details: String?) -> Event {
        let newEvent = Event(
            title: title,
            startAt: startAt,
            endAt: endAt,
            details: details,
            pushReminders: [.dayBefore],
            createdAt: Date(),  // 使用当前时间作为创建时间
            intendedDate: startAt == nil ? date : nil  // 只有无时间事项才设置intendedDate
        )
        addEvent(newEvent)
        return newEvent
    }
    
    /// 更新事项（完整版本）
    func updateEvent(_ event: Event, title: String, startAt: Date?, endAt: Date?, details: String?) {
        if let index = events.firstIndex(where: { $0.id == event.id }) {
            events[index].title = title
            events[index].startAt = startAt
            events[index].endAt = endAt
            events[index].details = details
            saveEvents()
        }
    }
    
    /// 清空所有数据（用于测试）
    func clearAllEvents() {
        events.removeAll()
        saveEvents()
    }
    
    // MARK: - Supabase Sync Methods
    
    /// 同步事项到Supabase数据库
    private func syncEventToSupabase(_ event: Event) async {
        // 检查是否已经同步过，如果已同步则跳过
        if event.isSynced {
            print("⏭️ 事项已同步，跳过：\(event.title)")
            return
        }
        
        guard SupabaseManager.shared.isAuthenticated,
              let userId = SupabaseManager.shared.currentUser?.id else {
            print("❌ 用户未登录，跳过同步到Supabase")
            return
        }
        
        do {
            // 先尝试使用新字段结构
            do {
                struct EventDataWithReminders: Codable {
                    let id: String
                    let user_id: String
                    let title: String
                    let start_at: String?
                    let end_at: String?
                    let details: String?
                    let intended_date: String?  // 新增：事件归属日期
                    let push_reminders: [String]
                    let push_day_before: Bool
                    let push_week_before: Bool
                    let push_status: [String: Bool]?
                    let created_at: String
                    // 重复事件字段
                    let recurrence_group_id: String?
                    let recurrence_type: String?
                    let recurrence_count: Int?
                    let recurrence_end_date: String?
                }
                
                let eventData = EventDataWithReminders(
                    id: event.id.uuidString,
                    user_id: userId.uuidString,
                    title: event.title,
                    start_at: event.startAt?.ISO8601Format(),
                    end_at: event.endAt?.ISO8601Format(),
                    details: event.details,
                    intended_date: event.intendedDate.map { date in
                        // 将intended_date转换为UTC的午夜时间，避免时区偏移
                        let calendar = Calendar.current
                        let components = calendar.dateComponents([.year, .month, .day], from: date)
                        // 修复：使用UTC日历创建UTC午夜时间，确保日期不偏移
                        var utcCalendar = Calendar(identifier: .gregorian)
                        utcCalendar.timeZone = TimeZone(identifier: "UTC")!
                        let utcMidnight = utcCalendar.date(from: components)!
                        return utcMidnight.ISO8601Format()
                    },  // 新增：同步事件归属日期
                    push_reminders: event.pushReminders.map { $0.rawValue },
                    push_day_before: event.pushDayBefore,
                    push_week_before: event.pushWeekBefore,
                    push_status: [
                        "day_before_sent": event.pushStatus.dayBeforeSent,
                        "week_before_sent": event.pushStatus.weekBeforeSent
                    ],
                    created_at: event.createdAt.ISO8601Format(),
                    // 重复事件字段
                    recurrence_group_id: event.recurrenceGroupId?.uuidString,
                    recurrence_type: event.recurrenceType != .none ? event.recurrenceType.rawValue : nil,
                    recurrence_count: event.recurrenceCount,
                    recurrence_end_date: event.recurrenceEndDate?.ISO8601Format()
                )
                
                try await supabase
                    .from("events")
                    .upsert(eventData)
                    .execute()
                
                print("✅ 事项同步到Supabase成功（含push_reminders）：\(event.title)")
                
                // 更新本地事件的同步状态
                await MainActor.run {
                    markEventAsSynced(event.id)
                }
            } catch {
                // 如果新字段不存在，回退到旧字段结构
                print("⚠️ push_reminders字段不存在，使用向后兼容模式")
                
                struct EventDataLegacy: Codable {
                    let id: String
                    let user_id: String
                    let title: String
                    let start_at: String?
                    let end_at: String?
                    let details: String?
                    let intended_date: String?  // 新增：事件归属日期（向后兼容模式也包含）
                    let push_day_before: Bool
                    let push_week_before: Bool
                    let push_status: [String: Bool]?
                    let created_at: String
                }
                
                // 如果有任何提醒设置，至少设置day_before为true以确保Edge Function能检测到
                let hasPushReminders = !event.pushReminders.isEmpty
                
                let eventDataLegacy = EventDataLegacy(
                    id: event.id.uuidString,
                    user_id: userId.uuidString,
                    title: event.title,
                    start_at: event.startAt?.ISO8601Format(),
                    end_at: event.endAt?.ISO8601Format(),
                    details: event.details,
                    intended_date: event.intendedDate.map { date in
                        // 将intended_date转换为UTC的午夜时间，避免时区偏移
                        let calendar = Calendar.current
                        let components = calendar.dateComponents([.year, .month, .day], from: date)
                        // 修复：使用UTC日历创建UTC午夜时间，确保日期不偏移
                        var utcCalendar = Calendar(identifier: .gregorian)
                        utcCalendar.timeZone = TimeZone(identifier: "UTC")!
                        let utcMidnight = utcCalendar.date(from: components)!
                        return utcMidnight.ISO8601Format()
                    },  // 新增：向后兼容模式也同步归属日期
                    push_day_before: event.pushDayBefore || hasPushReminders, // 如果有任何提醒就设为true
                    push_week_before: event.pushWeekBefore,
                    push_status: [
                        "day_before_sent": event.pushStatus.dayBeforeSent,
                        "week_before_sent": event.pushStatus.weekBeforeSent
                    ],
                    created_at: event.createdAt.ISO8601Format()
                )
                
                try await supabase
                    .from("events")
                    .upsert(eventDataLegacy)
                    .execute()
                
                print("✅ 事项同步到Supabase成功（向后兼容模式）：\(event.title)")
                
                // 更新本地事件的同步状态
                await MainActor.run {
                    markEventAsSynced(event.id)
                }
            }
            
        } catch {
            print("❌ 同步事项到Supabase失败：\(error)")
        }
    }
    
    /// 标记事项为已同步状态
    func markEventAsSynced(_ eventId: UUID) {
        if let index = events.firstIndex(where: { $0.id == eventId }) {
            events[index].isSynced = true
            saveEvents()
            print("✅ 事项标记为已同步：\(events[index].title)")
        }
    }

    /// 将本地事件ID替换为远端已存在的ID（用于去重合并）
    func replaceEventId(oldId: UUID, newId: UUID) {
        if let index = events.firstIndex(where: { $0.id == oldId }) {
            let old = events[index]
            var newEvent = Event(
                id: newId,
                title: old.title,
                startAt: old.startAt,
                endAt: old.endAt,
                details: old.details,
                pushReminders: old.pushReminders,
                createdAt: old.createdAt,
                intendedDate: old.intendedDate,
                isSynced: true
            )
            newEvent.pushStatus = old.pushStatus
            events[index] = newEvent
            saveEvents()
            print("🔗 本地事件ID重映射为远端ID，避免重复：\(newEvent.title)")
        }
    }
    
    // MARK: - Local Notifications
    
    /// 为事件调度本地通知（仅支持短期提醒）
    private func scheduleLocalNotifications(for event: Event) {
        // 现在所有事件都可以调度通知
        
        // 获取事件的参考时间
        let referenceDate: Date
        if let startAt = event.startAt {
            referenceDate = startAt
        } else if let intendedDate = event.intendedDate {
            // 对于无时间事项，设定为当天上午9点提醒
            let calendar = Calendar.current
            referenceDate = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: intendedDate) ?? intendedDate
        } else {
            print("⚠️ 事件无有效时间，跳过本地通知：\(event.title)")
            return
        }
        
        // 只调度短期提醒（长期提醒由Edge Function处理）
        let shortTermReminders = event.pushReminders.filter { reminder in
            switch reminder {
            case .atTime, .minutes15, .minutes30, .hours1, .hours2:
                return true
            case .dayBefore, .weekBefore, .none:
                return false
            }
        }
        
        for reminder in shortTermReminders {
            let notificationTime = referenceDate.addingTimeInterval(reminder.timeOffsetSeconds)
            
            // 只调度未来的通知
            guard notificationTime > Date() else { continue }
            
            let content = UNMutableNotificationContent()
            content.title = "HiCalendar提醒"
            content.body = createNotificationMessage(for: event, reminderType: reminder)
            content.sound = UNNotificationSound.default
            content.userInfo = [
                "eventId": event.id.uuidString,
                "reminderType": reminder.rawValue
            ]
            
            let calendar = Calendar.current
            let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: notificationTime)
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            
            let identifier = "\(event.id.uuidString)_\(reminder.rawValue)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("❌ 本地通知调度失败: \(error)")
                } else {
                    print("✅ 本地通知已调度: \(event.title) - \(reminder.displayName)")
                }
            }
        }
    }
    
    /// 创建通知消息（固定中度吐槽风格）
    private func createNotificationMessage(for event: Event, reminderType: PushReminderOption) -> String {
        let timePrefix: String
        switch reminderType {
        case .atTime:
            timePrefix = ""
        case .minutes15:
            timePrefix = "15分钟后"
        case .minutes30:
            timePrefix = "30分钟后"  
        case .hours1:
            timePrefix = "1小时后"
        case .hours2:
            timePrefix = "2小时后"
        default:
            timePrefix = ""
        }
        
        let messages = [
            "\(timePrefix)「\(event.title)」\(timePrefix.isEmpty ? "时间到了" : "")，别又说忘了！",
            "\(timePrefix)「\(event.title)」\(timePrefix.isEmpty ? "开始了" : "")，准备好了吗？",
            "\(timePrefix)「\(event.title)」\(timePrefix.isEmpty ? "该进行了" : "")，赶紧的！"
        ]
        
        return messages.randomElement() ?? "\(timePrefix)「\(event.title)」提醒"
    }
    
    /// 取消事件的本地通知
    private func cancelLocalNotifications(for event: Event) {
        let identifiers = PushReminderOption.allCases.map { reminder in
            "\(event.id.uuidString)_\(reminder.rawValue)"
        }
        
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        print("🗑️ 已取消本地通知：\(event.title)")
    }
}
