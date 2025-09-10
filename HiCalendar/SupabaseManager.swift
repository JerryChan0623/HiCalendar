//
//  SupabaseManager.swift
//  HiCalendar
//
//  Created on 2024. Supabase Authentication Manager
//

import Foundation
import SwiftUI
import AuthenticationServices
import Network

// MARK: - 真实的Supabase实现（需要先添加Supabase包）
 import Supabase

// MARK: - 真实的Supabase实现
class SupabaseManager: ObservableObject {
    static let shared = SupabaseManager()
    
    let client: SupabaseClient
    private let networkMonitor = NWPathMonitor()
    private let networkQueue = DispatchQueue(label: "NetworkMonitor")
    
    @Published var isAuthenticated = false
    @Published var currentUser: Auth.User? = nil // 使用Supabase的User类型
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var isNetworkAvailable = true
    
    private init() {
        // 创建配置更宽松的URLSessionConfiguration
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = 30.0  // 请求超时30秒
        sessionConfig.timeoutIntervalForResource = 60.0 // 资源超时60秒
        sessionConfig.waitsForConnectivity = true       // 等待网络连接
        sessionConfig.requestCachePolicy = .reloadIgnoringLocalCacheData
        
        // 注意：当前Supabase Swift SDK暂不支持自定义URLSession配置
        // let customSession = URLSession(configuration: sessionConfig)
        
        self.client = SupabaseClient(
            supabaseURL: URL(string: SupabaseConfig.projectURL)!,
            supabaseKey: SupabaseConfig.anonKey
        )
        
        // 启动网络监控
        startNetworkMonitoring()
        
        // 应用启动时检查现有会话
        Task {
            await checkSession()
        }
    }
    
    // 检查当前会话
    @MainActor
    func checkSession() async {
        isLoading = true
        do {
            print("🔍 开始检查Supabase会话...")
            let session = try await client.auth.session
            self.currentUser = session.user
            self.isAuthenticated = true
            
            // 同步本地状态
            UserDefaults.standard.set(true, forKey: "isLoggedIn")
            if let email = session.user.email {
                UserDefaults.standard.set(email, forKey: "userEmail")
            }
            
            print("✅ 已登录用户: \(session.user.id)")
            print("✅ 用户邮箱: \(session.user.email ?? "无")")
            
            // 登录成功后，同步所有本地事项到Supabase
            Task {
                await syncAllLocalEventsToSupabase()
            }
        } catch {
            self.isAuthenticated = false
            self.currentUser = nil
            UserDefaults.standard.set(false, forKey: "isLoggedIn")
            print("❌ 未登录或会话已过期: \(error.localizedDescription)")
            print("❌ 错误详情: \(error)")
        }
        isLoading = false
    }
    
    // Apple登录
    @MainActor
    func signInWithApple(idToken: String, nonce: String) async throws {
        isLoading = true
        errorMessage = nil
        
        print("🍎 开始Apple登录流程...")
        print("🔑 ID Token: \(idToken.prefix(20))...")
        print("🔐 Nonce: \(nonce.prefix(10))...")
        
        do {
            let session = try await client.auth.signInWithIdToken(
                credentials: .init(
                    provider: .apple,
                    idToken: idToken,
                    nonce: nonce
                )
            )
            
            self.currentUser = session.user
            self.isAuthenticated = true
            
            // 保存登录状态到本地
            UserDefaults.standard.set(true, forKey: "isLoggedIn")
            if let email = session.user.email {
                UserDefaults.standard.set(email, forKey: "userEmail")
            }
            
            isLoading = false
            print("✅ Apple登录成功: \(session.user.id)")
            print("✅ 用户邮箱: \(session.user.email ?? "无")")
            
            // Apple登录成功后，同步所有本地事项到Supabase
            Task {
                await syncAllLocalEventsToSupabase()
            }
        } catch {
            isLoading = false
            let translatedError = translateError(error)
            errorMessage = translatedError
            print("❌ Apple登录失败: \(error)")
            print("❌ 详细错误信息: \(error.localizedDescription)")
            print("❌ 翻译后的错误: \(translatedError)")
            throw error
        }
    }
    
