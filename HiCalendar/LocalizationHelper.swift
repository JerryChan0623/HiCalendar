//
//  LocalizationHelper.swift
//  HiCalendar
//
//  Created on 2025. Localization Helper for Multi-language Support
//

import Foundation

// MARK: - Localization Helper
struct L10n {

    // MARK: - Navigation & Basic UI
    static let settings = NSLocalizedString("settings", comment: "")
    static let back = NSLocalizedString("back", comment: "")
    static let done = NSLocalizedString("done", comment: "")
    static let cancel = NSLocalizedString("cancel", comment: "")
    static let ok = NSLocalizedString("ok", comment: "")
    static let save = NSLocalizedString("save", comment: "")
    static let delete = NSLocalizedString("delete", comment: "")
    static let edit = NSLocalizedString("edit", comment: "")
    static let add = NSLocalizedString("add", comment: "")
    static let confirm = NSLocalizedString("confirm", comment: "")

    // MARK: - Tab Bar
    static let calendarTab = NSLocalizedString("calendar_tab", comment: "")
    static let everythingTab = NSLocalizedString("everything_tab", comment: "")
    static let aiAssistant = NSLocalizedString("ai_assistant", comment: "")

    // MARK: - Settings View
    static let whoIsHere = NSLocalizedString("who_is_here", comment: "")
    static let itsYou = NSLocalizedString("its_you", comment: "")
    static let changeCalendarSkin = NSLocalizedString("change_calendar_skin", comment: "")
    static let currentLook = NSLocalizedString("current_look", comment: "")
    static let noBackgroundYet = NSLocalizedString("no_background_yet", comment: "")
    static let simpleBeauty = NSLocalizedString("simple_beauty", comment: "")
    static let dontWantThis = NSLocalizedString("dont_want_this", comment: "")
    static let iThinkAgain = NSLocalizedString("i_think_again", comment: "")
    static let dontWantIt = NSLocalizedString("dont_want_it", comment: "")
    static let leavingAlready = NSLocalizedString("leaving_already", comment: "")
    static let reallyLeaving = NSLocalizedString("really_leaving", comment: "")
    static let seeYouLater = NSLocalizedString("see_you_later", comment: "")
    static let chooseBackground = NSLocalizedString("choose_background", comment: "")
    static let updateBackground = NSLocalizedString("update_background", comment: "")
    static let backgroundTip = NSLocalizedString("background_tip", comment: "")

    // MARK: - Login & Authentication
    static let pleaseLogin = NSLocalizedString("please_login", comment: "")
    static let loginBenefits = NSLocalizedString("login_benefits", comment: "")
    static func loginError(_ error: String) -> String {
        return String(format: NSLocalizedString("login_error", comment: ""), error)
    }
    static func appleAuthError(_ error: String) -> String {
        return String(format: NSLocalizedString("apple_auth_error", comment: ""), error)
    }

    // MARK: - Premium Features
    static let upgradeHiCalendarPro = NSLocalizedString("upgrade_hicalendar_pro", comment: "")
    static let hiCalendarMember = NSLocalizedString("hicalendar_member", comment: "")
    static let unlockFeatures = NSLocalizedString("unlock_features", comment: "")
    static let alreadyUnlocked = NSLocalizedString("already_unlocked", comment: "")
    static let cloudSync = NSLocalizedString("cloud_sync", comment: "")
    static let desktopWidgets = NSLocalizedString("desktop_widgets", comment: "")
    static let smartPush = NSLocalizedString("smart_push", comment: "")
    static let upgradeNow = NSLocalizedString("upgrade_now", comment: "")
    static let restorePurchase = NSLocalizedString("restore_purchase", comment: "")
    static let alreadyUnlockedPro = NSLocalizedString("already_unlocked_pro", comment: "")
    static let unlockProFeatures = NSLocalizedString("unlock_pro_features", comment: "")
    static let purchasing = NSLocalizedString("purchasing", comment: "")
    static let lifetimeAccess = NSLocalizedString("lifetime_access", comment: "")
    static let unlockFullFeatures = NSLocalizedString("unlock_full_features", comment: "")

    // MARK: - Premium Features Details
    static let cloudSyncDesc = NSLocalizedString("cloud_sync_desc", comment: "")
    static let widgetDesc = NSLocalizedString("widget_desc", comment: "")
    static let smartPushDesc = NSLocalizedString("smart_push_desc", comment: "")

