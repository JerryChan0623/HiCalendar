//
//  EventStorageManager.swift
//  HiCalendar
//
//  Local storage manager for events using UserDefaults
//

import Foundation
import Supabase
import UserNotifications
import WidgetKit

class EventStorageManager: ObservableObject {
    static let shared = EventStorageManager()
    
    private let userDefaults = UserDefaults.standard
    private let eventsKey = "SavedEvents"
    private let supabase = SupabaseManager.shared.client
    
    // MARK: - App Groups Support for Widget
    private let appGroupsDefaults = UserDefaults(suiteName: "group.com.chenzhencong.HiCalendar")
    private let sharedEventsKey = "shared_events"
    
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
            print("📅 从UserDefaults加载了 \(events.count) 个事项")
            
            // 每次加载时都同步到Widget（确保数据一致性）
            saveEventsForWidget()
        } else {
            // 如果没有本地数据，使用示例数据（标记为已同步，避免上传到云端）
            var samples = Event.sampleEvents
            for i in samples.indices { samples[i].isSynced = true }
            self.events = samples
            print("📅 未找到已保存的事项，初始化样本数据: \(events.count) 个")
            saveEvents()
        }
    }
    
    /// 保存所有事项
    private func saveEvents() {
        if let data = try? JSONEncoder().encode(events) {
            userDefaults.set(data, forKey: eventsKey)
            
            // 同时保存到App Groups以供Widget访问
            saveEventsForWidget()
        }
    }
    
    /// 保存事件数据到App Groups，供Widget使用
    private func saveEventsForWidget() {
        // 检查是否已购买Widget功能
        // 使用异步方式避免死锁
        Task { @MainActor in
            let canUseWidget = PurchaseManager.shared.canUseWidget
            guard canUseWidget else {
                print("💰 Widget功能需要Pro版本，跳过数据同步")
                // 清空App Groups中的数据，防止非付费用户使用Widget
                if let appGroupsDefaults = self.appGroupsDefaults {
                    appGroupsDefaults.removeObject(forKey: self.sharedEventsKey)
                }
                return
            }

            // 执行实际的Widget数据保存
            self.performWidgetDataSave()
        }
    }

    /// 执行Widget数据保存的实际逻辑
    private func performWidgetDataSave() {

        guard let appGroupsDefaults = appGroupsDefaults else {
            print("❌ 无法访问App Groups UserDefaults")
            return
        }
        
        // 为Widget准备精简的事件数据（减少不必要的信息）
        let widgetEvents = events.map { event in
            return event // Widget需要完整的Event模型来进行日期筛选
        }
        
        do {
            let data = try JSONEncoder().encode(widgetEvents)
            appGroupsDefaults.set(data, forKey: sharedEventsKey)
            
            // 触发Widget刷新
            WidgetCenter.shared.reloadAllTimelines()
            
            print("✅ 已保存 \(widgetEvents.count) 个事件到App Groups")
        } catch {
            print("❌ 保存Widget数据失败: \(error)")
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

        // 更新会话中创建的事件数
        let currentCount = UserDefaults.standard.integer(forKey: "EventsCreatedInSession")
        UserDefaults.standard.set(currentCount + newEvents.count, forKey: "EventsCreatedInSession")

        // 为每个事件调度本地通知和同步
        for event in newEvents {
            // 追踪事件创建（非onboarding事件）
            if !event.isOnboarding {
                Task { @MainActor in
                    trackEventCreated(event: event)
                }
            }

            scheduleLocalNotifications(for: event)
            Task {
                await syncEventToSupabase(event)
            }

            // 如果启用了双向同步且事件不是来自系统日历，则自动导出到系统日历
            if !event.isFromSystemCalendar && !event.isOnboarding {
                Task {
                    await autoExportToSystemCalendar(event: event)
                }
            }
        }
    }

    // MARK: - Mixpanel Tracking Helper
    @MainActor
    private func trackEventCreated(event: Event) {
        let reminderTypes = event.pushReminders.map { $0.rawValue }

        MixpanelManager.shared.trackEventCreated(
            creationMethod: "manual",
            hasTime: event.startAt != nil,
            hasDetails: event.details != nil && !event.details!.isEmpty,
            reminderCount: event.pushReminders.count,
            reminderTypes: reminderTypes,
            isRecurring: event.isRecurrenceEvent,
            recurrenceType: event.originalRecurrenceType?.rawValue,
            recurrenceCount: event.recurrenceCount,
            characterCountTitle: event.title.count,
            characterCountDetails: event.details?.count ?? 0,
            timeSpent: 0 // 这里可以在创建事件时传入实际时间
        )
    }
    
    /// 添加重复事件 - 保留此方法以兼容旧代码
    func addRecurringEvents(_ baseEvent: Event) {
        // 直接调用addEvent，因为重复事件生成已经在调用方完成
        addEvent(baseEvent)
    }
    
    /// 删除事项
    func deleteEvent(_ event: Event) {
        // 追踪事件删除（非onboarding事件）
        if !event.isOnboarding {
            Task { @MainActor in
                trackEventDeleted(event: event, deletionMethod: "swipe") // 默认为swipe，可以在调用时传入具体方法
            }
        }

        // 取消本地通知
        cancelLocalNotifications(for: event)

        events.removeAll { $0.id == event.id }
        saveEvents()

        // 如果用户是会员且事件已同步，则从云端删除
        Task {
            let canSync = await MainActor.run {
                PurchaseManager.shared.canSyncToCloud
            }
            if canSync && event.isSynced {
                let success = await SupabaseManager.shared.deleteCloudEvent(eventId: event.id)
                if success {
                    print("✅ 已从云端删除事件: \(event.title)")
                } else {
                    print("⚠️ 云端删除失败，事件仅在本地删除: \(event.title)")
                }
            }
        }
    }

    @MainActor
    private func trackEventDeleted(event: Event, deletionMethod: String) {
        let eventAgeDays = Calendar.current.dateComponents([.day], from: event.createdAt, to: Date()).day ?? 0

        MixpanelManager.shared.trackEventDeleted(
            eventAgeDays: eventAgeDays,
            deletionMethod: deletionMethod,
            isRecurringEvent: event.isRecurrenceEvent,
            hadReminders: !event.pushReminders.isEmpty,
            confirmationShown: false // 可以根据实际UI调整
        )
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
        // 找到要删除的事件用于云端同步
        let eventToDelete = events.first { $0.id == id }

        events.removeAll { $0.id == id }
        saveEvents()

        // 如果找到事件且用户是会员且事件已同步，则从云端删除
        if let event = eventToDelete {
            Task {
                let canSync = await MainActor.run {
                    PurchaseManager.shared.canSyncToCloud
                }
                if canSync && event.isSynced {
                    let success = await SupabaseManager.shared.deleteCloudEvent(eventId: event.id)
                    if success {
                        print("✅ 已从云端删除事件: \(event.title)")
                    } else {
                        print("⚠️ 云端删除失败，事件仅在本地删除: \(event.title)")
                    }
                }
            }
        }
    }
    
    /// 更新事项（支持重复事件组同步修改）
    func updateEvent(_ updatedEvent: Event) {
        if let index = events.firstIndex(where: { $0.id == updatedEvent.id }) {
            let oldEvent = events[index]

            // 保持同步状态不变（已同步的事项更新后仍需重新同步）
            var eventToUpdate = updatedEvent
            eventToUpdate.isSynced = false  // 更新后需要重新同步

            events[index] = eventToUpdate

            // 如果是重复事件，同步修改该组中的所有其他事件
            if let groupId = updatedEvent.recurrenceGroupId {
                updateRecurrenceGroup(groupId: groupId, updatedEvent: eventToUpdate)
            }

            saveEvents()

            // 如果用户是会员且原事件已同步，则立即同步到云端
            Task { [eventToUpdate] in
                let canSync = await MainActor.run {
                    PurchaseManager.shared.canSyncToCloud
                }
                if canSync && oldEvent.isSynced {
                    let success = await SupabaseManager.shared.updateCloudEvent(eventToUpdate)
                    if success {
                        // 标记为已同步
                        await MainActor.run {
                            if let idx = self.events.firstIndex(where: { $0.id == eventToUpdate.id }) {
                                self.events[idx].isSynced = true
                                self.saveEvents()
                            }
                        }
                        print("✅ 已同步更新到云端: \(eventToUpdate.title)")
                    } else {
                        print("⚠️ 云端更新失败，事件仅在本地更新: \(eventToUpdate.title)")
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
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        print("📅 获取\(formatter.string(from: date))的事项: 找到\(filteredEvents.count)个事项")

        // 额外调试：显示所有相关的"缴纳电费"事件
        let allPaymentEvents = events.filter { $0.title.contains("缴纳电费") }
        if !allPaymentEvents.isEmpty {
            print("🔍 所有'缴纳电费'事项 (总数: \(allPaymentEvents.count)):")
            print("🕒 查询目标日期: \(formatter.string(from: date)) -> startOfDay: \(formatter.string(from: targetDay))")

            // 按ID分组显示，检查是否有重复ID
            let groupedById = Dictionary(grouping: allPaymentEvents) { $0.id }
            print("📊 按ID分组: \(groupedById.count)个不同ID")

            // 按系统日历ID分组显示，检查是否有重复的系统ID
            let groupedBySystemId = Dictionary(grouping: allPaymentEvents) { $0.systemCalendarEventID ?? "nil" }
            print("📊 按系统ID分组: \(groupedBySystemId.count)个不同系统ID")
            for (systemId, events) in groupedBySystemId {
                print("  系统ID \(systemId): \(events.count)个事件")
            }

            for (index, event) in allPaymentEvents.enumerated() {
                print("  [\(index + 1)] ID: \(event.id)")
                print("      系统ID: \(event.systemCalendarEventID ?? "nil")")
                print("      创建时间: \(formatter.string(from: event.createdAt))")

                if let startAt = event.startAt {
                    let eventDay = calendar.startOfDay(for: startAt)
                    let isMatch = calendar.isDate(eventDay, inSameDayAs: targetDay)
                    print("      \(event.title): \(formatter.string(from: startAt)) (有时间) -> eventDay: \(formatter.string(from: eventDay)), 匹配: \(isMatch)")
                } else if let intendedDate = event.intendedDate {
                    let eventDay = calendar.startOfDay(for: intendedDate)
                    let isMatch = calendar.isDate(eventDay, inSameDayAs: targetDay)
                    print("      \(event.title): \(formatter.string(from: intendedDate)) (无时间-intendedDate) -> eventDay: \(formatter.string(from: eventDay)), 匹配: \(isMatch)")

                    // 详细的日期组件调试
                    let intendedComponents = calendar.dateComponents([.year, .month, .day], from: intendedDate)
                    let targetComponents = calendar.dateComponents([.year, .month, .day], from: targetDay)
                    print("      详细对比: intended(\(intendedComponents.year ?? 0)-\(intendedComponents.month ?? 0)-\(intendedComponents.day ?? 0)) vs target(\(targetComponents.year ?? 0)-\(targetComponents.month ?? 0)-\(targetComponents.day ?? 0))")
                } else {
                    let referenceDate = event.createdAt
                    let eventDay = calendar.startOfDay(for: referenceDate)
                    let isMatch = calendar.isDate(eventDay, inSameDayAs: targetDay)
                    print("      \(event.title): \(formatter.string(from: referenceDate)) (无时间-createdAt) -> eventDay: \(formatter.string(from: eventDay)), 匹配: \(isMatch)")
                }
            }
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
    
    /// 更新重复事件组（批量更新）
    func updateRecurrenceGroupEvent(_ updatedEvent: Event) {
        guard let groupId = updatedEvent.recurrenceGroupId else {
            print("❌ 事件不属于重复组，使用普通更新")
            updateEvent(updatedEvent)  // 调用完整版本的updateEvent方法，保留所有字段
            return
        }
        
        // 更新当前事件
        if let index = events.firstIndex(where: { $0.id == updatedEvent.id }) {
            var eventToUpdate = updatedEvent
            eventToUpdate.isSynced = false  // 更新后需要重新同步
            events[index] = eventToUpdate
        }
        
        // 批量更新同组的其他事件（只更新可共享的属性）
        for i in events.indices {
            if let eventGroupId = events[i].recurrenceGroupId,
               eventGroupId == groupId,
               events[i].id != updatedEvent.id {
                
                // 保持原有的日期时间信息不变
                let originalStartAt = events[i].startAt
                
                // 只更新共享属性：标题、详情、推送设置、重复规则
                events[i].title = updatedEvent.title
                events[i].details = updatedEvent.details
                events[i].pushReminders = updatedEvent.pushReminders
                events[i].recurrenceType = updatedEvent.recurrenceType
                events[i].recurrenceCount = updatedEvent.recurrenceCount
                events[i].recurrenceEndDate = updatedEvent.recurrenceEndDate
                events[i].isSynced = false  // 需要重新同步
                
                // 如果原始事件没有时间，但现在设置了时间模式，需要重新计算
                if updatedEvent.startAt != nil && originalStartAt != nil {
                    // 有时间事件：保持相对时间间隔
                    let timeDifference = updatedEvent.endAt?.timeIntervalSince(updatedEvent.startAt!) ?? 3600
                    events[i].endAt = originalStartAt?.addingTimeInterval(timeDifference)
                } else if updatedEvent.startAt == nil && originalStartAt != nil {
                    // 从有时间变无时间：清除时间，保持原始日期
                    events[i].startAt = nil
                    events[i].endAt = nil
                    // intendedDate保持不变
                }
                
                print("🔄 同步更新组内事件：\(events[i].title) - \(events[i].startAt?.formatted(.dateTime.month().day()) ?? "无时间")")
            }
        }
        
        saveEvents()
        
        // 同步到Supabase
        Task {
            await syncEventToSupabase(updatedEvent)
            
            // 同步组内所有其他事件
            let groupEvents = events.filter { $0.recurrenceGroupId == groupId && $0.id != updatedEvent.id }
            for groupEvent in groupEvents {
                await syncEventToSupabase(groupEvent)
            }
        }
        
        print("✅ 批量更新完成，共更新\(events.filter { $0.recurrenceGroupId == groupId }.count)个重复事件")
    }
    
    /// 手动强制同步Widget数据（调试用）
    func forceWidgetSync() {
        // 检查是否已购买Widget功能
        Task { @MainActor in
            let canUseWidget = PurchaseManager.shared.canUseWidget
            guard canUseWidget else {
                print("💰 Widget功能需要Pro版本，无法强制同步")
                return
            }

            // 执行同步
            await self.performForceWidgetSync()
        }
    }

    /// 执行强制Widget同步的实际逻辑
    private func performForceWidgetSync() async {
        // 直接调用Widget数据保存
        performWidgetDataSave()

        // 立即刷新所有Widget
        WidgetCenter.shared.reloadAllTimelines()

        // 输出调试信息
        print("🔄 强制同步Widget数据完成")
        print("📊 当前事件数量: \(events.count)")

        if let appGroupsDefaults = appGroupsDefaults,
           let data = appGroupsDefaults.data(forKey: sharedEventsKey) {
            do {
                let savedEvents = try JSONDecoder().decode([Event].self, from: data)
                print("✅ App Groups中确认有 \(savedEvents.count) 个事件")
            } catch {
                print("❌ App Groups数据解码失败: \(error)")
            }
        } else {
            print("❌ App Groups中没有数据")
        }
    }
    
    
    // MARK: - Supabase Sync Methods
    
    /// 同步事项到Supabase数据库
    private func syncEventToSupabase(_ event: Event) async {
        // 检查是否为onboarding事项或系统日历事项（不同步到云端）
        if event.isOnboarding {
            print("📚 Onboarding事项不同步到云端，跳过：\(event.title)")
            return
        }

        if event.isFromSystemCalendar {
            print("📅 系统日历事项不同步到云端，跳过：\(event.title)")
            return
        }

        // 检查是否已经同步过，如果已同步则跳过
        if event.isSynced {
            print("⏭️ 事项已同步，跳过：\(event.title)")
            return
        }

        // 检查云同步权限（会员功能）
        let canSync = await MainActor.run {
            PurchaseManager.shared.canSyncToCloud
        }
        guard canSync else {
            print("💰 云同步功能需要Pro版本，跳过同步: \(event.title)")
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
                recurrenceGroupId: old.recurrenceGroupId,
                originalRecurrenceType: old.originalRecurrenceType,
                recurrenceCount: old.recurrenceCount,
                recurrenceEndDate: old.recurrenceEndDate,
                isSynced: true
            )
            newEvent.pushStatus = old.pushStatus
            events[index] = newEvent
            saveEvents()
            print("🔗 本地事件ID重映射为远端ID，避免重复：\(newEvent.title)")
        }
    }
    
    // MARK: - System Calendar Integration

    /// 自动导出新创建的事件到系统日历（实时同步）
    private func autoExportToSystemCalendar(event: Event) async {
        print("🔄 开始自动导出新事件到系统日历: \(event.title)")
        print("📋 事件详情: startAt=\(event.startAt?.description ?? "nil"), intendedDate=\(event.intendedDate?.description ?? "nil")")

        // 延迟执行避免与事件创建过程冲突
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1秒延迟

        await MainActor.run {
            let syncManager = SystemCalendarManager.shared
            print("🔍 系统日历同步状态检查:")
            print("  - syncEnabled: \(syncManager.syncEnabled)")
            print("  - hasCalendarAccess: \(syncManager.hasCalendarAccess)")
            print("  - syncDirection: \(syncManager.syncDirection)")
            print("  - isPremium: \(PurchaseManager.shared.isPremiumUnlocked)")

            Task {
                let success = await syncManager.exportEventToSystemCalendar(event)

                if success {
                    print("✅ 成功自动导出事件到系统日历: \(event.title)")
                } else {
                    print("❌ 自动导出事件失败: \(event.title)")
                }
            }
        }
    }

    // MARK: - Local Notifications
    
    /// 为事件调度本地通知（仅支持短期提醒）
    private func scheduleLocalNotifications(for event: Event) {
        // 本地通知允许所有用户使用（基础功能）
        // 仅云端推送功能需要会员权限
        
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
