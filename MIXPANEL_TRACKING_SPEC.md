# HiCalendar Mixpanel 埋点规范文档

## 📊 埋点总体策略

### 命名规范
- **前缀**: 所有事件必须以 `hicalendar_` 开头
- **格式**: `hicalendar_[模块]_[动作]` (小写，下划线分隔)
- **用户属性**: `$[属性名]` 或 `hc_[属性名]`

### 事件分类
1. **用户生命周期** - 注册、登录、会员转化
2. **核心功能使用** - 事件管理、AI交互
3. **付费转化漏斗** - 会员相关行为追踪
4. **产品体验** - 界面交互、功能发现

---

## 🔑 核心业务指标追踪

### 1. 用户生命周期事件

#### 用户注册登录
```javascript
// 应用启动
hicalendar_app_launched
Properties: {
  version: "1.0",
  device_type: "iPhone 15 Pro",
  os_version: "iOS 18.0",
  is_first_launch: true/false,
  install_source: "App Store" // 未来可扩展
}

// 用户登录
hicalendar_user_login_started
Properties: {
  login_method: "apple_signin", // apple_signin, email_password
  from_screen: "settings" // settings, onboarding, force_login
}

hicalendar_user_login_completed
Properties: {
  login_method: "apple_signin",
  success: true/false,
  error_code: "permission_denied", // 失败时
  time_to_complete: 3.2 // 秒
}

// 用户登出
hicalendar_user_logout
Properties: {
  session_duration: 1800, // 秒
  events_created_in_session: 5
}
```

#### 首次体验流程
```javascript
// Onboarding完成
hicalendar_onboarding_completed
Properties: {
  steps_completed: 4,
  total_steps: 4,
  completion_time: 120, // 秒
  skipped_steps: [] // ["notification_permission"]
}

// 权限请求
hicalendar_permission_requested
Properties: {
  permission_type: "notifications", // notifications, calendar, microphone
  granted: true/false,
  prompt_count: 1 // 第几次请求该权限
}
```

---

### 2. 事件管理核心功能

#### 事件创建
```javascript
// 开始创建事件
hicalendar_event_create_started
Properties: {
  entry_point: "fab_button", // fab_button, ai_chat, quick_add, calendar_tap
  has_initial_date: true/false
}

// 事件创建完成
hicalendar_event_created
Properties: {
  creation_method: "manual", // manual, ai_generated, voice_input
  has_time: true/false,
  has_details: true/false,
  reminder_count: 2,
  reminder_types: ["day_before", "15_minutes"],
  is_recurring: true/false,
  recurrence_type: "weekly", // daily, weekly, monthly, yearly
  recurrence_count: 7,
  character_count_title: 15,
  character_count_details: 120,
  time_spent: 45.5 // 秒
}

// 事件编辑
hicalendar_event_edited
Properties: {
  event_age_days: 3, // 事件创建后多少天被编辑
  fields_changed: ["title", "time"], // title, time, details, reminders
  is_recurring_event: true/false,
  edit_source: "calendar_view" // calendar_view, event_list, search_result
}

// 事件删除
hicalendar_event_deleted
Properties: {
  event_age_days: 5,
  deletion_method: "swipe", // swipe, edit_view_button, bulk_delete
  is_recurring_event: true/false,
  had_reminders: true/false,
  confirmation_shown: true/false
}
```

#### 日历交互
```javascript
// 日历视图切换
hicalendar_calendar_view_changed
Properties: {
  from_view: "month", // month, week, day, list
  to_view: "week",
  trigger: "tab_tap" // tab_tap, swipe_gesture, quick_action
}

// 日期导航
hicalendar_date_navigation
Properties: {
  navigation_type: "swipe", // swipe, tap_arrow, date_picker, today_button
  direction: "forward", // forward, backward, jump_to_date
  view_type: "month",
  date_distance: 7 // 跳转了多少天
}

// 事件查看
hicalendar_event_viewed
Properties: {
  view_source: "calendar_grid", // calendar_grid, event_list, search_result, widget
  event_type: "upcoming", // upcoming, past, today, recurring
  has_time: true/false,
  days_from_today: 3 // 距离今天的天数，负数表示过去
}
```

---

### 3. AI助手交互追踪