    // MARK: - Push Notifications
    static let notificationSettings = NSLocalizedString("notification_settings", comment: "")
    static let pushNotEnabled = NSLocalizedString("push_not_enabled", comment: "")
    static let enablePushTip = NSLocalizedString("enable_push_tip", comment: "")
    static let enablePush = NSLocalizedString("enable_push", comment: "")
    static let dayBeforeReminder = NSLocalizedString("day_before_reminder", comment: "")
    static let dayBeforeDesc = NSLocalizedString("day_before_desc", comment: "")
    static let weekBeforeReminder = NSLocalizedString("week_before_reminder", comment: "")
    static let weekBeforeDesc = NSLocalizedString("week_before_desc", comment: "")

    // MARK: - Legal Information
    static let legalInfo = NSLocalizedString("legal_info", comment: "")
    static let termsOfService = NSLocalizedString("terms_of_service", comment: "")
    static let privacyPolicy = NSLocalizedString("privacy_policy", comment: "")
    static func contactUs(_ email: String) -> String {
        return String(format: NSLocalizedString("contact_us", comment: ""), email)
    }
    static let loginAgreement = NSLocalizedString("login_agreement", comment: "")
    static let and = NSLocalizedString("and", comment: "")

    // MARK: - Login Benefits
    static let unlockMoreSettings = NSLocalizedString("unlock_more_settings", comment: "")
    static let personalizedBackground = NSLocalizedString("personalized_background", comment: "")
    static let personalizedBackgroundDesc = NSLocalizedString("personalized_background_desc", comment: "")
    static let becomeMemberUnlock = NSLocalizedString("become_member_unlock", comment: "")
    static let cloudBackup = NSLocalizedString("cloud_backup", comment: "")
    static let cloudBackupDesc = NSLocalizedString("cloud_backup_desc", comment: "")
    static let smartPushNotifications = NSLocalizedString("smart_push_notifications", comment: "")
    static let desktopWidget = NSLocalizedString("desktop_widget", comment: "")
    static let desktopWidgetDesc = NSLocalizedString("desktop_widget_desc", comment: "")
    static let loginFirstDesc = NSLocalizedString("login_first_desc", comment: "")

    // MARK: - AI Personality Responses
    static let aiCantUnderstand = NSLocalizedString("ai_cant_understand", comment: "")
    static func aiCreatedEvent(_ title: String) -> String {
        return String(format: NSLocalizedString("ai_created_event", comment: ""), title)
    }
    static let aiNoEventsToday = NSLocalizedString("ai_no_events_today", comment: "")
    static let aiBusyDay = NSLocalizedString("ai_busy_day", comment: "")
    static let aiEventConflict = NSLocalizedString("ai_event_conflict", comment: "")
    static func aiEventUpdated(_ title: String) -> String {
        return String(format: NSLocalizedString("ai_event_updated", comment: ""), title)
    }
    static func aiEventDeleted(_ title: String) -> String {
        return String(format: NSLocalizedString("ai_event_deleted", comment: ""), title)
    }
    static let aiGoodMorning = NSLocalizedString("ai_good_morning", comment: "")
    static let aiGoodAfternoon = NSLocalizedString("ai_good_afternoon", comment: "")
    static let aiGoodEvening = NSLocalizedString("ai_good_evening", comment: "")

    // MARK: - Event Management
    static let eventTitle = NSLocalizedString("event_title", comment: "")
    static let eventDetails = NSLocalizedString("event_details", comment: "")
    static let startTime = NSLocalizedString("start_time", comment: "")
    static let endTime = NSLocalizedString("end_time", comment: "")
    static let allDay = NSLocalizedString("all_day", comment: "")
    static let noTime = NSLocalizedString("no_time", comment: "")
    static let remindBefore = NSLocalizedString("remind_before", comment: "")
    static let saveEvent = NSLocalizedString("save_event", comment: "")
    static let deleteEvent = NSLocalizedString("delete_event", comment: "")

    // MARK: - Reminder Options
    static let noReminder = NSLocalizedString("no_reminder", comment: "")
    static let atEventTime = NSLocalizedString("at_event_time", comment: "")
    static let minutes15Before = NSLocalizedString("15_minutes_before", comment: "")
    static let minutes30Before = NSLocalizedString("30_minutes_before", comment: "")
    static let hour1Before = NSLocalizedString("1_hour_before", comment: "")
    static let hours2Before = NSLocalizedString("2_hours_before", comment: "")
    static let day1Before = NSLocalizedString("1_day_before", comment: "")
    static let week1Before = NSLocalizedString("1_week_before", comment: "")