    // 登出
    @MainActor
    func signOut() async throws {
        do {
            try await client.auth.signOut()
            self.currentUser = nil
            self.isAuthenticated = false
            
            // 清除本地状态
            UserDefaults.standard.set(false, forKey: "isLoggedIn")
            UserDefaults.standard.removeObject(forKey: "userEmail")
            
            print("✅ 用户已登出")
        } catch {
            errorMessage = "登出失败: \(error.localizedDescription)"
            print("❌ 登出失败: \(error)")
            throw error
        }
    }
    
    // 错误信息本地化
    private func translateError(_ error: Error) -> String {
        let errorString = error.localizedDescription.lowercased()
        
        if errorString.contains("authentication") {
            return "认证失败，请重试"
        } else if errorString.contains("network") {
            return "网络连接失败，请检查网络"
        } else if errorString.contains("invalid") {
            return "无效的登录信息"
        } else if errorString.contains("unauthorized") {
            return "未授权，请重新登录"
        } else {
            return "操作失败: \(error.localizedDescription)"
        }
    }
    
    // MARK: - 同步本地事项到Supabase
    
    /// 同步所有本地事项到Supabase（登录成功后调用）
    @MainActor
    private func syncAllLocalEventsToSupabase() async {
        guard isAuthenticated, let userId = currentUser?.id else {
            print("❌ 用户未认证，跳过批量同步")
            return
        }
        
        print("🔄 开始批量同步本地事项到Supabase...")
        
        // 获取所有本地事项
        let eventManager = EventStorageManager.shared
        let localEvents = eventManager.events
        
        // 首先检查哪些事项已经存在于Supabase中，避免重复同步
        let existingEventIds = await getExistingEventIds(for: userId.uuidString)
        // 修复：将已存在于远端的本地事件标记为已同步，避免误判
        for ev in localEvents where existingEventIds.contains(ev.id.uuidString) {
            EventStorageManager.shared.markEventAsSynced(ev.id)
        }
        let needSyncEvents = localEvents.filter { !existingEventIds.contains($0.id.uuidString) }
        
        print("📊 本地共有 \(localEvents.count) 个事项，其中 \(existingEventIds.count) 个已存在，需要同步 \(needSyncEvents.count) 个")
        
        if needSyncEvents.isEmpty {
            print("✅ 所有本地事项已同步，无需操作")
            return
        }
        
        var syncedCount = 0
        var failedCount = 0
        
        // 逐个同步事项到Supabase（带重试机制）
        for event in needSyncEvents {
            // 先查远端是否已存在等价事项，若存在则本地绑定该ID并标记为已同步
            if let dupId = await findDuplicateRemoteEventId(for: event, userId: userId.uuidString),
               let dupUUID = UUID(uuidString: dupId) {
                EventStorageManager.shared.replaceEventId(oldId: event.id, newId: dupUUID)
                continue
            }

            let success = await syncSingleEventWithRetry(event: event, userId: userId.uuidString, maxRetries: 3)
            if success {
                syncedCount += 1
            } else {
                failedCount += 1
            }
        }
        
        print("🎉 批量同步完成：成功 \(syncedCount) 个，失败 \(failedCount) 个")
    }
    
    /// 获取Supabase中已存在的事项ID列表
    private func getExistingEventIds(for userId: String) async -> Set<String> {
        do {
            let response: [EventIdOnly] = try await client
                .from("events")
                .select("id")
                .eq("user_id", value: userId)
                .execute()
                .value
            
            let existingIds = Set(response.map { $0.id })
            print("📋 Supabase中已有 \(existingIds.count) 个事项")
            return existingIds
        } catch {
            print("⚠️ 获取已存在事项失败，将尝试同步所有本地事项: \(error)")
            return Set<String>()
        }
    }

