# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

HiCalendar is a "Cute Calendar AI" iOS app built with SwiftUI that allows users to manage events through natural language AI interactions. The app features a playful, sarcastic AI personality that provides witty commentary while helping users create, modify, and query calendar events. The design follows Neobrutalism aesthetic with high contrast colors and bold borders.

## Development Commands

### Building and Testing
```bash
# Open project in Xcode
open HiCalendar.xcodeproj

# Build from command line (iPhone 16 simulator is the default target)
xcodebuild -project HiCalendar.xcodeproj -scheme HiCalendar -destination 'platform=iOS Simulator,name=iPhone 16' build

# Run all tests
xcodebuild test -project HiCalendar.xcodeproj -scheme HiCalendar -destination 'platform=iOS Simulator,name=iPhone 16'

# Run specific test class
xcodebuild test -project HiCalendar.xcodeproj -scheme HiCalendar -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:HiCalendarTests/HiCalendarTests

# Clean build folder
xcodebuild clean -project HiCalendar.xcodeproj -scheme HiCalendar

# Build and check for compilation errors (REQUIRED after code changes)
xcodebuild -project HiCalendar.xcodeproj -scheme HiCalendar -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | grep -E "(error:|warning:)" || echo "Build successful"

# Archive for release (if needed)
xcodebuild archive -project HiCalendar.xcodeproj -scheme HiCalendar -archivePath HiCalendar.xcarchive
```

### Project Structure
- `HiCalendar/` - Main app source code
  - `Views/` - SwiftUI view components
  - Core managers and utilities at root level
- `HiCalendarTests/` - Unit tests  
- `HiCalendarUITests/` - UI tests
- `Docs/` - Design documentation and HTML demos
- `PRD.md` - Product requirements document (in Chinese)
- `APPLE_AUTH_SETUP.md` / `APPLE_SIGNIN_SETUP.md` - Apple Sign In configuration docs

## Code Architecture

### Authentication System
- **SupabaseManager.swift**: Handles Supabase authentication (email/password, Apple Sign In)
  - Currently uses mock implementation, real Supabase SDK integration ready
  - Manages user sessions and authentication state
- **AppleAuthManager.swift**: Native Apple Sign In implementation
  - Handles ASAuthorizationAppleIDProvider flow
  - Persists user credentials in UserDefaults
  - Supports nonce generation for secure authentication

### Core Data Models (`Models.swift`)
- **User**: User profile with email, timezone, and push notification preferences (sarcasm level removed)
- **Event**: Calendar events with advanced push reminder system
  - `intendedDate: Date?` - ✨新增: 事件归属日期，专门用于无时间事项的日期归属
  - `pushReminders: [PushReminderOption]` - 多种提醒时间选项数组
  - `pushDayBefore/pushWeekBefore: Bool` - 向后兼容的布尔开关
  - `pushStatus: PushStatus` - 推送状态跟踪 (dayBeforeSent, weekBeforeSent等)
- **PushReminderOption**: 枚举类型推送提醒选项
  - `.none, .atTime, .minutes15, .minutes30, .hours1, .hours2, .dayBefore, .weekBefore`
- **UserDevice**: 设备Token管理模型，支持多设备推送
- **AIResponse**: AI interaction results with conclusion, sarcasm, suggestions, and action types
- **CalendarDay**: Date representation with associated events for calendar views

### Data Management
- **EventStorageManager.swift**: Singleton for local event persistence with Supabase sync
  - ObservableObject for SwiftUI reactive updates
  - CRUD operations with date-based filtering
  - UserDefaults backend with sample data fallback
  - Supabase同步：`syncEventToSupabase()` 支持新旧数据库架构
  - Key methods: `loadEvents()`, `addEvent()`, `updateEvent()`, `deleteEvent()`, `eventsForDate()`
- **PushNotificationManager.swift**: 推送通知管理单例 (已移除sarcasm level)
  - ObservableObject for SwiftUI reactive updates
  - APNs权限管理和设备Token注册
  - 推送设置同步(dayBefore, weekBefore)
  - 与Supabase user_devices表集成
  - 支持测试推送和权限状态检查
  - 本地通知调度：处理短期提醒(at_time, 15min, 30min, 1hr, 2hr)
