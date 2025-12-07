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
    static let redeemCode = NSLocalizedString("redeem_code", comment: "")
    static let redeemSuccess = NSLocalizedString("redeem_success", comment: "")
    static func redeemFailed(_ error: String) -> String {
        return String(format: NSLocalizedString("redeem_failed", comment: ""), error)
    }
    static let alreadyUnlockedPro = NSLocalizedString("already_unlocked_pro", comment: "")
    static let unlockProFeatures = NSLocalizedString("unlock_pro_features", comment: "")
    static let purchasing = NSLocalizedString("purchasing", comment: "")
    static let lifetimeAccess = NSLocalizedString("lifetime_access", comment: "")
    static let unlockFullFeatures = NSLocalizedString("unlock_full_features", comment: "")

    // MARK: - Premium Features Details
    static let proFeatures = NSLocalizedString("pro_features", comment: "")
    static let cloudSyncDesc = NSLocalizedString("cloud_sync_desc", comment: "")
    static let widgetDesc = NSLocalizedString("widget_desc", comment: "")
    static let smartPushDesc = NSLocalizedString("smart_push_desc", comment: "")
    static let cloudSyncFeatureDesc = NSLocalizedString("cloud_sync_feature_desc", comment: "")
    static let widgetFeatureDesc = NSLocalizedString("widget_feature_desc", comment: "")
    static let smartPushFeatureTitle = NSLocalizedString("smart_push_feature_title", comment: "")
    static let smartPushFeatureDesc = NSLocalizedString("smart_push_feature_desc", comment: "")
    static let systemCalendarFeatureTitle = NSLocalizedString("system_calendar_feature_title", comment: "")
    static let systemCalendarFeatureDesc = NSLocalizedString("system_calendar_feature_desc", comment: "")

    // MARK: - Push Notifications
    static let notificationSettings = NSLocalizedString("notification_settings", comment: "")
    static let pushNotEnabled = NSLocalizedString("push_not_enabled", comment: "")
    static let enablePushTip = NSLocalizedString("enable_push_tip", comment: "")
    static let enablePush = NSLocalizedString("enable_push", comment: "")
    static let dayBeforeReminder = NSLocalizedString("day_before_reminder", comment: "")
    static let dayBeforeDesc = NSLocalizedString("day_before_desc", comment: "")
    static let weekBeforeReminder = NSLocalizedString("week_before_reminder", comment: "")
    static let weekBeforeDesc = NSLocalizedString("week_before_desc", comment: "")
    static let weekBeforePushRequiresMember = NSLocalizedString("week_before_push_requires_member", comment: "")
    static let freeUserLocalNotificationTip = NSLocalizedString("free_user_local_notification_tip", comment: "")

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
    static let dateFormatYearMonth = NSLocalizedString("date_format_year_month", comment: "")

    // MARK: - Calendar View
    static let thisMonth = NSLocalizedString("this_month", comment: "")
    static let thisWeek = NSLocalizedString("this_week", comment: "")
    static let monthView = NSLocalizedString("month_view", comment: "")
    static let weekView = NSLocalizedString("week_view", comment: "")
    static let dayView = NSLocalizedString("day_view", comment: "")
    static let selectMonth = NSLocalizedString("select_month", comment: "")
    static let quickAddPlaceholder = NSLocalizedString("quick_add_placeholder", comment: "")

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
    static let signInWithApple = NSLocalizedString("sign_in_with_apple", comment: "")

    // MARK: - Empty State Messages
    static let emptyCalendarMessage = NSLocalizedString("empty_calendar_message", comment: "")
    static let noEventsMessage = NSLocalizedString("no_events_message", comment: "")
    static let allCompletedMessage = NSLocalizedString("all_completed_message", comment: "")
    static let loadingMessage = NSLocalizedString("loading_message", comment: "")
    static let noConnectionMessage = NSLocalizedString("no_connection_message", comment: "")

    // MARK: - Push Notification Messages
    static let notificationTitle = NSLocalizedString("notification_title", comment: "")
    static let notification15MinPrefix = NSLocalizedString("notification_15min_prefix", comment: "")
    static let notification30MinPrefix = NSLocalizedString("notification_30min_prefix", comment: "")
    static let notification1HourPrefix = NSLocalizedString("notification_1hour_prefix", comment: "")
    static let notification2HoursPrefix = NSLocalizedString("notification_2hours_prefix", comment: "")
    static let notificationAtTimeSuffix = NSLocalizedString("notification_attime_suffix", comment: "")
    static let notificationLaterSuffix = NSLocalizedString("notification_later_suffix", comment: "")
    static let notificationMessage1 = NSLocalizedString("notification_message_1", comment: "")
    static let notificationMessage2 = NSLocalizedString("notification_message_2", comment: "")
    static let notificationMessage3 = NSLocalizedString("notification_message_3", comment: "")
    static let notificationDefault = NSLocalizedString("notification_default", comment: "")

    // Cloud push messages
    static let push1DaySingle = NSLocalizedString("push_1day_single", comment: "")
    static let push1WeekSingle = NSLocalizedString("push_1week_single", comment: "")
    static let push1DayMultiple = NSLocalizedString("push_1day_multiple", comment: "")
    static let push1WeekMultiple = NSLocalizedString("push_1week_multiple", comment: "")
    static let push1DayNoTime = NSLocalizedString("push_1day_notime", comment: "")
    static let push1WeekNoTime = NSLocalizedString("push_1week_notime", comment: "")

    // MARK: - Missing UI Translations
    static let member = NSLocalizedString("member", comment: "")
    static let upgrade = NSLocalizedString("upgrade", comment: "")
    static let upgradeToPro = NSLocalizedString("upgrade_to_pro", comment: "")
    static let bidirectionalSyncWithSystemCalendar = NSLocalizedString("bidirectional_sync_with_system_calendar", comment: "")
    static let cloudPush = NSLocalizedString("cloud_push", comment: "")
    static let unlocked = NSLocalizedString("unlocked", comment: "")
    static let contactUsFooter = NSLocalizedString("contact_us_footer", comment: "")
    static let manageMembership = NSLocalizedString("manage_membership", comment: "")
    static let detailedSyncSettings = NSLocalizedString("detailed_sync_settings", comment: "")

    // MARK: - Event Edit View
    static let recurringEventSyncModify = NSLocalizedString("recurring_event_sync_modify", comment: "")
    static let modifyEventWillUpdateAll = NSLocalizedString("modify_event_will_update_all", comment: "")
    static let whatsThisCalled = NSLocalizedString("whats_this_called", comment: "")
    static let placeholderMeetingFish = NSLocalizedString("placeholder_meeting_fish", comment: "")
    static let whichDay = NSLocalizedString("which_day", comment: "")
    static let whatTimeStart = NSLocalizedString("what_time_start", comment: "")
    static let allDayEvent = NSLocalizedString("all_day_event", comment: "")
    static let changeTime = NSLocalizedString("change_time", comment: "")
    static let anyAdditionalDetails = NSLocalizedString("any_additional_details", comment: "")
    static let whereWhatToBring = NSLocalizedString("where_what_to_bring", comment: "")
    static let whenToRemindYou = NSLocalizedString("when_to_remind_you", comment: "")
    static let noReminderEmoji = NSLocalizedString("no_reminder_emoji", comment: "")
    static let recurrenceFrequency = NSLocalizedString("recurrence_frequency", comment: "")
    static let recurrenceSettings = NSLocalizedString("recurrence_settings", comment: "")
    static let startDate = NSLocalizedString("start_date", comment: "")
    static let endDate = NSLocalizedString("end_date", comment: "")
    static let after7Days = NSLocalizedString("after_7_days", comment: "")
    static let recurrenceCount = NSLocalizedString("recurrence_count", comment: "")
    static let endDateAlreadySet = NSLocalizedString("end_date_already_set", comment: "")
    static let timesSuffix = NSLocalizedString("times_suffix", comment: "")

    // MARK: - Event Edit Navigation & Buttons
    static let newEventTitle = NSLocalizedString("new_event_title", comment: "")
    static let editEventTitle = NSLocalizedString("edit_event_title", comment: "")
    static let doneButton = NSLocalizedString("done_button", comment: "")
    static let syncSaveButton = NSLocalizedString("sync_save_button", comment: "")
    static let createButton = NSLocalizedString("create_button", comment: "")

    // MARK: - Recurrence Options
    static let noRepeat = NSLocalizedString("no_repeat", comment: "")
    static let dailyRepeat = NSLocalizedString("daily_repeat", comment: "")
    static let weeklyRepeat = NSLocalizedString("weekly_repeat", comment: "")
    static let monthlyRepeat = NSLocalizedString("monthly_repeat", comment: "")
    static let yearlyRepeat = NSLocalizedString("yearly_repeat", comment: "")

    // MARK: - Event Drawer
    static func eventsWaitingForYou(_ count: Int) -> String {
        if count == 1 {
            return String(format: NSLocalizedString("event_waiting_for_you", comment: ""), count)
        } else {
            return String(format: NSLocalizedString("events_waiting_for_you", comment: ""), count)
        }
    }

    // MARK: - All Tasks View
    static let searchEventsPlaceholder = NSLocalizedString("search_events_placeholder", comment: "")
    static let urgentEvents = NSLocalizedString("urgent_events", comment: "")
    static let upcomingEvents = NSLocalizedString("upcoming_events", comment: "")
    static let laterEvents = NSLocalizedString("later_events", comment: "")
    static let expiredEvents = NSLocalizedString("expired_events", comment: "")
    static let collapse = NSLocalizedString("collapse", comment: "")
    static let viewAll = NSLocalizedString("view_all", comment: "")
    static func moreItemsHidden(_ count: Int) -> String {
        return String(format: NSLocalizedString("more_items_hidden", comment: ""), count)
    }
    static let noMatchingEvents = NSLocalizedString("no_matching_events", comment: "")

    // MARK: - Delete Confirmation
    static let deleteRecurrenceGroupTitle = NSLocalizedString("delete_recurrence_group_title", comment: "")
    static let deleteSingleEventTitle = NSLocalizedString("delete_single_event_title", comment: "")
    static let deleteRecurrenceGroupMessage = NSLocalizedString("delete_recurrence_group_message", comment: "")
    static let deleteSingleEventMessage = NSLocalizedString("delete_single_event_message", comment: "")
    static let deleteAllButton = NSLocalizedString("delete_all_button", comment: "")
    static let deleteEventButton = NSLocalizedString("delete_event_button", comment: "")

    // MARK: - Login Benefits Details
    static let personalizedBackgroundDescDetail = NSLocalizedString("personalized_background_desc_detail", comment: "")
    static let cloudBackupTitle = NSLocalizedString("cloud_backup_title", comment: "")
    static let cloudBackupDescDetail = NSLocalizedString("cloud_backup_desc_detail", comment: "")
    static let smartPushTitle = NSLocalizedString("smart_push_title", comment: "")
    static let smartPushDescDetail = NSLocalizedString("smart_push_desc_detail", comment: "")
    static let desktopWidgetDescDetail = NSLocalizedString("desktop_widget_desc_detail", comment: "")
    static let systemCalendarSyncTitle = NSLocalizedString("system_calendar_sync_title", comment: "")
    static let systemCalendarSyncDescDetail = NSLocalizedString("system_calendar_sync_desc_detail", comment: "")

    // MARK: - Time Reminder Labels
    static let expiredEvent = NSLocalizedString("expired_event", comment: "")
    static let eventToday = NSLocalizedString("event_today", comment: "")
    static let eventTomorrow = NSLocalizedString("event_tomorrow", comment: "")
    static let eventDayAfterTomorrow = NSLocalizedString("event_day_after_tomorrow", comment: "")
    static func eventDaysLater(_ days: Int) -> String {
        return String(format: NSLocalizedString("event_days_later", comment: ""), days)
    }
    static func eventWeeksLater(_ weeks: Int) -> String {
        return String(format: NSLocalizedString("event_weeks_later", comment: ""), weeks)
    }
    static let eventVeryFarFuture = NSLocalizedString("event_very_far_future", comment: "")

    // MARK: - Apple Sign In Error Messages
    static let appleSigninCredentialInvalid = NSLocalizedString("apple_signin_credential_invalid", comment: "")
    static let appleSigninDataIncomplete = NSLocalizedString("apple_signin_data_incomplete", comment: "")
    static func supabaseSigninFailed(_ error: String) -> String {
        return String(format: NSLocalizedString("supabase_signin_failed", comment: ""), error)
    }
    static let signinCanceled = NSLocalizedString("signin_canceled", comment: "")
    static let signinFailed = NSLocalizedString("signin_failed", comment: "")
    static let signinInvalidResponse = NSLocalizedString("signin_invalid_response", comment: "")
    static let signinNotHandled = NSLocalizedString("signin_not_handled", comment: "")
    static let signinUnknownError = NSLocalizedString("signin_unknown_error", comment: "")
    static let signinNotInteractive = NSLocalizedString("signin_not_interactive", comment: "")
    static let signinCredentialExcluded = NSLocalizedString("signin_credential_excluded", comment: "")
    static let signinCredentialImportFailed = NSLocalizedString("signin_credential_import_failed", comment: "")
    static let signinCredentialExportFailed = NSLocalizedString("signin_credential_export_failed", comment: "")
    static let signinGeneralError = NSLocalizedString("signin_general_error", comment: "")
}