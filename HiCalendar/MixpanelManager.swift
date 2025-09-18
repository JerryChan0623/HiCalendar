//
//  MixpanelManager.swift
//  HiCalendar
//
//  Created on 2025. Mixpanel Analytics Manager
//

import Foundation
import UIKit
import Mixpanel

@MainActor
class MixpanelManager: ObservableObject {
    static let shared = MixpanelManager()

    private var mixpanel: MixpanelInstance?

    // Mixpanel 配置
    private let projectToken = "0206a8ea4dbd922e8f5b5e3b7940b503"
    private let apiSecret = "41573c33624e3665b59832f9f6a048eb"

    private init() {
        setupMixpanel()
    }

    // MARK: - Setup
    private func setupMixpanel() {
        #if DEBUG
        // 开发环境使用测试项目token（如果有的话）
        mixpanel = Mixpanel.initialize(token: projectToken, trackAutomaticEvents: false)
        print("🔥 Mixpanel initialized in DEBUG mode")
        #else
        // 生产环境
        mixpanel = Mixpanel.initialize(token: projectToken, trackAutomaticEvents: false)
        print("🔥 Mixpanel initialized in RELEASE mode")
        #endif

        // 设置用户属性
        setupUserProperties()
    }

    private func setupUserProperties() {
        guard let mixpanel = mixpanel else { return }

        // 设置基础设备信息
        mixpanel.people.set(properties: [
            "$ios_device_model": UIDevice.current.model,
            "$ios_version": UIDevice.current.systemVersion,
            "$ios_app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
            "$ios_app_build": Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        ])
    }

    // MARK: - User Identity
    func identify(userId: String) {
        mixpanel?.identify(distinctId: userId)
        print("📊 Mixpanel identified user: \(userId)")
    }

    func setUserProperties(_ properties: [String: MixpanelType]) {
        mixpanel?.people.set(properties: properties)
        print("👤 Mixpanel user properties updated: \(properties)")
    }

    func logout() {
        mixpanel?.reset()
        print("🚪 Mixpanel user logged out and reset")
    }

    // MARK: - Event Tracking
    private func track(event: String, properties: [String: MixpanelType]? = nil) {
        guard let mixpanel = mixpanel else { return }

        var finalProperties = properties ?? [:]

        // 添加通用属性
        finalProperties["app_version"] = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        finalProperties["platform"] = "iOS"
        finalProperties["timestamp"] = Date().timeIntervalSince1970

        mixpanel.track(event: event, properties: finalProperties)

        #if DEBUG
        print("📊 Mixpanel tracked: \(event) with properties: \(finalProperties)")
        #endif
    }
}

// MARK: - 1. 用户生命周期事件
extension MixpanelManager {

    // 应用启动
    func trackAppLaunched(
        version: String,
        deviceType: String,
        osVersion: String,
        isFirstLaunch: Bool,
        installSource: String = "App Store"
    ) {
        track(event: "hicalendar_app_launched", properties: [
            "version": version,
            "device_type": deviceType,
            "os_version": osVersion,
            "is_first_launch": isFirstLaunch,
            "install_source": installSource
        ])
    }

    // 用户登录开始
    func trackUserLoginStarted(
        loginMethod: String, // apple_signin, email_password
        fromScreen: String   // settings, onboarding, force_login
    ) {
        track(event: "hicalendar_user_login_started", properties: [
            "login_method": loginMethod,
            "from_screen": fromScreen
        ])
    }

    // 用户登录完成
    func trackUserLoginCompleted(
        loginMethod: String,
        success: Bool,
        errorCode: String? = nil,
        timeToComplete: Double
    ) {
        var properties: [String: MixpanelType] = [
            "login_method": loginMethod,
            "success": success,
            "time_to_complete": timeToComplete
        ]

        if let errorCode = errorCode {
            properties["error_code"] = errorCode
        }

        track(event: "hicalendar_user_login_completed", properties: properties)
    }