    // MARK: - Status & Messages
    static let loading = NSLocalizedString("loading", comment: "")
    static let syncing = NSLocalizedString("syncing", comment: "")
    static let syncCompleted = NSLocalizedString("sync_completed", comment: "")
    static let syncFailed = NSLocalizedString("sync_failed", comment: "")
    static let noEvents = NSLocalizedString("no_events", comment: "")
    static let today = NSLocalizedString("today", comment: "")
    static let tomorrow = NSLocalizedString("tomorrow", comment: "")
    static let yesterday = NSLocalizedString("yesterday", comment: "")

    // MARK: - Purchase Messages
    static let purchaseSuccess = NSLocalizedString("purchase_success", comment: "")
    static func purchaseFailed(_ error: String) -> String {
        return String(format: NSLocalizedString("purchase_failed", comment: ""), error)
    }
    static let purchaseRestored = NSLocalizedString("purchase_restored", comment: "")
    static let noPreviousPurchase = NSLocalizedString("no_previous_purchase", comment: "")
    static let productNotFound = NSLocalizedString("product_not_found", comment: "")

    // MARK: - Error Messages
    static let somethingWentWrong = NSLocalizedString("something_went_wrong", comment: "")
    static let networkError = NSLocalizedString("network_error", comment: "")
    static let tryAgainLater = NSLocalizedString("try_again_later", comment: "")

    // MARK: - Time Formats
    static let timeFormat12h = NSLocalizedString("time_format_12h", comment: "")
    static let timeFormat24h = NSLocalizedString("time_format_24h", comment: "")
    static let dateFormatShort = NSLocalizedString("date_format_short", comment: "")
    static let dateFormatLong = NSLocalizedString("date_format_long", comment: "")

    // MARK: - Calendar View
    static let thisMonth = NSLocalizedString("this_month", comment: "")
    static let thisWeek = NSLocalizedString("this_week", comment: "")
    static let monthView = NSLocalizedString("month_view", comment: "")
    static let weekView = NSLocalizedString("week_view", comment: "")
    static let dayView = NSLocalizedString("day_view", comment: "")

    // MARK: - Voice & AI Features
    static let voicePermissionNeeded = NSLocalizedString("voice_permission_needed", comment: "")
    static let voicePermissionDenied = NSLocalizedString("voice_permission_denied", comment: "")
    static let recording = NSLocalizedString("recording", comment: "")
    static let processing = NSLocalizedString("processing", comment: "")
    static let speakNow = NSLocalizedString("speak_now", comment: "")
    static let tapToType = NSLocalizedString("tap_to_type", comment: "")
    static let longPressToRecord = NSLocalizedString("long_press_to_record", comment: "")

    // MARK: - Alert Messages
    static let reallyDontWant = NSLocalizedString("really_dont_want", comment: "")
    static let sureDeleteImage = NSLocalizedString("sure_delete_image", comment: "")

    // MARK: - App Information
    static func appVersion(_ version: String) -> String {
        return String(format: NSLocalizedString("app_version", comment: ""), version)
    }
    static func buildNumber(_ build: String) -> String {
        return String(format: NSLocalizedString("build_number", comment: ""), build)
    }

    // MARK: - Missing Basic Strings
    static let contactUsTitle = NSLocalizedString("contact_us_title", comment: "")
    static let termsTitle = NSLocalizedString("terms_title", comment: "")
    static let memberCenter = NSLocalizedString("member_center", comment: "")

    // MARK: - Onboarding Cards & Alerts
    static let dragPinchAdjust = NSLocalizedString("drag_pinch_adjust", comment: "")
    static let cropBackgroundImage = NSLocalizedString("crop_background_image", comment: "")
    static let cancelCrop = NSLocalizedString("cancel_crop", comment: "")
    static let confirmCrop = NSLocalizedString("confirm_crop", comment: "")
    static let enableNotifications = NSLocalizedString("enable_notifications", comment: "")
    static let maybeLater = NSLocalizedString("maybe_later", comment: "")
    static let notificationPermissionMessage = NSLocalizedString("notification_permission_message", comment: "")
    static let recordingVoice = NSLocalizedString("recording_voice", comment: "")
    static let processingVoice = NSLocalizedString("processing_voice", comment: "")

