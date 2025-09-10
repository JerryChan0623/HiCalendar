//
//  PushNotificationManager.swift
//  HiCalendar
//
//  Created on 2024. Push Notification Management
//

import Foundation
import UserNotifications
import UIKit
import Supabase

// MARK: - Push Notification Manager
class PushNotificationManager: ObservableObject {
    static let shared = PushNotificationManager()
    
    @Published var isPermissionGranted = false
    @Published var currentDeviceToken: String?
    @Published var pushSettings = PushSettings()
    
    private let supabase = SupabaseManager.shared.client
    
    private init() {
        checkNotificationPermission()
        loadPushSettings()
    }
    
    // MARK: - Push Settings Model
    struct PushSettings: Codable {
        var dayBeforeEnabled = true
        var weekBeforeEnabled = false
        
        enum CodingKeys: String, CodingKey {
            case dayBeforeEnabled = "default_push_day_before"
            case weekBeforeEnabled = "default_push_week_before"
        }
    }
    
    // MARK: - Permission Management
    
    /// 检查当前推送权限状态
    func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isPermissionGranted = settings.authorizationStatus == .authorized
                print("📱 推送权限状态: \(settings.authorizationStatus.rawValue)")
            }
        }
    }
    
    /// 请求推送权限
    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            )
            
            await MainActor.run {
                self.isPermissionGranted = granted
                if granted {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
            
            return granted
        } catch {
            print("❌ 请求推送权限失败: \(error)")
            return false
        }
    }
    
    /// 打开系统设置页面
    func openSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    // MARK: - Device Token Management
    
    /// 上传Device Token到Supabase
    func uploadDeviceToken(_ token: String) async {
        guard SupabaseManager.shared.isAuthenticated,
              let userId = SupabaseManager.shared.currentUser?.id else {
            print("❌ 用户未登录，无法上传Device Token")
            return
        }
        
        do {
            // 插入或更新设备记录
            struct DeviceData: Codable {
                let user_id: String
                let device_token: String
                let platform: String
                let is_active: Bool
            }
            
            let deviceData = DeviceData(
                user_id: userId.uuidString,
                device_token: token,
                platform: "ios",
                is_active: true
            )
            
            try await supabase
                .from("user_devices")
                .upsert(deviceData)
                .execute()
            
            print("✅ Device Token上传成功: \(token)")
            
            await MainActor.run {
                self.currentDeviceToken = token
            }
            
        } catch {
            print("❌ Device Token上传失败: \(error)")
        }
    }
    
    /// 标记设备为非活跃状态（用户登出时调用）
    func deactivateCurrentDevice() async {
        guard let token = currentDeviceToken else { return }
        
        do {
            struct UpdateData: Codable {
                let is_active: Bool
            }
            
            let updateData = UpdateData(is_active: false)
            
            try await supabase
                .from("user_devices")
                .update(updateData)
                .eq("device_token", value: token)
                .execute()
            
            await MainActor.run {
                self.currentDeviceToken = nil
            }
            
            print("✅ 设备已标记为非活跃")
        } catch {
            print("❌ 设备状态更新失败: \(error)")
        }
    }
    
    // MARK: - Push Settings Management
    
    /// 加载用户的推送设置
    func loadPushSettings() {
        guard SupabaseManager.shared.isAuthenticated,
              let userId = SupabaseManager.shared.currentUser?.id else {
            return
        }
        
        Task {
            do {
                let response: [PushSettings] = try await supabase
                    .from("users")
                    .select("default_push_day_before, default_push_week_before")
                    .eq("id", value: userId)
                    .execute()
                    .value
                
                if let settings = response.first {
                    await MainActor.run {
                        self.pushSettings = settings
                    }
                }
            } catch {
                print("❌ 加载推送设置失败: \(error)")
            }
        }
    }
    
    /// 更新用户的推送设置
    func updatePushSettings(_ settings: PushSettings) async {
        guard SupabaseManager.shared.isAuthenticated,
              let userId = SupabaseManager.shared.currentUser?.id else {
            print("❌ 用户未登录，无法更新推送设置")
            return
        }
        
        do {
            struct UserUpdateData: Codable {
                let default_push_day_before: Bool
                let default_push_week_before: Bool
            }
            
            let updateData = UserUpdateData(
                default_push_day_before: settings.dayBeforeEnabled,
                default_push_week_before: settings.weekBeforeEnabled
            )
            
            try await supabase
                .from("users")
                .update(updateData)
                .eq("id", value: userId.uuidString)
                .execute()
            
            await MainActor.run {
                self.pushSettings = settings
            }
            
            print("✅ 推送设置更新成功")
        } catch {
            print("❌ 推送设置更新失败: \(error)")
        }
    }
    
    // MARK: - Utility Methods
    
    /// 获取推送权限状态描述
    func getPermissionStatusDescription() -> String {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            let description: String
            switch settings.authorizationStatus {
            case .notDetermined:
                description = "未设置"
            case .denied:
                description = "已拒绝"
            case .authorized:
                description = "已允许"
            case .provisional:
                description = "临时允许"
            case .ephemeral:
                description = "临时"
            @unknown default:
                description = "未知状态"
            }
            print("📱 推送权限: \(description)")
        }
        
        return isPermissionGranted ? "已开启" : "未开启"
    }
    
    /// 测试本地推送通知（用于调试）
    func sendTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "HiCalendar测试"
        content.body = "这是一条测试推送通知～ 🎉"
        content.badge = 1
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "test_notification",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ 测试通知发送失败: \(error)")
            } else {
                print("✅ 测试通知已发送")
            }
        }
    }
}

// MARK: - Push Notification Permission Status Extension
extension UNAuthorizationStatus {
    var description: String {
        switch self {
        case .notDetermined: return "未设置"
        case .denied: return "已拒绝"  
        case .authorized: return "已允许"
        case .provisional: return "临时允许"
        case .ephemeral: return "临时"
        @unknown default: return "未知状态"
        }
    }
    
    var isEnabled: Bool {
        return self == .authorized || self == .provisional
    }
}