    // 用户登出
    func trackUserLogout(
        sessionDuration: TimeInterval,
        eventsCreatedInSession: Int
    ) {
        track(event: "hicalendar_user_logout", properties: [
            "session_duration": sessionDuration,
            "events_created_in_session": eventsCreatedInSession
        ])
    }

    // 权限请求
    func trackPermissionRequested(
        permissionType: String, // notifications, calendar, microphone
        granted: Bool,
        promptCount: Int
    ) {
        track(event: "hicalendar_permission_requested", properties: [
            "permission_type": permissionType,
            "granted": granted,
            "prompt_count": promptCount
        ])
    }
}

// MARK: - 2. 事件管理核心功能
extension MixpanelManager {

    // 开始创建事件
    func trackEventCreateStarted(
        entryPoint: String, // fab_button, calendar_tap, quick_add
        hasInitialDate: Bool
    ) {
        track(event: "hicalendar_event_create_started", properties: [
            "entry_point": entryPoint,
            "has_initial_date": hasInitialDate
        ])
    }

    // 事件创建完成
    func trackEventCreated(
        creationMethod: String = "manual",
        hasTime: Bool,
        hasDetails: Bool,
        reminderCount: Int,
        reminderTypes: [String],
        isRecurring: Bool,
        recurrenceType: String? = nil,
        recurrenceCount: Int? = nil,
        characterCountTitle: Int,
        characterCountDetails: Int,
        timeSpent: Double
    ) {
        var properties: [String: MixpanelType] = [
            "creation_method": creationMethod,
            "has_time": hasTime,
            "has_details": hasDetails,
            "reminder_count": reminderCount,
            "reminder_types": reminderTypes,
            "is_recurring": isRecurring,
            "character_count_title": characterCountTitle,
            "character_count_details": characterCountDetails,
            "time_spent": timeSpent
        ]

        if let recurrenceType = recurrenceType {
            properties["recurrence_type"] = recurrenceType
        }

        if let recurrenceCount = recurrenceCount {
            properties["recurrence_count"] = recurrenceCount
        }

        track(event: "hicalendar_event_created", properties: properties)
    }

    // 事件编辑
    func trackEventEdited(
        eventAgeDays: Int,
        fieldsChanged: [String],
        isRecurringEvent: Bool,
        editSource: String // calendar_view, event_list, search_result
    ) {
        track(event: "hicalendar_event_edited", properties: [
            "event_age_days": eventAgeDays,
            "fields_changed": fieldsChanged,
            "is_recurring_event": isRecurringEvent,
            "edit_source": editSource
        ])
    }

    // 事件删除
    func trackEventDeleted(
        eventAgeDays: Int,
        deletionMethod: String, // swipe, edit_view_button, bulk_delete
        isRecurringEvent: Bool,
        hadReminders: Bool,
        confirmationShown: Bool
    ) {
        track(event: "hicalendar_event_deleted", properties: [
            "event_age_days": eventAgeDays,
            "deletion_method": deletionMethod,
            "is_recurring_event": isRecurringEvent,
            "had_reminders": hadReminders,
            "confirmation_shown": confirmationShown
        ])
    }

    // 日历视图切换
    func trackCalendarViewChanged(
        fromView: String, // month, week, day, list
        toView: String,
        trigger: String // tab_tap, swipe_gesture, quick_action
    ) {
        track(event: "hicalendar_calendar_view_changed", properties: [
            "from_view": fromView,
            "to_view": toView,
            "trigger": trigger
        ])
    }

    // 日期导航
    func trackDateNavigation(
        navigationType: String, // swipe, tap_arrow, date_picker, today_button
        direction: String, // forward, backward, jump_to_date
        viewType: String,
        dateDistance: Int
    ) {
        track(event: "hicalendar_date_navigation", properties: [
            "navigation_type": navigationType,
            "direction": direction,
            "view_type": viewType,
            "date_distance": dateDistance
        ])
    }