    /// 若远端已存在“相同内容”的事项，则返回其ID，用于避免重复插入
    private func findDuplicateRemoteEventId(for event: Event, userId: String) async -> String? {
        do {
            var query = client
                .from("events")
                .select("id,title,start_at,intended_date")
                .eq("user_id", value: userId)
                .eq("title", value: event.title)

            if let startAt = event.startAt {
                query = query.eq("start_at", value: startAt.ISO8601Format())
            } else if let intended = event.intendedDate {
                var utcCalendar = Calendar(identifier: .gregorian)
                utcCalendar.timeZone = TimeZone(identifier: "UTC")!
                let comps = Calendar.current.dateComponents([.year, .month, .day], from: intended)
                let utcMidnight = utcCalendar.date(from: comps)!
                query = query.eq("intended_date", value: utcMidnight.ISO8601Format())
            } else {
                // 没有时间字段时，无法可靠匹配
            }

            struct RemoteRow: Codable { let id: String }
            let rows: [RemoteRow] = try await query.limit(1).execute().value
            return rows.first?.id
        } catch {
            print("⚠️ 查重失败，忽略：\(error)")
            return nil
        }
    }
    
    /// 带重试机制的单个事项同步
    private func syncSingleEventWithRetry(event: Event, userId: String, maxRetries: Int = 3) async -> Bool {
        // 首先检查网络连通性
        if !(await waitForNetworkConnection()) {
            print("❌ 网络不可用，跳过同步: \(event.title)")
            return false
        }
        
        var retryCount = 0
        
        while retryCount <= maxRetries {
            do {
                // 使用新字段结构同步
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
                }
                
                let eventData = EventDataWithReminders(
                    id: event.id.uuidString,
                    user_id: userId,
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
                    },  // 修复：正确处理intended_date的时区转换
                    push_reminders: event.pushReminders.map { $0.rawValue },
                    push_day_before: event.pushDayBefore,
                    push_week_before: event.pushWeekBefore,
                    push_status: [
                        "day_before_sent": event.pushStatus.dayBeforeSent,
                        "week_before_sent": event.pushStatus.weekBeforeSent
                    ],
                    created_at: event.createdAt.ISO8601Format()
                )
                
                try await client
                    .from("events")
                    .upsert(eventData)
                    .execute()
                
                print("✅ 同步成功: \(event.title)")
                // 成功后立即标记本地为已同步
                await MainActor.run {
                    EventStorageManager.shared.markEventAsSynced(event.id)
                }
                return true
                
            } catch {
                retryCount += 1
                let isNetworkError = (error as NSError).domain == NSURLErrorDomain
                
                if retryCount <= maxRetries && isNetworkError {
                    let delay = TimeInterval(retryCount * 2) // 递增延迟：2秒、4秒、6秒
                    print("⚠️ 网络错误，\(delay)秒后重试第\(retryCount)次: \(event.title)")
                    
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                } else {
                    print("❌ 同步失败（重试\(retryCount-1)次后放弃）: \(event.title) - \(error.localizedDescription)")
                    return false
                }
            }
        }
        
        return false
    }
    
    // 用于查询已存在事项ID的结构体
    private struct EventIdOnly: Codable {
        let id: String
    }
    
    // MARK: - 网络监控
    
    /// 启动网络状态监控
    private func startNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isNetworkAvailable = path.status == .satisfied
                
                let networkStatus = path.status == .satisfied ? "连接" : "断开"
                print("📶 网络状态: \(networkStatus)")
                
                if path.status == .satisfied {
                    print("📶 网络类型: \(self?.getNetworkType(path) ?? "未知")")
                } else {
                    print("❌ 网络连接失败，同步功能暂不可用")
                }
            }
        }
        
        networkMonitor.start(queue: networkQueue)
    }
    
    /// 获取网络类型描述
    private func getNetworkType(_ path: NWPath) -> String {
        if path.usesInterfaceType(.wifi) {
            return "WiFi"
        } else if path.usesInterfaceType(.cellular) {
            return "蜂窝网络"
        } else if path.usesInterfaceType(.wiredEthernet) {
            return "有线网络"
        } else {
            return "其他"
        }
    }
    
    /// 检查网络连通性（同步方法使用）
    private func waitForNetworkConnection() async -> Bool {
        // 如果网络已连接，直接返回
        if isNetworkAvailable {
            return true
        }
        
        print("⏳ 等待网络连接恢复...")
        
        // 等待最多15秒
        for _ in 0..<15 {
            if isNetworkAvailable {
                print("✅ 网络连接已恢复")
                return true
            }
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 等待1秒
        }
        
        print("❌ 网络连接超时")
        return false
    }
}
