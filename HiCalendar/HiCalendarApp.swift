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
        }
        .modelContainer(sharedModelContainer)
    }
}

// MARK: - App Delegate for Push Notifications
class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // 设置推送通知代理
        UNUserNotificationCenter.current().delegate = self
        
        // 不在启动时自动请求推送权限，延迟到用户交互时请求
        print("📱 App启动完成，推送权限将在适当时机请求")
        
        return true
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
        // 如果包含event_id，可以导航到对应的事件详情
        if let eventId = userInfo["event_id"] as? String {
            print("🎯 导航到事件: \(eventId)")
            // TODO: 实现导航到事件详情的逻辑
        }
    }
}