#### AI对话
```javascript
// AI对话开始
hicalendar_ai_chat_started
Properties: {
  entry_point: "bottom_bar_button", // bottom_bar_button, floating_button, voice_overlay
  input_method: "voice", // voice, text, quick_action
  session_id: "uuid" // 用于关联对话session
}

// AI消息发送
hicalendar_ai_message_sent
Properties: {
  session_id: "uuid",
  message_type: "voice", // voice, text
  character_count: 25,
  voice_duration: 3.2, // 语音时长（秒）
  message_intent: "create_event", // create_event, query_events, modify_event, general_chat
  message_index: 1 // 在对话中的消息序号
}

// AI响应处理
hicalendar_ai_response_received
Properties: {
  session_id: "uuid",
  response_type: "event_created", // event_created, event_query, no_action, error
  processing_time: 1.8, // 秒
  confidence_level: "high", // high, medium, low
  actions_performed: ["create_event"], // create_event, search_events, set_reminder
  user_satisfaction: null // 用户反馈时填充
}

// 语音功能使用
hicalendar_voice_interaction
Properties: {
  action: "start_recording", // start_recording, stop_recording, transcription_success, permission_denied
  duration: 4.5, // 录音时长
  transcription_accuracy: "high", // high, medium, low, failed
  language: "zh-CN"
}
```

---

### 4. 会员付费转化漏斗

#### 付费页面
```javascript
// 会员页面访问
hicalendar_premium_page_viewed
Properties: {
  entry_source: "settings", // settings, feature_lock, onboarding, notification
  user_tier: "free", // free, premium
  days_since_install: 5,
  premium_feature_blocked: "cloud_sync" // cloud_sync, widgets, push_notifications
}

// 付费意向
hicalendar_purchase_flow_started
Properties: {
  product_id: "premium_lifetime",
  price_displayed: "$9.99",
  currency: "USD",
  trigger_source: "feature_lock", // cta_button, feature_lock, upgrade_prompt
  user_events_count: 15 // 用户已创建的事件数
}

// 购买完成
hicalendar_purchase_completed
Properties: {
  product_id: "premium_lifetime",
  price_paid: 9.99,
  currency: "USD",
  payment_method: "apple_pay",
  purchase_time: "2025-01-15T10:30:00Z",
  days_to_convert: 3, // 从首次访问premium页面到购买的天数
  trial_used: false // 未来如有试用功能
}

// 购买失败
hicalendar_purchase_failed
Properties: {
  product_id: "premium_lifetime",
  error_type: "user_cancelled", // user_cancelled, payment_failed, store_error
  error_code: "SKError.paymentCancelled",
  step_failed: "payment_confirmation" // product_loading, payment_confirmation, receipt_verification
}

// 购买恢复
hicalendar_purchase_restored
Properties: {
  product_id: "premium_lifetime",
  success: true/false,
  restoration_trigger: "settings_button" // settings_button, app_launch_check, purchase_page
}
```

#### 会员功能使用
```javascript
// 云同步使用
hicalendar_cloud_sync_triggered
Properties: {
  sync_type: "manual", // manual, automatic, background
  events_uploaded: 5,
  events_downloaded: 2,
  sync_duration: 2.3, // 秒
  success: true/false,
  error_type: "network_error" // 失败时
}

// Widget使用
hicalendar_widget_interacted
Properties: {
  widget_size: "medium", // small, medium, large
  interaction_type: "tap_event", // tap_event, tap_add_button, tap_background
  events_displayed: 3,
  from_lock_screen: false
}

// 系统日历同步 (新功能)
hicalendar_system_calendar_sync
Properties: {
  sync_direction: "bidirectional", // import_only, export_only, bidirectional
  calendars_selected: 2,
  events_imported: 8,
  events_exported: 12,
  sync_duration: 5.2,
  success: true/false
}
```

---

### 5. 推送通知效果

```javascript
// 推送通知发送 (通过后端记录)
hicalendar_push_sent
Properties: {
  notification_type: "day_before", // day_before, week_before, at_time
  event_title: "会议", // 脱敏处理
  user_timezone: "Asia/Shanghai",
  delivery_method: "apns" // apns, local_notification
}

// 推送通知点击
hicalendar_push_clicked
Properties: {
  notification_type: "day_before",
  time_to_click: 300, // 从收到通知到点击的秒数
  app_state: "background", // background, foreground, not_running
  target_event_id: "uuid"
}

// 推送设置变更
hicalendar_push_settings_changed
Properties: {
  setting_type: "reminder_default", // reminder_default, permission_status
  old_value: ["day_before"],
  new_value: ["day_before", "15_minutes"],
  change_source: "event_edit" // event_edit, settings_page, first_time_setup
}
```

---

### 6. 用户行为与参与度

