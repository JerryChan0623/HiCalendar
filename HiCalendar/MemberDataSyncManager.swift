//
//  MemberDataSyncManager.swift
//  HiCalendar
//
//  会员数据同步管理器 - 确保会员用户数据不丢失
//

import Foundation
import Combine
import UIKit

@MainActor
class MemberDataSyncManager: ObservableObject {
    static let shared = MemberDataSyncManager()

    @Published var syncStatus: SyncStatus = .idle
    @Published var lastSyncDate: Date?
    @Published var syncProgress: Double = 0.0
    @Published var errorMessage: String?

    private let supabaseManager = SupabaseManager.shared
    private let eventManager = EventStorageManager.shared
    private var cancellables = Set<AnyCancellable>()

    enum SyncStatus {
        case idle
        case syncing
        case completed
        case failed
    }

    struct SyncResult {
        let success: Bool
        let eventsUploaded: Int
        let eventsDownloaded: Int
        let errorMessage: String?
    }

    private init() {
        loadLastSyncDate()

        // 监听应用进入前台时触发同步
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { _ in
                Task {
                    await self.scheduleAutoSync()
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - 核心同步方法

    /// 完整数据同步（会员登录时调用）
    func performFullSync() async -> SyncResult {
        print("🔄 开始执行完整数据同步...")
        syncStatus = .syncing
        syncProgress = 0.0
        errorMessage = nil

        // 1. 检查用户会员状态（使用本地购买状态）
        let isPremium = await MainActor.run {
            PurchaseManager.shared.isPremiumUnlocked
        }
        guard isPremium else {
            print("⚠️ 用户不是会员，跳过数据同步")
            syncStatus = .completed
            return SyncResult(success: true, eventsUploaded: 0, eventsDownloaded: 0, errorMessage: nil)
        }

        syncProgress = 0.1

        // 2. 上传本地数据到云端
        let uploadResult = await uploadLocalDataToCloud()
        syncProgress = 0.5

        // 3. 从云端下载数据
        let downloadResult = await downloadCloudDataToLocal()
        syncProgress = 0.9

        // 4. 更新最后同步时间
        updateLastSyncDate()
        syncProgress = 1.0
        syncStatus = .completed

        print("✅ 完整数据同步完成")
        return SyncResult(
            success: true,
            eventsUploaded: uploadResult,
            eventsDownloaded: downloadResult,
            errorMessage: nil
        )
    }

    /// 增量同步（定期调用）
    func performIncrementalSync() async -> SyncResult {
        print("🔄 开始执行增量数据同步...")

        // 检查用户会员状态（使用本地购买状态）
        let isPremium = await MainActor.run {
            PurchaseManager.shared.isPremiumUnlocked
        }
        guard isPremium else {
            return SyncResult(success: true, eventsUploaded: 0, eventsDownloaded: 0, errorMessage: nil)
        }

        // 只同步未同步的本地数据，过滤掉onboarding事项
        let unsyncedEvents = eventManager.events.filter { !$0.isSynced && !$0.isOnboarding }

        var uploadCount = 0
        for event in unsyncedEvents {
            let success = await syncEventToCloud(event)
            if success {
                // 标记为已同步
                var updatedEvent = event
                updatedEvent.isSynced = true
                eventManager.updateEvent(updatedEvent)
                uploadCount += 1
            }
        }

        // 下载云端新数据
        let downloadCount = await downloadRecentCloudData()

        updateLastSyncDate()

        print("✅ 增量同步完成: 上传\(uploadCount)个，下载\(downloadCount)个")
        return SyncResult(success: true, eventsUploaded: uploadCount, eventsDownloaded: downloadCount, errorMessage: nil)
    }

    // MARK: - 数据备份和恢复

    /// 创建完整数据备份
    func createBackup() async -> Bool {
        do {
            guard let currentUser = await supabaseManager.getCurrentUser(),
                  currentUser.isMember else {
                print("⚠️ 非会员用户无法创建云端备份")
                return false
            }

            // 调用Edge Function创建备份
            let url = URL(string: "\(supabaseManager.supabaseURL)/functions/v1/member-data-sync?action=backup")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("Bearer \(supabaseManager.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")

            let body = ["user_id": currentUser.id.uuidString]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)

            let (_, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                print("✅ 数据备份创建成功")
                return true
            } else {
                print("❌ 备份创建失败")
                return false
            }
        } catch {
            print("❌ 备份创建异常: \(error)")
            return false
        }
    }

    /// 从备份恢复数据
    func restoreFromBackup(backupData: [String: Any]) async -> Bool {
        do {
            guard let currentUser = await supabaseManager.getCurrentUser(),
                  currentUser.isMember else {
                print("⚠️ 非会员用户无法恢复备份")
                return false
            }

            // 调用Edge Function恢复数据
            let url = URL(string: "\(supabaseManager.supabaseURL)/functions/v1/member-data-sync?action=restore")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("Bearer \(supabaseManager.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")

            let body: [String: Any] = [
                "user_id": currentUser.id.uuidString,
                "backup_data": backupData
            ]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)

            let (_, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                // 重新加载本地数据
                eventManager.loadEvents()
                print("✅ 数据恢复成功")
                return true
            } else {
                print("❌ 数据恢复失败")
                return false
            }
        } catch {
            print("❌ 数据恢复异常: \(error)")
            return false
        }
    }

    // MARK: - 私有方法

    private func uploadLocalDataToCloud() async -> Int {
        var uploadCount = 0

        // 过滤掉onboarding事项，只同步真实的用户事项
        let eventsToSync = eventManager.events.filter { !$0.isOnboarding }
        print("📤 需要上传的事项数量: \(eventsToSync.count)（已过滤\(eventManager.events.count - eventsToSync.count)个onboarding事项）")

        for event in eventsToSync {
            let success = await syncEventToCloud(event)
            if success {
                uploadCount += 1
                // 标记为已同步
                var updatedEvent = event
                updatedEvent.isSynced = true
                eventManager.updateEvent(updatedEvent)
            }
        }

        return uploadCount
    }

    private func downloadCloudDataToLocal() async -> Int {
        // 实现从云端下载数据逻辑
        // 这里调用SupabaseManager的方法获取云端事件
        let cloudEvents = await supabaseManager.fetchAllEvents()
        var downloadCount = 0

        for cloudEvent in cloudEvents {
            // 检查本地是否已存在
            let exists = eventManager.events.contains { $0.id == cloudEvent.id }
            if !exists {
                eventManager.addEvent(cloudEvent)
                downloadCount += 1
            } else {
                // 更新已存在的事件（以云端为准）
                eventManager.updateEvent(cloudEvent)
            }
        }

        return downloadCount
    }

    private func downloadRecentCloudData() async -> Int {
        // 只下载最近更新的数据
        guard lastSyncDate != nil else {
            return await downloadCloudDataToLocal()
        }

        // 实现增量下载逻辑
        return 0
    }

    private func syncEventToCloud(_ event: Event) async -> Bool {
        // 检查用户认证状态
        guard supabaseManager.isAuthenticated,
              let userId = supabaseManager.currentUser?.id else {
            print("❌ 用户未认证，无法同步事项到云端")
            return false
        }

        // 调用SupabaseManager的同步方法
        return await supabaseManager.syncSingleEventWithRetry(event: event, userId: userId.uuidString)
    }

    private func scheduleAutoSync() async {
        // 对于会员用户，每隔一段时间自动同步
        let isPremium = await MainActor.run {
            PurchaseManager.shared.isPremiumUnlocked
        }
        guard isPremium else {
            return
        }

        // 如果距离上次同步超过1小时，执行增量同步
        if let lastSync = lastSyncDate,
           Date().timeIntervalSince(lastSync) > 3600 { // 1小时
            _ = await performIncrementalSync()
        }
    }

    private func loadLastSyncDate() {
        if let timestamp = UserDefaults.standard.object(forKey: "LastMemberSyncDate") as? Date {
            lastSyncDate = timestamp
        }
    }

    private func updateLastSyncDate() {
        lastSyncDate = Date()
        UserDefaults.standard.set(lastSyncDate, forKey: "LastMemberSyncDate")
    }
}

// MARK: - 扩展方法
extension MemberDataSyncManager {

    /// 检查会员状态是否过期
    func checkMembershipExpiry() async -> Bool {
        guard let currentUser = await supabaseManager.getCurrentUser() else {
            return false
        }

        if currentUser.isMember {
            if let expiryDate = currentUser.membershipExpiresAt {
                return Date() > expiryDate
            }
            return false // 永久会员
        }

        return true // 非会员视为过期
    }

    /// 获取同步统计信息
    func getSyncStats() -> (localEvents: Int, lastSync: Date?, isUpToDate: Bool) {
        let localEvents = eventManager.events.count
        let isUpToDate = lastSyncDate != nil &&
                        Date().timeIntervalSince(lastSyncDate!) < 3600 // 1小时内

        return (localEvents, lastSyncDate, isUpToDate)
    }
}