    // MARK: - Widget Strings
    static let noEventsToday = NSLocalizedString("no_events_today", comment: "")
    static func moreEventsCount(_ count: Int) -> String {
        return String(format: NSLocalizedString("more_events_count", comment: ""), count)
    }
    static func totalWeekEvents(_ count: Int) -> String {
        return String(format: NSLocalizedString("total_week_events", comment: ""), count)
    }
    static let allWeekEvents = NSLocalizedString("all_week_events", comment: "")
    static let noEventsThisWeek = NSLocalizedString("no_events_this_week", comment: "")
    static let upgradeToProWidget = NSLocalizedString("upgrade_to_pro_widget", comment: "")
    static let widgetLocked = NSLocalizedString("widget_locked", comment: "")

    // MARK: - System Calendar Integration
    static let systemCalendarSync = NSLocalizedString("system_calendar_sync", comment: "")
    static let systemCalendarRequiresPremium = NSLocalizedString("system_calendar_requires_premium", comment: "")
    static let calendarPermissionRequired = NSLocalizedString("calendar_permission_required", comment: "")
    static let calendarPermissionDenied = NSLocalizedString("calendar_permission_denied", comment: "")
    static func calendarPermissionError(_ error: String) -> String {
        return String(format: NSLocalizedString("calendar_permission_error", comment: ""), error)
    }
    static let importOnlyCalendar = NSLocalizedString("import_only_calendar", comment: "")
    static let exportOnlyCalendar = NSLocalizedString("export_only_calendar", comment: "")
    static let bidirectionalSync = NSLocalizedString("bidirectional_sync", comment: "")
    static let importOnlyDescription = NSLocalizedString("import_only_description", comment: "")
    static let exportOnlyDescription = NSLocalizedString("export_only_description", comment: "")
    static let bidirectionalDescription = NSLocalizedString("bidirectional_description", comment: "")
    static let manualSync = NSLocalizedString("manual_sync", comment: "")
    static let hourlySync = NSLocalizedString("hourly_sync", comment: "")
    static let dailySync = NSLocalizedString("daily_sync", comment: "")
    static let realtimeSync = NSLocalizedString("realtime_sync", comment: "")
    static let noCalendarSelected = NSLocalizedString("no_calendar_selected", comment: "")
    static let untitledEvent = NSLocalizedString("untitled_event", comment: "")
    static func syncError(_ error: String) -> String {
        return String(format: NSLocalizedString("sync_error", comment: ""), error)
    }
    static let enableCalendarSync = NSLocalizedString("enable_calendar_sync", comment: "")
    static let syncDirectionTitle = NSLocalizedString("sync_direction_title", comment: "")
    static let syncFrequencyTitle = NSLocalizedString("sync_frequency_title", comment: "")
    static let selectedCalendarsTitle = NSLocalizedString("selected_calendars_title", comment: "")
    static let lastSyncTime = NSLocalizedString("last_sync_time", comment: "")
    static let performManualSync = NSLocalizedString("perform_manual_sync", comment: "")
    static let syncInProgress = NSLocalizedString("sync_in_progress", comment: "")

    // MARK: - Purchase Manager Error Messages
    static let unlockCloudSyncDescription = NSLocalizedString("unlock_cloud_sync_description", comment: "")
    static func loadingProductsFailed(_ error: String) -> String {
        return String(format: NSLocalizedString("loading_products_failed", comment: ""), error)
    }
    static let unknownPurchaseResult = NSLocalizedString("unknown_purchase_result", comment: "")
    static let purchaseVerificationFailed = NSLocalizedString("purchase_verification_failed", comment: "")
    static func purchaseFailedError(_ error: String) -> String {
        return String(format: NSLocalizedString("purchase_failed_error", comment: ""), error)
    }
    static func restorePurchaseFailed(_ error: String) -> String {
        return String(format: NSLocalizedString("restore_purchase_failed", comment: ""), error)
    }
    static func memberDataSyncFailed(_ error: String) -> String {
        return String(format: NSLocalizedString("member_data_sync_failed", comment: ""), error)
    }
    static let verificationFailedMessage = NSLocalizedString("verification_failed_message", comment: "")
    static let productNotFoundMessage = NSLocalizedString("product_not_found_message", comment: "")
    static let userRejectedPush = NSLocalizedString("user_rejected_push", comment: "")
    static let userChoseLaterPush = NSLocalizedString("user_chose_later_push", comment: "")

    // MARK: - Login Guide
    static let loginGuideTitle = NSLocalizedString("login_guide_title", comment: "")
    static let loginGuideSubtitle = NSLocalizedString("login_guide_subtitle", comment: "")
    static let loginButton = NSLocalizedString("login_button", comment: "")
}