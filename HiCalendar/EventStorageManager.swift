//
//  EventStorageManager.swift
//  HiCalendar
//
//  Local storage manager for events using UserDefaults
//

import Foundation

class EventStorageManager: ObservableObject {
    static let shared = EventStorageManager()
    
    private let userDefaults = UserDefaults.standard
    private let eventsKey = "SavedEvents"
    
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
            // 如果没有本地数据，使用示例数据
            self.events = Event.sampleEvents
            saveEvents()
        }
    }
    
    /// 保存所有事项
    private func saveEvents() {
        if let data = try? JSONEncoder().encode(events) {
            userDefaults.set(data, forKey: eventsKey)
        }
    }
    
    /// 添加新事项
    func addEvent(_ event: Event) {
        events.append(event)
        saveEvents()
    }
    
    /// 删除事项
    func deleteEvent(_ event: Event) {
        events.removeAll { $0.id == event.id }
        saveEvents()
    }
    
    /// 删除事项（通过ID）
    func deleteEvent(withId id: UUID) {
        events.removeAll { $0.id == id }
        saveEvents()
    }
    
    /// 更新事项
    func updateEvent(_ updatedEvent: Event) {
        if let index = events.firstIndex(where: { $0.id == updatedEvent.id }) {
            events[index] = updatedEvent
            saveEvents()
        }
    }
    
    /// 获取指定日期的事项
    func eventsForDate(_ date: Date) -> [Event] {
        // 使用 Calendar.current.startOfDay 来确保日期比较的一致性
        let calendar = Calendar.current
        let targetDay = calendar.startOfDay(for: date)
        
        let filteredEvents = events.filter { event in
            // 所有事项都应该有 startAt 时间，按日期精确过滤
            if let startAt = event.startAt {
                let eventDay = calendar.startOfDay(for: startAt)
                let isMatch = calendar.isDate(eventDay, inSameDayAs: targetDay)
                return isMatch
            } else {
                // 理论上不应该存在没有 startAt 的事项，但为了安全起见保留
                return false
            }
        }.sorted { event1, event2 in
            // 按创建时间倒序排列（新建的在顶部）
            return event1.createdAt > event2.createdAt
        }
        
        return filteredEvents
    }
    
    /// 创建新事项
    func createEvent(title: String, date: Date) -> Event {
        let calendar = Calendar.current
        let newEvent = Event(
            title: title,
            startAt: calendar.startOfDay(for: date),  // 设置为对应日期的开始时间
            endAt: nil,      // 结束时间默认为空
            details: nil     // 详情默认为空
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
            details: details
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
}
