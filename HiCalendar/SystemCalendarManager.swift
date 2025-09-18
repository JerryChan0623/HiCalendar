//
//  SystemCalendarManager.swift
//  HiCalendar
//
//  Created on 2025. System Calendar Integration Manager
//

import Foundation
import EventKit
import SwiftUI

@MainActor
class SystemCalendarManager: ObservableObject {
    static let shared = SystemCalendarManager()

    private let eventStore = EKEventStore()

    // MARK: - Published Properties
    @Published var hasCalendarAccess = false
    @Published var isLoading = false
    @Published var syncEnabled = false
    @Published var lastSyncDate: Date?
    @Published var errorMessage: String?

    // 同步设置
    @Published var syncDirection: SyncDirection = .bidirectional
    @Published var selectedCalendars: Set<String> = []
    @Published var syncFrequency: SyncFrequency = .realtime

    // 可用的系统日历
    @Published var availableCalendars: [EKCalendar] = []

    // 定时器自动同步
    private var syncTimer: Timer?

    private init() {
        loadSettings()
        checkCalendarAuthorizationStatus()
        setupRealtimeSync()
        setupAppLifecycleObservers()
    }

    // MARK: - Real-time Sync Implementation

    /// 设置实时同步监听
    private func setupRealtimeSync() {
        // 监听系统日历数据库变化
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleEKEventStoreChanged),
            name: .EKEventStoreChanged,
            object: eventStore
        )
        print("📱 已设置系统日历数据库变化监听")
    }

    /// 处理EventKit数据库变化通知
    @objc private func handleEKEventStoreChanged(_ notification: Notification) {
        print("🔄 检测到系统日历数据变化，准备同步...")

        // 检查权限和设置
        guard hasCalendarAccess,
              syncEnabled,
              syncFrequency == .realtime else {
            print("⏸️ 跳过同步: 权限=\(hasCalendarAccess), 开启=\(syncEnabled), 频率=\(syncFrequency)")
            return
        }

        // 检查会员状态
        guard PurchaseManager.shared.isPremiumUnlocked else {
            print("💰 非会员用户，跳过实时同步")
            return
        }

        // 延迟执行避免频繁触发
        Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1秒延迟
            await performSync()
        }
    }

    /// 设置应用生命周期监听
    private func setupAppLifecycleObservers() {
        // 应用进入前台时同步
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )

        // 应用进入后台时同步（如果有未保存的更改）
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )

        print("📱 已设置应用生命周期同步监听")
    }

    /// 应用进入前台处理
    @objc private func handleAppDidBecomeActive(_ notification: Notification) {
        Task {
            await schedulePeriodicSync()
        }
    }

    /// 应用进入后台处理
    @objc private func handleAppDidEnterBackground(_ notification: Notification) {
        // 在后台快速同步重要更改
        if syncEnabled && hasCalendarAccess && PurchaseManager.shared.isPremiumUnlocked {
            Task {
                await performQuickSync()
            }
        }
    }

    /// 定期同步检查
    private func schedulePeriodicSync() async {
        guard syncEnabled,
              hasCalendarAccess,
              PurchaseManager.shared.isPremiumUnlocked else {
            return
        }

        // 检查是否需要同步（超过5分钟未同步）
        if let lastSync = lastSyncDate,
           Date().timeIntervalSince(lastSync) < 300 { // 5分钟
            print("⏸️ 距离上次同步不足5分钟，跳过定期同步")
            return
        }

        print("🔄 执行定期同步检查...")
        await performSync()
    }

    /// 快速同步（仅同步未保存的更改）
    private func performQuickSync() async {
        print("⚡ 执行快速同步...")

        // 只导出新创建的HiCalendar事项到系统日历
        if syncDirection == .exportOnly || syncDirection == .bidirectional {
            await exportRecentEventsToSystemCalendar()
        }
    }

    // MARK: - Timer-based Sync

    /// 设置定时器同步
    private func setupTimerSync() {
        stopTimerSync() // 先停止现有定时器

        // 只有在启用同步且为会员时才设置定时器
        guard syncEnabled,
              hasCalendarAccess,
              PurchaseManager.shared.isPremiumUnlocked else {
            print("⏸️ 未满足定时器同步条件，跳过设置")
            return
        }

        let interval: TimeInterval
        switch syncFrequency {
        case .manual:
            print("📋 手动同步模式，不设置定时器")
            return
        case .hourly:
            interval = 3600 // 1小时
        case .daily:
            interval = 86400 // 24小时
        case .realtime:
            interval = 300 // 5分钟（实时模式的后备定时器）
        }

        print("⏰ 设置定时器同步，间隔: \(interval)秒")
        syncTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.performPeriodicTimerSync()
            }
        }
    }

    /// 停止定时器同步
    private func stopTimerSync() {
        syncTimer?.invalidate()
        syncTimer = nil
        print("⏹️ 定时器同步已停止")
    }

    /// 定时器触发的周期性同步
    private func performPeriodicTimerSync() async {
        print("⏰ 定时器触发周期性同步...")

        // 检查条件是否仍然满足
        guard syncEnabled,
              hasCalendarAccess,
              PurchaseManager.shared.isPremiumUnlocked else {
            print("⏸️ 同步条件已不满足，停止定时器")
            stopTimerSync()
            return
        }

        // 检查是否已经很久没同步了
        if let lastSync = lastSyncDate,
           Date().timeIntervalSince(lastSync) < 60 { // 1分钟内已同步过
            print("⏸️ 最近已同步，跳过定时器同步")
            return
        }

        await performSync()
    }

    // MARK: - Sync Configuration Enums
    enum SyncDirection: String, CaseIterable {
        case importOnly = "import_only"
        case exportOnly = "export_only"
        case bidirectional = "bidirectional"

        var displayName: String {
            switch self {
            case .importOnly: return L10n.importOnlyCalendar
            case .exportOnly: return L10n.exportOnlyCalendar
            case .bidirectional: return L10n.bidirectionalSync
            }
        }

        var description: String {
            switch self {
            case .importOnly: return L10n.importOnlyDescription
            case .exportOnly: return L10n.exportOnlyDescription
            case .bidirectional: return L10n.bidirectionalDescription
            }
        }
    }

    enum SyncFrequency: String, CaseIterable {
        case manual = "manual"
        case hourly = "hourly"
        case daily = "daily"
        case realtime = "realtime"

        var displayName: String {
            switch self {
            case .manual: return L10n.manualSync
            case .hourly: return L10n.hourlySync
            case .daily: return L10n.dailySync
            case .realtime: return L10n.realtimeSync
            }
        }
    }

    // MARK: - Permission Management
    func requestCalendarPermission() async -> Bool {
        print("🔐 开始请求日历权限...")

        // 首先检查会员状态
        guard PurchaseManager.shared.isPremiumUnlocked else {
            await MainActor.run {
                self.errorMessage = L10n.systemCalendarRequiresPremium
            }
            return false
        }

        // 检查当前权限状态
        let currentStatus = EKEventStore.authorizationStatus(for: .event)
        print("📱 当前日历权限状态: \(currentStatus)")

        switch currentStatus {
        case .fullAccess:
            print("✅ 已有完整日历访问权限")
            await MainActor.run {
                self.hasCalendarAccess = true
                self.errorMessage = nil
                loadAvailableCalendars()
            }
            return true

        case .denied, .restricted:
            print("❌ 日历权限被拒绝或受限制")
            // 权限已被拒绝，不设置错误消息，让UI处理权限引导
            await MainActor.run {
                self.hasCalendarAccess = false
                self.errorMessage = nil
            }
            return false

        case .notDetermined:
            print("🤔 日历权限未确定，将显示iOS系统权限对话框")
            // 首次请求 - 这会显示iOS原生权限对话框（带日历数据预览）
            do {
                let granted = try await eventStore.requestFullAccessToEvents()
                print("📝 权限请求结果: \(granted)")
                await MainActor.run {
                    self.hasCalendarAccess = granted
                    self.errorMessage = nil
                    if granted {
                        loadAvailableCalendars()
                    }
                }
                return granted
            } catch {
                print("❌ 请求权限时发生错误: \(error)")
                await MainActor.run {
                    self.errorMessage = L10n.calendarPermissionError(error.localizedDescription)
                    self.hasCalendarAccess = false
                }
                return false
            }

        case .writeOnly:
            print("✏️ 当前仅有写入权限，需要请求完整访问权限")
            // 用户之前授予了写入权限，现在请求完整访问权限
            do {
                let granted = try await eventStore.requestFullAccessToEvents()
                print("📝 完整权限请求结果: \(granted)")
                await MainActor.run {
                    self.hasCalendarAccess = granted
                    self.errorMessage = nil
                    if granted {
                        loadAvailableCalendars()
                    }
                }
                return granted
            } catch {
                print("❌ 请求完整权限时发生错误: \(error)")
                await MainActor.run {
                    self.errorMessage = L10n.calendarPermissionError(error.localizedDescription)
                    self.hasCalendarAccess = false
                }
                return false
            }

        @unknown default:
            print("⚠️ 未知的权限状态")
            await MainActor.run {
                self.hasCalendarAccess = false
                self.errorMessage = nil
            }
            return false
        }
    }

    private func checkCalendarAuthorizationStatus() {
        let status = EKEventStore.authorizationStatus(for: .event)
        hasCalendarAccess = status == .fullAccess

        if hasCalendarAccess {
            loadAvailableCalendars()
        }
    }

    private func loadAvailableCalendars() {
        availableCalendars = eventStore.calendars(for: .event)
            .filter { $0.allowsContentModifications }

        // 默认选择所有日历
        if selectedCalendars.isEmpty {
            selectedCalendars = Set(availableCalendars.map { $0.calendarIdentifier })
            print("📅 默认选择所有日历: \(selectedCalendars.count)个")
        }
    }

    // 防止重复同步的标志
    private var isSyncing = false

    // MARK: - Sync Operations
    func performSync() async {
        // 防止重复同步
        if isSyncing {
            print("⚠️ 同步已在进行中，跳过重复请求")
            return
        }

        isSyncing = true
        print("🔄 开始执行同步，方向: \(syncDirection)")

        defer {
            isSyncing = false
            print("🔄 同步流程结束，解锁同步标志")
        }

        // 检查会员状态
        guard PurchaseManager.shared.isPremiumUnlocked else {
            print("❌ 用户不是会员，无法同步")
            errorMessage = L10n.systemCalendarRequiresPremium
            return
        }

        guard hasCalendarAccess else {
            print("❌ 没有日历访问权限，无法同步")
            errorMessage = L10n.calendarPermissionRequired
            return
        }

        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        let eventCountBefore = EventStorageManager.shared.events.count
        print("📊 同步前事件数量: \(eventCountBefore)")

        switch syncDirection {
        case .importOnly:
            await importFromSystemCalendar()
        case .exportOnly:
            await exportToSystemCalendar()
        case .bidirectional:
            await performBidirectionalSync()
        }

        let eventCountAfter = EventStorageManager.shared.events.count
        print("📊 同步后事件数量: \(eventCountAfter)")

        await MainActor.run {
            lastSyncDate = Date()
            saveSettings()
            isLoading = false
        }

        print("✅ 同步完成")
    }

    // 从系统日历导入事件
    private func importFromSystemCalendar() async {
        print("📥 开始从系统日历导入事件...")

        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: Date().addingTimeInterval(-30 * 24 * 3600)) // 30天前
        let endDate = calendar.startOfDay(for: Date().addingTimeInterval(365 * 24 * 3600)) // 1年后

        let selectedCalendars = getSelectedCalendars()
        print("📅 选中的系统日历: \(selectedCalendars.map { $0.title })")
        print("📅 时间范围: \(startDate) 到 \(endDate)")

        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: selectedCalendars)
        let systemEvents = eventStore.events(matching: predicate)

        print("🔍 找到 \(systemEvents.count) 个系统日历事件")

        let storageManager = EventStorageManager.shared
        var importedCount = 0

        for systemEvent in systemEvents {
            let eventTitle = systemEvent.title ?? "无标题"
            let eventDate = systemEvent.startDate
            print("🔍 处理事件: \(eventTitle) - 全天: \(systemEvent.isAllDay) - 日期: \(eventDate?.description ?? "无日期")")

            // 强化去重逻辑：防止循环导入
            // 检查是否已存在相同的事件（多重检查机制）
            let existingEvents = storageManager.events.filter { existingEvent in
                // 第一层检查：系统事件ID匹配
                let hasSystemId = existingEvent.systemCalendarEventID == systemEvent.eventIdentifier

                // 第二层检查：标题完全匹配
                let hasSameTitle = existingEvent.title == eventTitle

                // 第三层检查：时间匹配（最严格的检查）
                var hasSameTime = false

                if systemEvent.isAllDay {
                    // 全天事件：比较日期（不管时间）
                    if let systemStart = systemEvent.startDate {
                        let calendar = Calendar.current

                        // 对于HiCalendar的全天事件（使用intendedDate）
                        if let existingIntended = existingEvent.intendedDate {
                            hasSameTime = calendar.isDate(systemStart, inSameDayAs: existingIntended)
                        }
                        // 对于HiCalendar的有时间事件转全天的情况
                        else if let existingStart = existingEvent.startAt {
                            hasSameTime = calendar.isDate(systemStart, inSameDayAs: existingStart)
                        }
                    }
                } else if let systemStart = systemEvent.startDate {
                    // 有时间的事件：精确时间比较
                    if let existingStart = existingEvent.startAt {
                        let timeDiff = abs(systemStart.timeIntervalSince(existingStart))
                        hasSameTime = timeDiff < 60 // 1分钟内误差
                    }
                } else {
                    // 系统事件没有时间（这种情况很少见）
                    hasSameTime = existingEvent.startAt == nil && existingEvent.intendedDate == nil
                }

                // 多重防护判定：
                // 1. 系统ID匹配 (精确匹配)
                if hasSystemId {
                    return true
                }

                // 2. 标题 + 时间完全匹配 (防止循环导入)
                if hasSameTitle && hasSameTime {
                    // 额外检查：如果现有事件有systemCalendarEventID，说明可能是循环导入
                    if existingEvent.systemCalendarEventID != nil {
                        print("🔄 检测到可能的循环导入: \(eventTitle) - 现有事件已有系统ID")
                        return true
                    }
                    return true
                }

                return false
            }

            print("🔍 去重结果: 找到\(existingEvents.count)个已存在的相同事件")

            if existingEvents.isEmpty {
                // 详细调试全天事件的日期处理
                if systemEvent.isAllDay {
                    let startDate = systemEvent.startDate
                    let calendar = Calendar.current
                    let components = startDate != nil ? calendar.dateComponents([.year, .month, .day, .timeZone], from: startDate!) : nil
                    print("🔍 全天事件详细信息:")
                    print("  原始startDate: \(startDate?.description ?? "nil")")
                    print("  当前时区: \(calendar.timeZone.identifier)")
                    print("  年月日: \(components?.year ?? 0)-\(components?.month ?? 0)-\(components?.day ?? 0)")
                    print("  组件时区: \(components?.timeZone?.identifier ?? "nil")")
                }

                let hiCalendarEvent = Event(
                    title: eventTitle,
                    startAt: systemEvent.isAllDay ? nil : systemEvent.startDate,
                    endAt: systemEvent.isAllDay ? nil : systemEvent.endDate,
                    details: systemEvent.notes,
                    pushReminders: convertSystemReminders(systemEvent.alarms),
                    createdAt: Date(),
                    intendedDate: systemEvent.isAllDay ? systemEvent.startDate : nil,
                    systemCalendarEventID: systemEvent.eventIdentifier,
                    systemCalendarID: systemEvent.calendar.calendarIdentifier,
                    isFromSystemCalendar: true
                )

                // 额外调试导入后的事件信息
                if systemEvent.isAllDay {
                    print("  导入后intendedDate: \(hiCalendarEvent.intendedDate?.description ?? "nil")")
                    if let intendedDate = hiCalendarEvent.intendedDate {
                        let calendar = Calendar.current
                        let components = calendar.dateComponents([.year, .month, .day], from: intendedDate)
                        print("  intendedDate年月日: \(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)")
                    }
                }

                storageManager.addEvent(hiCalendarEvent)
                importedCount += 1
                print("✅ 导入事件: \(hiCalendarEvent.title) - 日期: \(systemEvent.startDate?.description ?? "无日期")")
            } else {
                print("⏭️ 跳过已存在的事件: \(eventTitle) - 日期: \(eventDate?.description ?? "无日期") (已有\(existingEvents.count)个相同实例)")
            }
        }

        print("✅ 从系统日历导入了 \(importedCount) 个事件，总共检查了 \(systemEvents.count) 个事件")
    }

    // 导出到系统日历
    private func exportToSystemCalendar() async {
        let storageManager = EventStorageManager.shared

        // 优先使用HiCalendar专用日历
        let targetCalendar = getOrCreateHiCalendarCalendar() ?? getSelectedCalendars().first ?? eventStore.defaultCalendarForNewEvents

        guard let calendar = targetCalendar else {
            errorMessage = L10n.noCalendarSelected
            return
        }

        print("📤 使用目标日历导出: \(calendar.title) (\(calendar.source.title))")

        var exportedCount = 0

        for event in storageManager.events {
            // 更严格的过滤：跳过已经同步到系统日历的事件
            if event.isFromSystemCalendar {
                print("⏭️ 跳过系统日历来源事件: \(event.title)")
                continue
            }

            if event.systemCalendarEventID != nil {
                print("⏭️ 跳过已导出事件: \(event.title) (系统ID: \(event.systemCalendarEventID ?? "nil"))")
                continue
            }

            // 额外检查：防止导出Onboarding样本事件
            if event.title.contains("🌟") || event.title.contains("🔔") || event.title.contains("🎤") || event.title.contains("🎨") || event.title.contains("😄") || event.title.contains("📬") {
                print("⏭️ 跳过样本引导事件: \(event.title)")
                continue
            }

            let result = await exportSingleEventToSystemCalendar(event: event, targetCalendar: calendar)
            if result {
                exportedCount += 1
            }
        }

        print("✅ 导出了 \(exportedCount) 个事件到系统日历")
    }

    /// 导出最近创建的事件到系统日历（用于实时同步）
    private func exportRecentEventsToSystemCalendar() async {
        let storageManager = EventStorageManager.shared

        // 优先使用HiCalendar专用日历
        let targetCalendar = getOrCreateHiCalendarCalendar() ?? getSelectedCalendars().first ?? eventStore.defaultCalendarForNewEvents

        guard let calendar = targetCalendar else {
            print("❌ 无法获取目标日历")
            return
        }

        print("📤 快速同步使用目标日历: \(calendar.title)")

        // 查找最近5分钟内创建且未同步到系统日历的事件
        let fiveMinutesAgo = Date().addingTimeInterval(-300)
        let recentEvents = storageManager.events.filter { event in
            // 不是系统日历事件，且没有系统日历ID，且是最近创建的
            !event.isFromSystemCalendar &&
            event.systemCalendarEventID == nil &&
            event.createdAt > fiveMinutesAgo
        }

        var exportedCount = 0
        for event in recentEvents {
            let result = await exportSingleEventToSystemCalendar(event: event, targetCalendar: calendar)
            if result {
                exportedCount += 1
            }
        }

        if exportedCount > 0 {
            print("⚡ 快速同步: 导出了 \(exportedCount) 个最近创建的事件到系统日历")
        }
    }

    /// 导出单个事件到系统日历
    private func exportSingleEventToSystemCalendar(event: Event, targetCalendar: EKCalendar) async -> Bool {
        print("🚀 exportSingleEventToSystemCalendar 开始: \(event.title)")
        print("📅 目标日历: \(targetCalendar.title) (\(targetCalendar.calendarIdentifier))")

        let storageManager = EventStorageManager.shared

        let systemEvent = EKEvent(eventStore: eventStore)
        systemEvent.title = event.title
        systemEvent.notes = event.details
        systemEvent.calendar = targetCalendar

        if let startAt = event.startAt {
            systemEvent.startDate = startAt
            systemEvent.endDate = event.endAt ?? startAt.addingTimeInterval(3600) // 默认1小时
            systemEvent.isAllDay = false
            print("⏰ 有时间事件: \(startAt) 到 \(systemEvent.endDate?.description ?? "nil")")
        } else if let intendedDate = event.intendedDate {
            // 全天事件 - 需要将intendedDate转换为本地时区的当天开始时间
            let calendar = Calendar.current
            let dateComponents = calendar.dateComponents([.year, .month, .day], from: intendedDate)

            guard let localStartDate = calendar.date(from: dateComponents) else {
                print("⚠️ 无法创建本地日期，跳过导出: \(event.title)")
                return false
            }

            systemEvent.startDate = localStartDate
            systemEvent.endDate = calendar.date(byAdding: .day, value: 1, to: localStartDate)
            systemEvent.isAllDay = true
            print("📅 全天事件: 原始=\(intendedDate), 本地开始=\(localStartDate)")
        } else {
            print("⚠️ 事件无有效日期，跳过导出: \(event.title)")
            print("  - startAt: \(event.startAt?.description ?? "nil")")
            print("  - intendedDate: \(event.intendedDate?.description ?? "nil")")
            return false
        }

        // 添加提醒
        systemEvent.alarms = convertToSystemAlarms(event.pushReminders, startDate: systemEvent.startDate)
        print("🔔 提醒设置: \(event.pushReminders.map { $0.rawValue })")

        do {
            print("💾 尝试保存到EventStore...")
            try eventStore.save(systemEvent, span: .thisEvent)
            print("✅ EventStore保存成功，系统事件ID: \(systemEvent.eventIdentifier)")

            // 更新HiCalendar事件，记录系统日历ID
            var updatedEvent = event
            updatedEvent.systemCalendarEventID = systemEvent.eventIdentifier
            updatedEvent.systemCalendarID = targetCalendar.calendarIdentifier
            storageManager.updateEvent(updatedEvent)
            print("🔗 已更新HiCalendar事件，关联系统日历ID")

            print("✅ 成功导出事件到系统日历: \(event.title)")
            return true
        } catch {
            print("❌ 导出事件失败: \(event.title) - \(error.localizedDescription)")
            print("❌ 错误详情: \(error)")
            return false
        }
    }

    // 双向同步
    private func performBidirectionalSync() async {
        // 先导入新的系统日历事件
        await importFromSystemCalendar()

        // 再导出新的HiCalendar事件
        await exportToSystemCalendar()

        // 同步已存在事件的更新
        await syncExistingEvents()
    }

    // 同步已存在事件的更新
    private func syncExistingEvents() async {
        let storageManager = EventStorageManager.shared

        for event in storageManager.events {
            guard let systemEventID = event.systemCalendarEventID,
                  let systemEvent = eventStore.event(withIdentifier: systemEventID) else {
                continue
            }

            // 检查是否需要更新
            let needsUpdate = checkIfEventNeedsUpdate(hiCalendarEvent: event, systemEvent: systemEvent)

            if needsUpdate.hiCalendarNeedsUpdate {
                updateHiCalendarEvent(event, from: systemEvent)
            }

            if needsUpdate.systemEventNeedsUpdate {
                updateSystemEvent(systemEvent, from: event)
            }
        }
    }

    // MARK: - Helper Methods

    /// 获取或创建HiCalendar专用日历
    private func getOrCreateHiCalendarCalendar() -> EKCalendar? {
        // 首先查找是否已存在HiCalendar日历
        let existingHiCalendar = availableCalendars.first { $0.title == "HiCalendar" }

        if let existing = existingHiCalendar {
            print("📅 找到现有HiCalendar日历: \(existing.calendarIdentifier)")
            return existing
        }

        // 创建新的HiCalendar日历
        return createHiCalendarCalendar()
    }

    /// 创建HiCalendar专用日历
    private func createHiCalendarCalendar() -> EKCalendar? {
        print("🆕 创建新的HiCalendar日历...")

        // 优先选择iCloud源
        let iCloudSource = eventStore.sources.first {
            $0.sourceType == .calDAV &&
            $0.title.lowercased().contains("icloud")
        }

        let targetSource = iCloudSource ?? eventStore.defaultCalendarForNewEvents?.source

        guard let source = targetSource else {
            print("❌ 无法找到可用的日历源")
            return nil
        }

        let calendar = EKCalendar(for: .event, eventStore: eventStore)
        calendar.title = "HiCalendar"
        calendar.source = source

        // 设置日历颜色为品牌色
        calendar.cgColor = UIColor.systemBlue.cgColor

        do {
            try eventStore.saveCalendar(calendar, commit: true)
            print("✅ 成功创建HiCalendar日历: \(calendar.calendarIdentifier)")

            // 刷新可用日历列表
            loadAvailableCalendars()

            // 自动选择新创建的日历
            selectedCalendars.insert(calendar.calendarIdentifier)
            saveSettings()

            return calendar
        } catch {
            print("❌ 创建HiCalendar日历失败: \(error)")
            return nil
        }
    }

    private func getSelectedCalendars() -> [EKCalendar] {
        // 如果没有选择任何日历，优先使用或创建HiCalendar日历
        if selectedCalendars.isEmpty {
            print("📅 未选择特定日历，使用或创建HiCalendar专用日历")

            if let hiCalendar = getOrCreateHiCalendarCalendar() {
                print("📅 使用HiCalendar专用日历: \(hiCalendar.title)")
                return [hiCalendar]
            }

            // 备选：优先选择iCloud日历（能同步到所有设备）
            let iCloudCalendars = availableCalendars.filter {
                $0.source.sourceType == .calDAV &&
                $0.source.title.lowercased().contains("icloud")
            }

            if !iCloudCalendars.isEmpty {
                print("☁️ 找到 \(iCloudCalendars.count) 个iCloud日历: \(iCloudCalendars.map { $0.title })")
                return iCloudCalendars
            }

            // 备选：使用默认日历
            if let defaultCalendar = eventStore.defaultCalendarForNewEvents {
                print("📅 使用默认日历: \(defaultCalendar.title)")
                return [defaultCalendar]
            }

            // 最后选择：使用所有可用日历
            print("📅 使用所有可用日历")
            return availableCalendars
        }

        let filtered = availableCalendars.filter { selectedCalendars.contains($0.calendarIdentifier) }
        print("📅 已选择 \(filtered.count) 个日历: \(filtered.map { "\($0.title) (\($0.source.title))" })")
        return filtered
    }

    private func convertSystemReminders(_ alarms: [EKAlarm]?) -> [PushReminderOption] {
        guard let alarms = alarms else { return [] }

        var reminders: [PushReminderOption] = []

        for alarm in alarms {
            let offset = alarm.relativeOffset
            switch Int(offset) {
            case 0: reminders.append(.atTime)
            case -900: reminders.append(.minutes15) // -15 minutes
            case -1800: reminders.append(.minutes30) // -30 minutes
            case -3600: reminders.append(.hours1) // -1 hour
            case -7200: reminders.append(.hours2) // -2 hours
            case -86400: reminders.append(.dayBefore) // -1 day
            case -604800: reminders.append(.weekBefore) // -1 week
            default: break
            }
        }

        return reminders.isEmpty ? [.dayBefore] : reminders
    }

    private func convertToSystemAlarms(_ reminders: [PushReminderOption], startDate: Date) -> [EKAlarm] {
        return reminders.compactMap { reminder in
            let offset = reminder.timeOffsetSeconds
            return EKAlarm(relativeOffset: offset)
        }
    }

    private func checkIfEventNeedsUpdate(hiCalendarEvent: Event, systemEvent: EKEvent) -> (hiCalendarNeedsUpdate: Bool, systemEventNeedsUpdate: Bool) {
        let hiTitle = hiCalendarEvent.title
        let systemTitle = systemEvent.title ?? ""
        let titleDifferent = hiTitle != systemTitle

        let hiStart = hiCalendarEvent.startAt
        let systemStart = systemEvent.isAllDay ? nil : systemEvent.startDate
        let startDifferent = hiStart != systemStart

        // 简化版本：如果标题或开始时间不同就需要更新
        // 实际应用中可能需要更复杂的冲突解决逻辑
        let needsUpdate = titleDifferent || startDifferent

        return (needsUpdate, needsUpdate)
    }

    private func updateHiCalendarEvent(_ event: Event, from systemEvent: EKEvent) {
        var updatedEvent = event
        updatedEvent.title = systemEvent.title ?? event.title
        updatedEvent.details = systemEvent.notes

        if systemEvent.isAllDay {
            updatedEvent.startAt = nil
            updatedEvent.endAt = nil
            updatedEvent.intendedDate = systemEvent.startDate
        } else {
            updatedEvent.startAt = systemEvent.startDate
            updatedEvent.endAt = systemEvent.endDate
            updatedEvent.intendedDate = nil
        }

        EventStorageManager.shared.updateEvent(updatedEvent)
    }

    private func updateSystemEvent(_ systemEvent: EKEvent, from hiCalendarEvent: Event) {
        systemEvent.title = hiCalendarEvent.title
        systemEvent.notes = hiCalendarEvent.details

        if let startAt = hiCalendarEvent.startAt {
            systemEvent.startDate = startAt
            systemEvent.endDate = hiCalendarEvent.endAt ?? startAt.addingTimeInterval(3600)
            systemEvent.isAllDay = false
        } else if let intendedDate = hiCalendarEvent.intendedDate {
            systemEvent.startDate = intendedDate
            systemEvent.endDate = intendedDate.addingTimeInterval(24 * 3600)
            systemEvent.isAllDay = true
        }

        do {
            try eventStore.save(systemEvent, span: .thisEvent)
        } catch {
            print("❌ 更新系统事件失败: \(error)")
        }
    }

    // MARK: - Settings Persistence
    private func loadSettings() {
        syncEnabled = UserDefaults.standard.bool(forKey: "SystemCalendarSyncEnabled")
        lastSyncDate = UserDefaults.standard.object(forKey: "LastSystemCalendarSync") as? Date

        if let directionRaw = UserDefaults.standard.string(forKey: "SystemCalendarSyncDirection"),
           let direction = SyncDirection(rawValue: directionRaw) {
            syncDirection = direction
        }

        if let frequencyRaw = UserDefaults.standard.string(forKey: "SystemCalendarSyncFrequency"),
           let frequency = SyncFrequency(rawValue: frequencyRaw) {
            syncFrequency = frequency
        }

        if let savedCalendars = UserDefaults.standard.array(forKey: "SelectedSystemCalendars") as? [String] {
            selectedCalendars = Set(savedCalendars)
        }
    }

    private func saveSettings() {
        UserDefaults.standard.set(syncEnabled, forKey: "SystemCalendarSyncEnabled")
        UserDefaults.standard.set(lastSyncDate, forKey: "LastSystemCalendarSync")
        UserDefaults.standard.set(syncDirection.rawValue, forKey: "SystemCalendarSyncDirection")
        UserDefaults.standard.set(syncFrequency.rawValue, forKey: "SystemCalendarSyncFrequency")
        UserDefaults.standard.set(Array(selectedCalendars), forKey: "SelectedSystemCalendars")

        // 设置更改后重新设置定时器
        if syncEnabled && hasCalendarAccess {
            setupTimerSync()
        }
    }

    // MARK: - Public Interface
    func enableSync() async {
        print("🚀 开始启用系统日历同步...")

        // 检查会员状态
        guard PurchaseManager.shared.isPremiumUnlocked else {
            print("❌ 用户不是会员，无法启用系统日历同步")
            await MainActor.run {
                self.errorMessage = L10n.systemCalendarRequiresPremium
            }
            return
        }

        // 检查权限状态
        guard hasCalendarAccess else {
            print("❌ 没有日历访问权限，无法启用同步")
            await MainActor.run {
                self.errorMessage = L10n.calendarPermissionRequired
            }
            return
        }

        print("✅ 会员状态和权限检查通过，启用同步...")
        syncEnabled = true
        saveSettings()

        print("📊 当前设置 - 同步方向: \(syncDirection), 同步频率: \(syncFrequency), 选中日历数: \(selectedCalendars.count)")

        // 设置定时器同步
        setupTimerSync()

        // 立即执行一次同步，不管频率设置
        print("🔄 执行首次同步...")
        await performSync()
    }

    var isPremiumFeature: Bool {
        return !PurchaseManager.shared.isPremiumUnlocked
    }

    func disableSync() {
        print("🛑 禁用系统日历同步...")
        syncEnabled = false
        stopTimerSync() // 停止定时器
        saveSettings()
        print("✅ 系统日历同步已禁用")
    }

    func toggleCalendarSelection(_ calendar: EKCalendar) {
        if selectedCalendars.contains(calendar.calendarIdentifier) {
            selectedCalendars.remove(calendar.calendarIdentifier)
        } else {
            selectedCalendars.insert(calendar.calendarIdentifier)
        }
        saveSettings()
    }

    /// 手动创建HiCalendar专用日历（供UI调用）
    @discardableResult
    func createHiCalendarDedicatedCalendar() async -> Bool {
        print("🎯 用户手动创建HiCalendar专用日历")

        guard hasCalendarAccess else {
            errorMessage = L10n.calendarPermissionRequired
            return false
        }

        guard PurchaseManager.shared.isPremiumUnlocked else {
            errorMessage = L10n.systemCalendarRequiresPremium
            return false
        }

        // 检查是否已存在
        let existingCalendar = availableCalendars.first { $0.title == "HiCalendar" }
        if existingCalendar != nil {
            print("📅 HiCalendar日历已存在")
            errorMessage = "HiCalendar日历已存在"
            return false
        }

        if let newCalendar = createHiCalendarCalendar() {
            print("✅ 成功创建HiCalendar专用日历")

            // 清除旧的日历选择，优先使用新创建的HiCalendar日历
            selectedCalendars.removeAll()
            selectedCalendars.insert(newCalendar.calendarIdentifier)
            saveSettings()

            print("📅 已设置HiCalendar为默认同步日历")
            return true
        } else {
            errorMessage = "创建HiCalendar日历失败"
            return false
        }
    }

    /// 强制切换到HiCalendar专用日历（解决现有Work日历问题）
    func switchToHiCalendarOnly() async -> Bool {
        print("🔄 强制切换到HiCalendar专用日历...")

        guard hasCalendarAccess else {
            errorMessage = L10n.calendarPermissionRequired
            return false
        }

        guard PurchaseManager.shared.isPremiumUnlocked else {
            errorMessage = L10n.systemCalendarRequiresPremium
            return false
        }

        // 获取或创建HiCalendar日历
        guard let hiCalendar = getOrCreateHiCalendarCalendar() else {
            errorMessage = "无法获取HiCalendar日历"
            return false
        }

        // 清除所有旧的日历选择
        selectedCalendars.removeAll()
        selectedCalendars.insert(hiCalendar.calendarIdentifier)
        saveSettings()

        print("✅ 已强制切换到HiCalendar专用日历")
        print("📅 新的默认日历: \(hiCalendar.title) (\(hiCalendar.source.title))")

        return true
    }

    /// 清理系统日历循环导入的重复事件
    func cleanupSystemCalendarDuplicates() async {
        print("🧹 开始清理系统日历循环导入的重复事件...")

        let storageManager = EventStorageManager.shared
        var cleanedCount = 0

        // 找出所有可能的重复事件组
        var eventGroups: [String: [Event]] = [:]

        for event in storageManager.events {
            let calendar = Calendar.current
            var dateKey = ""

            if let startAt = event.startAt {
                let components = calendar.dateComponents([.year, .month, .day], from: startAt)
                dateKey = "\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)"
            } else if let intendedDate = event.intendedDate {
                let components = calendar.dateComponents([.year, .month, .day], from: intendedDate)
                dateKey = "\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)"
            }

            let groupKey = "\(event.title.lowercased())-\(dateKey)"
            if eventGroups[groupKey] == nil {
                eventGroups[groupKey] = []
            }
            eventGroups[groupKey]?.append(event)
        }

        var eventsToKeep: [Event] = []

        // 处理每个重复组
        for (groupKey, events) in eventGroups {
            if events.count > 1 {
                print("🔍 发现重复组 '\(groupKey)': \(events.count) 个事件")

                // 优先级排序：
                // 1. 原生HiCalendar事件 (systemCalendarEventID == nil && !isFromSystemCalendar)
                // 2. 有系统ID的事件 (systemCalendarEventID != nil)
                // 3. 系统日历导入的事件 (isFromSystemCalendar)
                let sortedEvents = events.sorted { first, second in
                    // 原生HiCalendar事件优先级最高
                    let firstIsNative = first.systemCalendarEventID == nil && !first.isFromSystemCalendar
                    let secondIsNative = second.systemCalendarEventID == nil && !second.isFromSystemCalendar

                    if firstIsNative && !secondIsNative {
                        return true
                    }
                    if !firstIsNative && secondIsNative {
                        return false
                    }

                    // 其次是有系统ID的事件
                    if first.systemCalendarEventID != nil && second.systemCalendarEventID == nil {
                        return true
                    }
                    if first.systemCalendarEventID == nil && second.systemCalendarEventID != nil {
                        return false
                    }

                    // 最后按创建时间排序
                    return first.createdAt < second.createdAt
                }

                // 保留优先级最高的事件
                let eventToKeep = sortedEvents[0]
                eventsToKeep.append(eventToKeep)

                // 删除系统日历中的重复事件
                for duplicateEvent in sortedEvents.dropFirst() {
                    if let systemEventID = duplicateEvent.systemCalendarEventID,
                       let systemEvent = eventStore.event(withIdentifier: systemEventID) {
                        do {
                            try eventStore.remove(systemEvent, span: .thisEvent)
                            print("🗑️ 已从系统日历删除重复事件: \(duplicateEvent.title)")
                        } catch {
                            print("❌ 删除系统日历事件失败: \(error)")
                        }
                    }
                }

                cleanedCount += events.count - 1
                print("✅ 清理重复组: 保留 '\(eventToKeep.title)'，删除 \(events.count - 1) 个重复")
            } else {
                eventsToKeep.append(events[0])
            }
        }

        if cleanedCount > 0 {
            // 重新设置事件列表（通过清空再批量添加来保存）
            storageManager.events.removeAll()
            for event in eventsToKeep {
                storageManager.events.append(event)
            }

            // 手动触发保存
            UserDefaults.standard.set(try? JSONEncoder().encode(eventsToKeep), forKey: "HiCalendarEvents")

            print("✅ 清理完成：删除了 \(cleanedCount) 个重复事件")
        } else {
            print("✅ 没有发现重复事件")
        }
    }

    /// 清理重复事件（供外部调用）
    func cleanupDuplicateEvents() {
        let storageManager = EventStorageManager.shared
        var eventsToKeep: [Event] = []
        var duplicateGroups: [String: [Event]] = [:]

        // 按标题+日期分组
        for event in storageManager.events {
            let calendar = Calendar.current
            var dateKey = ""

            if let startAt = event.startAt {
                let components = calendar.dateComponents([.year, .month, .day], from: startAt)
                dateKey = "\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)"
            } else if let intendedDate = event.intendedDate {
                let components = calendar.dateComponents([.year, .month, .day], from: intendedDate)
                dateKey = "\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)"
            }

            let key = "\(event.title)-\(dateKey)"

            if duplicateGroups[key] == nil {
                duplicateGroups[key] = []
            }
            duplicateGroups[key]?.append(event)
        }

        var cleanedCount = 0

        // 保留每组的第一个事件，删除重复的
        for (_, events) in duplicateGroups {
            if events.count > 1 {
                // 优先保留有systemCalendarEventID的事件
                let sortedEvents = events.sorted { first, second in
                    if first.systemCalendarEventID != nil && second.systemCalendarEventID == nil {
                        return true
                    }
                    if first.systemCalendarEventID == nil && second.systemCalendarEventID != nil {
                        return false
                    }
                    return first.createdAt < second.createdAt // 保留最早创建的
                }

                eventsToKeep.append(sortedEvents[0])
                cleanedCount += events.count - 1

                print("🧹 清理重复事件: \(events[0].title) - 保留1个，删除\(events.count - 1)个")
            } else {
                eventsToKeep.append(events[0])
            }
        }

        if cleanedCount > 0 {
            // 重新设置事件列表（通过清空再批量添加来保存）
            storageManager.events.removeAll()
            for event in eventsToKeep {
                storageManager.events.append(event)
            }

            // 手动触发保存
            UserDefaults.standard.set(try? JSONEncoder().encode(eventsToKeep), forKey: "HiCalendarEvents")

            print("✅ 清理完成：删除了 \(cleanedCount) 个重复事件")
        } else {
            print("✅ 没有发现重复事件")
        }
    }

    /// 立即导出单个事件到系统日历（供外部调用）
    func exportEventToSystemCalendar(_ event: Event) async -> Bool {
        print("📤 exportEventToSystemCalendar 开始检查: \(event.title)")

        // 检查权限和设置
        print("🔍 权限检查: hasCalendarAccess=\(hasCalendarAccess), syncEnabled=\(syncEnabled), syncDirection=\(syncDirection)")
        guard hasCalendarAccess,
              syncEnabled,
              (syncDirection == .bidirectional || syncDirection == .exportOnly) else {
            print("⏸️ 系统日历同步未启用或不支持导出")
            print("  - hasCalendarAccess: \(hasCalendarAccess)")
            print("  - syncEnabled: \(syncEnabled)")
            print("  - syncDirection: \(syncDirection)")
            return false
        }

        // 检查会员状态
        let isPremium = PurchaseManager.shared.isPremiumUnlocked
        print("💰 会员状态检查: isPremium=\(isPremium)")
        guard isPremium else {
            print("💰 非会员用户，无法导出到系统日历")
            return false
        }

        // 跳过已有系统日历ID的事件
        print("🔍 事件状态检查: systemCalendarEventID=\(event.systemCalendarEventID ?? "nil"), isFromSystemCalendar=\(event.isFromSystemCalendar)")
        guard event.systemCalendarEventID == nil && !event.isFromSystemCalendar else {
            print("⏸️ 事件已存在于系统日历中，跳过导出: \(event.title)")
            return false
        }

        // 优先使用HiCalendar专用日历
        let targetCalendar = getOrCreateHiCalendarCalendar() ?? getSelectedCalendars().first ?? eventStore.defaultCalendarForNewEvents
        print("📅 目标日历: \(targetCalendar?.title ?? "nil") (\(targetCalendar?.source.title ?? "nil"))")
        guard let calendar = targetCalendar else {
            print("❌ 无法获取目标日历")
            return false
        }

        print("🔄 正在导出单个事件到系统日历: \(event.title)")
        let result = await exportSingleEventToSystemCalendar(event: event, targetCalendar: calendar)
        print("📤 导出结果: \(result ? "成功" : "失败")")
        return result
    }
}