#### 应用使用模式
```javascript
// 应用前后台切换
hicalendar_app_backgrounded
Properties: {
  session_duration: 180, // 秒
  events_created: 1,
  ai_messages_sent: 3,
  screens_visited: ["calendar", "ai_chat", "event_edit"]
}

hicalendar_app_foregrounded
Properties: {
  background_duration: 3600, // 秒
  notification_pending: false,
  return_source: "widget_tap" // home_screen_icon, widget_tap, notification_tap, background_app_refresh
}

// 搜索使用
hicalendar_search_performed
Properties: {
  query_length: 5,
  query_type: "event_title", // event_title, date_range, mixed
  results_count: 3,
  result_clicked: true/false,
  search_duration: 2.1 // 从输入到点击结果的时间
}

// 功能发现
hicalendar_feature_discovered
Properties: {
  feature_name: "voice_input", // voice_input, recurring_events, background_images, widgets
  discovery_method: "accidental_tap", // tutorial, accidental_tap, exploration, notification
  time_to_discover: 86400 // 从首次使用app到发现功能的秒数
}
```

#### 用户留存关键指标
```javascript
// 每日活跃
hicalendar_daily_active
Properties: {
  day_of_week: "monday",
  events_today: 2,
  events_upcoming_week: 8,
  last_active_days_ago: 1,
  streak_days: 5 // 连续活跃天数
}

// 核心功能使用里程碑
hicalendar_milestone_reached
Properties: {
  milestone_type: "events_created_10", // events_created_10, days_active_7, premium_converted
  days_to_reach: 12,
  user_segment: "power_user" // casual_user, regular_user, power_user
}
```

---

## 👤 用户属性定义

### 基础用户属性
```javascript
// 设置用户属性
mixpanel.getPeople().set({
  "$name": "用户昵称",
  "$email": "user@example.com",
  "$created": "2025-01-15T10:30:00Z", // 首次使用时间

  // HiCalendar 自定义属性
  "hc_user_tier": "premium", // free, premium
  "hc_signup_method": "apple_signin", // apple_signin, email_password
  "hc_preferred_language": "zh-CN",
  "hc_timezone": "Asia/Shanghai",

  // 使用行为统计
  "hc_total_events_created": 45,
  "hc_ai_messages_sent": 120,
  "hc_days_active": 28,
  "hc_last_sync_date": "2025-01-20T09:15:00Z",

  // 功能使用偏好
  "hc_uses_voice_input": true,
  "hc_uses_recurring_events": true,
  "hc_has_custom_background": false,
  "hc_widget_installed": true,
  "hc_system_calendar_synced": false,

  // 付费相关
  "hc_conversion_date": "2025-01-18T14:20:00Z",
  "hc_lifetime_value": 9.99,
  "hc_days_to_convert": 3
});
```

---

## 📈 关键业务指标Dashboard

### 核心KPI指标
1. **DAU/WAU/MAU** - 基于 `hicalendar_daily_active`
2. **用户留存率** - D1, D7, D30留存
3. **付费转化率** - 从 `hicalendar_premium_page_viewed` 到 `hicalendar_purchase_completed`
4. **功能采用率** - AI助手使用率、Widget安装率等
5. **用户参与度** - 平均事件创建数、AI对话数

### 转化漏斗分析
```
应用安装 → 首次打开 → 完成Onboarding → 创建首个事件 →
活跃使用(7天) → 访问付费页面 → 完成购买 → 使用付费功能
```

### 用户分群策略
- **新用户** (0-7天): 关注Onboarding完成率
- **活跃用户** (8-30天): 关注功能使用深度
- **忠实用户** (30天+): 关注付费转化
- **付费用户**: 关注高级功能使用率和流失风险

---

## 🔧 技术实施注意事项

### 数据隐私与合规
- 所有个人信息需要脱敏处理
- 事件标题等敏感数据只记录长度，不记录具体内容
- 遵循GDPR和国内隐私法规要求
- 提供用户数据导出和删除功能

### 埋点代码规范
- 使用异步发送避免影响用户体验
- 添加埋点失败的容错处理
- 本地缓存机制处理网络异常
- 开发/生产环境分离

### 测试验证
- 所有埋点必须经过QA验证
- 提供埋点测试页面供开发调试
- 集成自动化测试验证关键埋点

这份文档涵盖了HiCalendar应用的核心业务场景和用户行为追踪。请review这个埋点方案，确认是否符合你的分析需求，然后我开始实施代码集成。