- **BackgroundImageManager.swift**: Custom background image handling
  - Image compression (JPEG 1.0 quality, 无压缩) and caching
  - UserDefaults storage for persistence
  - ObservableObject for reactive UI updates
- **ImageCropView.swift**: Custom image cropping interface for backgrounds

### Design System (`DesignTokens.swift`)
- **Neobrutalism aesthetic**: High contrast colors, bold borders (2-5pt), no shadows
- **Dark mode support**: Dynamic colors that adapt to system appearance  
- **Brand colors**: Bright yellow (#FFFF00), electric blue (#00BFFF), neon green, warning red
- **Typography**: Bold system fonts (.heavy, .black weights) for headers
- **Layout tokens**: Consistent spacing (4-32pt grid), button heights (44pt minimum)
- **Usage**: Access via `BrandColor`, `BrandFont`, `BrandSpacing` enums

### UI Architecture
- **View Layer**: SwiftUI views in `Views/` folder
  - `CalendarView.swift` - Month/week/day calendar with drag-to-reschedule
  - `EventEditView.swift` - Event CRUD with auto-save and多选推送提醒设置UI
    - 支持8种提醒时间选项的多选界面
    - 自动本地通知调度(短期提醒)
    - 展开/收起式推送设置卡片
  - `EventListView.swift` - Searchable event list with filtering
  - `HomeView.swift` - AI chat interface and daily summary
  - `MainCalendarAIView.swift` - Primary calendar view with AI integration and custom backgrounds  
  - `SettingsView.swift` - User preferences and push notification settings (sarcasm level已移除)
  - `EverythingsView.swift` - Event countdown with urgency indicators
- **Navigation**: `ContentView.swift` handles root TabView navigation
- **App Entry**: `HiCalendarApp.swift` configures app lifecycle and push notification AppDelegate
- **Component Library**: `UIComponents.swift` provides reusable Neobrutalism components

### Custom Material Design 3 UI Components (`UIComponents.swift`)
- **MD3ButtonStyle**: Filled/Tonal/Outlined/Text/Elevated button variants with proper MD3 styling
- **MD3FAB**: Floating Action Button with extended label support
- **MD3Chip**: Filter and choice chips for selection interfaces
- **MD3Card**: Elevated/Filled/Outlined card containers with proper elevation
- **MD3TextField**: Floating label text field with error states and helper text
- **ConflictBadge**: Status badges for event conflict indication
- **CalendarDayCell**: Enhanced calendar cell with event text display (not just dots)
- **ColorfulIcon**: Unified icon system with brand color gradients and semantic groupings
- **IndependentAIButton**: Standalone AI assistant button for new bottom bar layout

### Recent UI Component Enhancements
- **Calendar Event Display**: Changed from abstract dots to actual event text in calendar cells
- **Bottom Bar Redesign**: Split into `CustomTabBar` (tab switching) + `IndependentAIButton` (AI interaction)
- **Tab Selection**: Background now encompasses entire button area (icon + text)
- **Voice Recording**: Full-screen overlay with animated audio waves and real-time transcription

## Development Guidelines

### Architecture Patterns
- **MVVM**: ViewModels use ObservableObject for reactive updates
- **Singleton Pattern**: EventStorageManager, BackgroundImageManager for shared state
- **Data Flow**: UserDefaults → Manager → SwiftUI View (via @Published properties)

### Design System Integration
- **Mandatory**: Use `BrandColor`, `BrandFont`, `BrandSpacing` enums from `DesignTokens.swift`
- **Styling**: Apply `.neobrutalStyle()` modifier for consistent 3-5pt borders
- **Components**: Prefer custom components from `UIComponents.swift` over system defaults

### Data Management Standards
- **Event Operations**: Always use `EventStorageManager.shared` singleton
- **Event Structure**: Optional start/end times, mandatory title, optional details
- **intendedDate Field**: Critical for no-time events date attribution (fixes push timing issues)
- **Sample Data**: Use `Event.sampleEvents` for development and testing - designed for onboarding
- **Persistence**: UserDefaults with automatic JSON encoding/decoding
- **Supabase Sync**: Full bi-directional sync with cloud database

### AI Personality Implementation
- **Response Structure**: AIResponse with conclusion, sarcasm, suggestion, actionType
- **Sarcasm Style**: 固定为中度吐槽风格 (已移除用户可调节的吐槽等级)
- **Action Types**: create, query, modify, delete, conflict, unknown
- **Voice Integration**: AIVoiceManager handles speech-to-text and text-to-speech
- **Interaction Modes**: WeChat-style long press (voice) + tap (text chat)

### Permission Management Strategy
- **Push Notifications**: Delayed friendly prompt on app launch (1 second delay)
- **Voice Permissions**: On-demand request when user first uses AI voice feature
- **Graceful Degradation**: Voice denied → fallback to text chat
- **User-Centric**: No intrusive permission requests at startup

### Chinese Localization
- **Primary Language**: Chinese UI text for Chinese market
- **Timezone**: Default Asia/Shanghai, user-configurable
- **Sample Content**: Chinese event titles with appropriate emoji

## Technical Specifications

- **iOS Deployment Target**: 18.5+ (iPhone 16 simulator is primary test target)
- **Architecture**: MVVM + ObservableObject pattern
- **Data Persistence**: UserDefaults with JSON encoding (Supabase migration planned)
- **Key Dependencies**: 
  - AuthenticationServices (Apple Sign In)
  - PhotosUI (background image picker)
  - Supabase SDK (configured but using mock implementation)
- **Bundle Identifier**: com.chenzhencong.HiCalendar
- **Required Entitlements**: 
  - Sign in with Apple capability
  - Push Notifications (aps-environment: development/production)
- **Build Requirements**: Auto-compile verification required after code changes
- **APNs Integration**: Full push notification system with device token management

## Supabase Integration & Database Structure

### Authentication Setup
The app uses Supabase for authentication with Apple Sign In integration:
1. Real Supabase SDK implementation in `SupabaseManager.swift`
2. Apple Sign In service ID configured in Supabase dashboard
3. Bundle ID: `com.chenzhencong.HiCalendar`

### Database Schema (Supabase PostgreSQL)

#### Core Tables

**`auth.users`** (Supabase系统表)
- Supabase内置用户认证表，存储基础认证信息

**`public.users`** (用户扩展信息表)
```sql
- id: UUID (主键, 引用auth.users.id)
- email: TEXT (用户邮箱)
- timezone: TEXT (时区, 默认'Asia/Shanghai') 
- default_push_day_before: BOOLEAN (默认事件前1天推送, 默认true)
- default_push_week_before: BOOLEAN (默认事件前1周推送, 默认false)
- created_at/updated_at: TIMESTAMPTZ (创建/更新时间)
注: sarcasm_level字段已移除
```

**`events`** (日历事件表)
```sql
- id: UUID (主键)
- user_id: UUID (用户ID, 引用auth.users.id)
- title: TEXT (事件标题, 必填)
- start_at: TIMESTAMPTZ (开始时间, 可选)
- end_at: TIMESTAMPTZ (结束时间, 可选)
- details: TEXT (事件详情, 可选)
- intended_date: TIMESTAMPTZ (事件归属日期, 可选) - ✨新增字段
- push_reminders: TEXT[] (推送提醒选项数组)
- push_day_before: BOOLEAN (向后兼容: 事件前1天推送, 默认true)
- push_week_before: BOOLEAN (向后兼容: 事件前1周推送, 默认false)
- push_status: JSONB (推送状态记录, 默认{})
- created_at/updated_at: TIMESTAMPTZ (创建/更新时间)
```

**`user_devices`** (用户设备表 - APNs推送)
```sql
- id: UUID (主键)
- user_id: UUID (用户ID, 引用auth.users.id)
- device_token: TEXT (APNs设备Token, 唯一)
- platform: TEXT (平台标识, 默认'ios')
- is_active: BOOLEAN (设备是否活跃, 默认true)
- created_at/updated_at: TIMESTAMPTZ (创建/更新时间)
```

**`push_notifications`** (推送记录表)
```sql
- id: UUID (主键)
- user_id: UUID (用户ID, 引用auth.users.id)
- event_id: UUID (事件ID, 引用events.id)
- device_token: TEXT (推送的设备Token)
- type: TEXT (推送类型: 'day_before', 'week_before')
- message: TEXT (推送消息内容)
- sent_at: TIMESTAMPTZ (发送时间, 默认NOW())
- status: TEXT (发送状态: 'sent', 'failed', 'retry', 默认'sent')
- apns_response: TEXT (APNs响应信息, 用于调试)
```

**`push_templates`** (推送文案模板表) - 可选，目前使用硬编码模板
```sql
- id: UUID (主键)
- type: TEXT (推送类型: '1_day', '1_week', 'at_time', etc.)
- template: TEXT (文案模板, 使用{title}占位符)
- created_at: TIMESTAMPTZ (创建时间)
注: sarcasm_level字段已移除，使用固定中度吐槽风格
```

#### Row Level Security (RLS)策略
- **用户数据隔离**: 每个用户只能访问自己的数据
- **Service Role权限**: Edge Function可以管理推送记录
- **模板公开**: 推送文案模板对所有用户可读

#### 自动化功能
- **用户Profile自动创建**: 新用户注册时自动在public.users表创建记录
- **时间戳自动更新**: 所有表的updated_at字段自动维护
- **索引优化**: 关键查询字段(user_id, start_at, device_token等)建立索引

### Push Notification System

#### 推送架构 (混合架构)
- **本地推送**: iOS本地通知处理短期提醒(at_time, 15min, 30min, 1hr, 2hr)
- **服务端推送**: Edge Function处理长期提醒(1_day, 1_week)
- **APNs集成**: 通过Supabase Edge Function发送推送到APNs
- **定时调度**: 使用pg_cron每小时执行检查待推送事件 (`0 * * * *`)
- **设备管理**: 支持多设备Token管理和活跃状态跟踪
- **批量推送**: 支持同用户同类型多事件的批量推送消息

#### 推送文案示例 (固定中度吐槽风格)
```
单个事项:
- 1天前: "明天「会议」，别又临时找借口说忘了！"
- 1周前: "一周后「会议」，现在不准备待会儿又手忙脚乱？"

多个事项批量:
- 1天前: "明天「会议」、「培训」等3件事等着，忙死你了吧？"
- 1周前: "下周「会议」、「培训」等3个安排，别到时候又说没时间！"

无时间事项:
- 1天前: "别忘了「整理文件」这事儿，拖了这么久该动手了吧？"
```

### 相关文件
- `supabase/functions/push-scheduler/index.ts` - Edge Function推送调度器 (已部署)
- `info.md` - Supabase项目配置信息和访问凭证
- `HiCalendar.entitlements` - APNs推送权限配置
- `PushNotificationManager.swift` - iOS端推送管理器
- `EventStorageManager.swift` - 事件存储与Supabase同步

#### Supabase配置信息
- **项目ID**: ngzzciukzokypzzpcbvj
- **区域**: Southeast Asia (Singapore)
- **Cron任务**: push-notification-scheduler (每小时执行)
- **Edge Function**: push-scheduler (Version 8, ACTIVE)
- **数据库**: 已添加push_reminders字段支持

## Core Product Features (from PRD.md)

- **Natural Language AI**: One-sentence event creation/query/modification
- **Sarcastic AI Personality**: 固定中度吐槽风格 (不再用户可调节)
- **Smart Conflict Detection**: Hard/soft conflicts with alternative suggestions
- **Advanced Push Notifications**: 8种提醒时间选项的混合推送架构
  - 短期提醒: 本地通知 (准点, 15分钟前, 30分钟前, 1小时前, 2小时前)
  - 长期提醒: 服务端推送 (1天前, 1周前)
  - 批量消息: 智能合并同用户同类型推送
- **Neobrutalism UI**: High contrast "Cute Style" design aesthetic
- **Chinese Market Focus**: Primary UI language and cultural adaptation

## Development Workflow & CLI Tools

### Supabase CLI配置
```bash
# 环境变量设置
export SUPABASE_ACCESS_TOKEN="sbp_e0cb607213c322adb626e7fedef7d958e45eaf36"

# 项目操作
supabase projects list
supabase functions list --project-ref ngzzciukzokypzzpcbvj
supabase link --project-ref ngzzciukzokypzzpcbvj

# 数据库连接
psql "postgresql://postgres.ngzzciukzokypzzpcbvj:GgUFBSOifzhTqt0j@aws-1-ap-southeast-1.pooler.supabase.com:5432/postgres"

# 或使用Homebrew PostgreSQL客户端
/opt/homebrew/opt/postgresql@15/bin/psql "connection_string"
```

### 推送系统调试
```bash
# 检查Cron任务状态
SELECT * FROM cron.job WHERE jobname LIKE '%push%';

# 查看推送历史
SELECT * FROM push_notifications ORDER BY sent_at DESC LIMIT 10;

# 检查用户设备Token
SELECT user_id, device_token, is_active FROM user_devices;

# 分析事件推送时机
SELECT id, title, start_at, push_reminders, push_status 
FROM events WHERE id = '具体事件ID';
```

## Recent Updates & Bug Fixes

### 🎯 全面UI/UX优化 (2025-09-04)

#### AI语音系统完善
- **WeChat风格交互**: 长按AI按钮0.5秒录音，短按文字对话
- **录音蒙层**: 全屏录音界面，实时音波动画和语音识别显示
- **权限优化**: 启动时推送权限弹框，首次使用AI时语音权限请求
- **语音管理**: AIVoiceManager单例管理所有语音功能

#### 底部栏布局重设计
- **新布局**: `[看日子 ----- 全部安排] [AI助手]` - AI助手独立右侧
- **功能分组**: 左侧Tab切换组，右侧AI交互按钮
- **选中背景**: 优化为包含图标+文字的完整按钮区域背景
- **视觉层级**: AI助手独立背景，功能归属更明确

#### 日历显示增强
- **事项文本显示**: 日历格子内显示具体事项标题（最多2个）
- **彩色标签**: 不同事项使用品牌色系轮换背景
- **信息密度**: 从抽象点状指示器改为直观文本显示
- **响应式布局**: 适配不同状态（选中/今天/普通）的颜色方案

#### 样本事项引导策略
- **Onboarding设计**: 今天体验功能 + 后天推送演示
- **留存策略**: 后天事项在明天推送，展示推送功能并提升留存
- **核心引导**: AI交互学习、真实使用习惯建立、个性化设置

#### 权限管理优化
- **用户友好**: 移除启动时自动弹框，改为用户交互时按需请求
- **推送权限**: 延迟1秒友好弹框，可选择"开启"或"稍后"
- **语音权限**: 首次长按AI按钮时请求，拒绝后降级到文字聊天
- **权限检查**: 启动时静默检查状态，不干扰用户

#### 图标色彩系统统一
- **ColorfulIcon系统**: 统一所有图标色彩，基于品牌色系
- **视觉层级**: 主要功能(蓝色系)，功能性(中性灰)，提醒类(暖色系)
- **一致性**: 底部栏、工具栏、按钮图标使用统一色彩语言

### 💰 会员数据同步系统实现 (2025-09-16)

#### 会员功能完整实现
- **数据保护**: 会员用户数据自动云端备份，防止数据丢失
- **智能同步**: 登录时自动同步本地数据到云端，下载云端数据到本地
- **权限控制**: 云同步功能仅限会员使用，非会员不会上传数据
- **Onboarding过滤**: 系统生成的引导事项不会同步到云端

#### 核心实现组件
1. **MemberDataSyncManager.swift**: 会员数据同步管理器
   - 完整数据同步（会员登录时）
   - 增量同步（定期后台同步）
   - 网络状态监控和重试机制
   - 数据去重和冲突解决

2. **SupabaseManager.swift 增强**:
   - 真实的 `fetchAllEvents()` 实现，替换模拟数据
   - 云端删除和更新方法：`deleteCloudEvent()`, `updateCloudEvent()`
   - Onboarding事项过滤，防止样本数据污染云端
   - 会员状态检查和权限控制

3. **设置页面重构 (SettingsView.swift)**:
   - 根据登录状态显示不同内容
   - 未登录：仅显示登录引导和功能介绍
   - 已登录：显示完整设置选项
   - 登录前推送权限检查流程

#### 登录引导优化
- **智能横幅**: 首次安装时显示登录引导横幅
- **视觉设计**: 参考底部导航栏样式，毛玻璃背景+渐变边框
- **响应式宽度**: 95%屏幕宽度，居中显示
- **用户体验**: 点击登录或关闭后不再显示

#### 权限管理流程
- **推送权限**: 登录前检查并请求推送权限
- **系统弹框**: 直接使用系统权限弹框，避免重复请求
- **优雅降级**: 权限被拒绝时仍可正常登录

### 🔥 推送系统核心架构重构 (2025-09-02)

#### 问题背景
推送通知系统存在根本性设计缺陷：使用`created_at`字段既作为事件创建时间戳，又作为无时间事项的日期归属判断依据，导致推送时机计算错误。

**核心问题**: 今天创建的其他日期的卡片，系统会错误地按创建时间而非事件归属日期来计算推送时机。

#### 解决方案: `intendedDate`字段重构

**✅ 已完成的重构任务:**

1. **Event模型更新 (`Models.swift`)**
   - 新增 `intendedDate: Date?` 字段，专门用于无时间事项的日期归属
   - 更新所有初始化方法以支持新字段
   - 保持向后兼容性

2. **Edge Function重构 (`supabase/functions/push-scheduler/index.ts`)**
   - 更新 `interface Event` 添加 `intended_date: string | null`
   - 重构 `queryEventsNeedingNotification()` 推送判断逻辑
   - 重构 `groupEventsByUserAndType()` 批量推送逻辑
   - **推送时机判断逻辑**:
     - 有时间事项: 使用 `start_at` 字段
     - 无时间事项: 优先使用 `intended_date`，如为空则回退到 `created_at` (向后兼容)
   - 部署新版本Edge Function

3. **iOS同步逻辑更新**
   - `EventStorageManager.swift`: 更新 `EventDataWithReminders` 和 `EventDataLegacy` 结构
   - `SupabaseManager.swift`: 更新批量同步逻辑
   - 确保 `intended_date` 字段在所有同步场景中被正确传输

4. **数据库架构更新**
   - 在 `events` 表添加 `intended_date TIMESTAMPTZ` 字段
   - 保持与现有数据的完全兼容性

#### 技术实现细节

**推送时机计算逻辑 (更新后)**:
```typescript
// 无时间事件的日期确定
if (event.intended_date) {
  // 优先使用intended_date
  const intendedDate = new Date(event.intended_date)
  eventDate = new Date(intendedDate.getFullYear(), intendedDate.getMonth(), intendedDate.getDate(), 0, 0, 0)
} else {
  // 向后兼容：回退到created_at
  const createdDate = new Date(event.created_at)
  eventDate = new Date(createdDate.getFullYear(), createdDate.getMonth(), createdDate.getDate(), 0, 0, 0)
}
```

**数据同步结构 (iOS)**:
```swift
struct EventDataWithReminders: Codable {
  let intended_date: String?  // 新增字段
  // ... 其他字段保持不变
}
```

#### 向后兼容性保证
- 旧版本事件(`intended_date` 为空)会自动回退到使用 `created_at` 进行推送判断
- 所有现有推送逻辑保持不变，仅增强无时间事项的日期归属精度
- 数据库架构向后兼容，无需数据迁移

#### 修复的问题场景
- ✅ 今天创建明天的无时间事项 → 今天收到1天前提醒 (之前: 明天收到)
- ✅ 本周创建下周的无时间事项 → 提前1周收到提醒 (之前: 本周收到)
- ✅ 批量推送消息准确性提升，按真实事件归属日期分组

## Special Instructions

- 中文回复我 (Respond in Chinese)
- Git operations only when explicitly requested with "git" command
- **MANDATORY**: Auto-compile after coding changes using iPhone 16 simulator target
- Test both light/dark modes for design system compliance
- 推送系统使用混合架构：本地+服务端相结合
- 所有数据库操作优先使用PostgreSQL直连，CLI作为备选