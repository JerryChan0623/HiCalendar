//
//  HiCalendarApp.swift
//  HiCalendar
//
//  Created by Jerry  on 2025/8/8.
//

import SwiftUI
import SwiftData
import UserNotifications

@main
struct HiCalendarApp: App {
    @StateObject private var authManager = SupabaseManager.shared
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .onOpenURL { url in
                    handleDeepLink(url)
                }
        }
        .modelContainer(sharedModelContainer)
    }

    // MARK: - 深链接处理
    private func handleDeepLink(_ url: URL) {
        print("🔗 收到深链接: \(url)")

        if url.scheme == "hicalendar" && url.host == "premium" {
            // Widget点击升级链接
            print("💰 从Widget跳转到付费页面")

            // 通过通知中心发送事件到ContentView
            NotificationCenter.default.post(
                name: Notification.Name("ShowPremiumView"),
                object: nil
            )
        }
    }
}

// MARK: - App Delegate for Push Notifications
class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // 设置推送通知代理
        UNUserNotificationCenter.current().delegate = self

        // 清除应用图标上的badge数字（iOS 17+使用新API）
        if #available(iOS 17.0, *) {
            UNUserNotificationCenter.current().setBadgeCount(0) { error in
                if let error = error {
                    print("⚠️ 清除badge失败: \(error)")
                }
            }
        } else {
            UIApplication.shared.applicationIconBadgeNumber = 0
        }

        // 初始化Mixpanel并追踪应用启动
        Task { @MainActor in
            setupMixpanelTracking()
        }

        // 不在启动时自动请求推送权限，延迟到用户交互时请求
        print("📱 App启动完成，推送权限将在适当时机请求")

        return true
    }

    // MARK: - Mixpanel Setup
    @MainActor
    private func setupMixpanelTracking() {
        // 检查是否首次启动
        let isFirstLaunch = !UserDefaults.standard.bool(forKey: "HasLaunchedBefore")
        if isFirstLaunch {
            UserDefaults.standard.set(true, forKey: "HasLaunchedBefore")
        }

        // 追踪应用启动
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let deviceType = UIDevice.current.model
        let osVersion = UIDevice.current.systemVersion

        MixpanelManager.shared.trackAppLaunched(
            version: version,
            deviceType: deviceType,
            osVersion: osVersion,
            isFirstLaunch: isFirstLaunch
        )

        // 如果用户已登录，设置用户身份
        if SupabaseManager.shared.isAuthenticated,
           let userId = SupabaseManager.shared.currentUser?.id.uuidString {
            MixpanelManager.shared.identify(userId: userId)
        }
    }
    
    // MARK: - APNs Registration
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        
        print("✅ 获取到Device Token: \(token)")
        
        // 上传到Supabase
        Task {
            await PushNotificationManager.shared.uploadDeviceToken(token)
        }
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ Device Token注册失败: \(error)")
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension AppDelegate: UNUserNotificationCenterDelegate {
    
    // 应用在前台时收到推送通知
    func userNotificationCenter(_ center: UNUserNotificationCenter, 
                               willPresent notification: UNNotification, 
                               withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        print("📱 收到前台推送: \(notification.request.content.body)")
        
        // 在前台也显示推送通知
        completionHandler([.banner, .badge, .sound])
    }
    
    // 用户点击推送通知
    func userNotificationCenter(_ center: UNUserNotificationCenter, 
                               didReceive response: UNNotificationResponse, 
                               withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let userInfo = response.notification.request.content.userInfo
        print("👆 用户点击推送通知: \(userInfo)")
        
        // 处理推送通知点击事件
        handlePushNotificationTap(userInfo: userInfo)
        
        completionHandler()
    }
    
    // MARK: - 处理推送通知点击
    private func handlePushNotificationTap(userInfo: [AnyHashable: Any]) {
        // 获取推送信息
        let notificationType = userInfo["type"] as? String ?? "unknown"
        let eventId = userInfo["event_id"] as? String ?? ""
        let sentTime = userInfo["sent_time"] as? TimeInterval ?? 0
        let timeToClick = Date().timeIntervalSince1970 - sentTime

        // 确定应用状态
        let appState: String
        switch UIApplication.shared.applicationState {
        case .active:
            appState = "foreground"
        case .inactive:
            appState = "background"
        case .background:
            appState = "not_running"
        @unknown default:
            appState = "unknown"
        }

        // 追踪推送点击
        Task { @MainActor in
            MixpanelManager.shared.trackPushClicked(
                notificationType: notificationType,
                timeToClick: timeToClick,
                appState: appState,
                targetEventId: eventId
            )
        }

        // 如果包含event_id，可以导航到对应的事件详情
        if !eventId.isEmpty {
            print("🎯 导航到事件: \(eventId)")
            // TODO: 实现导航到事件详情的逻辑
        }
    }
}