    // 事件查看
    func trackEventViewed(
        viewSource: String, // calendar_grid, event_list, search_result, widget
        eventType: String, // upcoming, past, today, recurring
        hasTime: Bool,
        daysFromToday: Int
    ) {
        track(event: "hicalendar_event_viewed", properties: [
            "view_source": viewSource,
            "event_type": eventType,
            "has_time": hasTime,
            "days_from_today": daysFromToday
        ])
    }
}

// MARK: - 3. 会员付费转化漏斗
extension MixpanelManager {

    // 会员页面访问
    func trackPremiumPageViewed(
        entrySource: String, // settings, feature_lock, onboarding, notification
        userTier: String, // free, premium
        daysSinceInstall: Int,
        premiumFeatureBlocked: String? = nil
    ) {
        var properties: [String: MixpanelType] = [
            "entry_source": entrySource,
            "user_tier": userTier,
            "days_since_install": daysSinceInstall
        ]

        if let feature = premiumFeatureBlocked {
            properties["premium_feature_blocked"] = feature
        }

        track(event: "hicalendar_premium_page_viewed", properties: properties)
    }

    // 购买流程开始
    func trackPurchaseFlowStarted(
        productId: String,
        priceDisplayed: String,
        currency: String,
        triggerSource: String, // cta_button, feature_lock, upgrade_prompt
        userEventsCount: Int
    ) {
        track(event: "hicalendar_purchase_flow_started", properties: [
            "product_id": productId,
            "price_displayed": priceDisplayed,
            "currency": currency,
            "trigger_source": triggerSource,
            "user_events_count": userEventsCount
        ])
    }

    // 购买完成
    func trackPurchaseCompleted(
        productId: String,
        pricePaid: Double,
        currency: String,
        paymentMethod: String,
        purchaseTime: String,
        daysToConvert: Int,
        trialUsed: Bool = false
    ) {
        track(event: "hicalendar_purchase_completed", properties: [
            "product_id": productId,
            "price_paid": pricePaid,
            "currency": currency,
            "payment_method": paymentMethod,
            "purchase_time": purchaseTime,
            "days_to_convert": daysToConvert,
            "trial_used": trialUsed
        ])
    }

    // 购买失败
    func trackPurchaseFailed(
        productId: String,
        errorType: String, // user_cancelled, payment_failed, store_error
        errorCode: String,
        stepFailed: String // product_loading, payment_confirmation, receipt_verification
    ) {
        track(event: "hicalendar_purchase_failed", properties: [
            "product_id": productId,
            "error_type": errorType,
            "error_code": errorCode,
            "step_failed": stepFailed
        ])
    }

    // 购买恢复
    func trackPurchaseRestored(
        productId: String,
        success: Bool,
        restorationTrigger: String // settings_button, app_launch_check, purchase_page
    ) {
        track(event: "hicalendar_purchase_restored", properties: [
            "product_id": productId,
            "success": success,
            "restoration_trigger": restorationTrigger
        ])
    }

    // 云同步使用
    func trackCloudSyncTriggered(
        syncType: String, // manual, automatic, background
        eventsUploaded: Int,
        eventsDownloaded: Int,
        syncDuration: Double,
        success: Bool,
        errorType: String? = nil
    ) {
        var properties: [String: MixpanelType] = [
            "sync_type": syncType,
            "events_uploaded": eventsUploaded,
            "events_downloaded": eventsDownloaded,
            "sync_duration": syncDuration,
            "success": success
        ]

        if let errorType = errorType {
            properties["error_type"] = errorType
        }

        track(event: "hicalendar_cloud_sync_triggered", properties: properties)
    }

    // Widget使用
    func trackWidgetInteracted(
        widgetSize: String, // small, medium, large
        interactionType: String, // tap_event, tap_add_button, tap_background
        eventsDisplayed: Int,
        fromLockScreen: Bool
    ) {
        track(event: "hicalendar_widget_interacted", properties: [
            "widget_size": widgetSize,
            "interaction_type": interactionType,
            "events_displayed": eventsDisplayed,
            "from_lock_screen": fromLockScreen
        ])
    }

    // 系统日历同步
    func trackSystemCalendarSync(
        syncDirection: String, // import_only, export_only, bidirectional
        calendarsSelected: Int,
        eventsImported: Int,
        eventsExported: Int,
        syncDuration: Double,
        success: Bool
    ) {
        track(event: "hicalendar_system_calendar_sync", properties: [
            "sync_direction": syncDirection,
            "calendars_selected": calendarsSelected,
            "events_imported": eventsImported,
            "events_exported": eventsExported,
            "sync_duration": syncDuration,
            "success": success
        ])
    }
}

// MARK: - 4. 推送通知效果
extension MixpanelManager {

    // 推送通知发送
    func trackPushSent(
        notificationType: String, // day_before, week_before, at_time
        eventTitle: String, // 脱敏处理
        userTimezone: String,
        deliveryMethod: String // apns, local_notification
    ) {
        track(event: "hicalendar_push_sent", properties: [
            "notification_type": notificationType,
            "event_title": eventTitle,
            "user_timezone": userTimezone,
            "delivery_method": deliveryMethod
        ])
    }

    // 推送通知点击
    func trackPushClicked(
        notificationType: String,
        timeToClick: TimeInterval,
        appState: String, // background, foreground, not_running
        targetEventId: String
    ) {
        track(event: "hicalendar_push_clicked", properties: [
            "notification_type": notificationType,
            "time_to_click": timeToClick,
            "app_state": appState,
            "target_event_id": targetEventId
        ])
    }

    // 推送设置变更
    func trackPushSettingsChanged(
        settingType: String, // reminder_default, permission_status
        oldValue: [String],
        newValue: [String],
        changeSource: String // event_edit, settings_page, first_time_setup
    ) {
        track(event: "hicalendar_push_settings_changed", properties: [
            "setting_type": settingType,
            "old_value": oldValue,
            "new_value": newValue,
            "change_source": changeSource
        ])
    }
}

// MARK: - 5. 用户行为与参与度
extension MixpanelManager {

    // 应用进入后台
    func trackAppBackgrounded(
        sessionDuration: TimeInterval,
        eventsCreated: Int,
        screensVisited: [String]
    ) {
        track(event: "hicalendar_app_backgrounded", properties: [
            "session_duration": sessionDuration,
            "events_created": eventsCreated,
            "screens_visited": screensVisited
        ])
    }

    // 应用回到前台
    func trackAppForegrounded(
        backgroundDuration: TimeInterval,
        notificationPending: Bool,
        returnSource: String // home_screen_icon, widget_tap, notification_tap, background_app_refresh
    ) {
        track(event: "hicalendar_app_foregrounded", properties: [
            "background_duration": backgroundDuration,
            "notification_pending": notificationPending,
            "return_source": returnSource
        ])
    }

    // 搜索使用
    func trackSearchPerformed(
        queryLength: Int,
        queryType: String, // event_title, date_range, mixed
        resultsCount: Int,
        resultClicked: Bool,
        searchDuration: Double
    ) {
        track(event: "hicalendar_search_performed", properties: [
            "query_length": queryLength,
            "query_type": queryType,
            "results_count": resultsCount,
            "result_clicked": resultClicked,
            "search_duration": searchDuration
        ])
    }

    // 功能发现
    func trackFeatureDiscovered(
        featureName: String, // background_images, widgets, system_calendar_sync
        discoveryMethod: String, // tutorial, accidental_tap, exploration, notification
        timeToDiscover: TimeInterval
    ) {
        track(event: "hicalendar_feature_discovered", properties: [
            "feature_name": featureName,
            "discovery_method": discoveryMethod,
            "time_to_discover": timeToDiscover
        ])
    }
}