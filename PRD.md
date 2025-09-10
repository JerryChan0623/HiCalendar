# HiCalendar - Cute Calendar AI 产品需求文档 (PRD)

**版本**: v2.1  
**日期**: 2025-09-04  
**状态**: 开发中 (核心功能已完成80%)

---

## 1. 产品概述

### 1.1 产品定位
HiCalendar是一款面向中国市场的"可爱日历AI"iOS应用，通过自然语言AI交互帮助用户管理日程，采用Neobrutalism设计风格，具备讽刺幽默的AI人格。

### 1.2 核心价值
- **自然语言交互**: 一句话创建、查询、修改日程
- **智能推送系统**: 8种提醒方式的混合推送架构
- **个性化AI助手**: 固定中度吐槽风格，提升用户粘性
- **本地优先存储**: 快速响应，离线可用

---

## 2. 功能架构

### 2.1 技术架构图
```
┌─────────────────────────────────────┐
│           iOS SwiftUI 前端           │
├─────────────────────────────────────┤
│ • EventStorageManager (本地优先)     │
│ • PushNotificationManager (混合推送) │  
│ • BackgroundImageManager (个性化)    │
│ • SupabaseManager (云端同步)        │
├─────────────────────────────────────┤
│          Supabase 后端服务           │
│ • PostgreSQL (用户数据)             │
│ • Edge Functions (推送调度)         │
│ • APNs集成 (推送通道)               │
│ • pg_cron (定时任务)                │
└─────────────────────────────────────┘
```

### 2.2 数据流架构
```
用户操作 → 本地存储 → 后台同步 → 推送调度 → APNs → 设备通知
   ↓         ↓         ↓         ↓        ↓        ↓
SwiftUI → UserDefaults → Supabase → Edge Function → Apple → 用户
```

---

## 3. 核心功能模块

### 3.1 AI聊天模块 (`AIChatView`)

#### 功能描述
智能对话界面，支持自然语言创建和管理日程事项。

#### 技术实现
**接口**: `AIResponse`模型  
**逻辑**: 本地NLP解析 + 固定吐槽回复模板  
**存储**: 会话历史存储在UserDefaults

#### 页面功能
- ✅ **自然语言输入**: "明天下午2点开会"
- ✅ **智能事项创建**: 自动解析时间、标题、详情
- ✅ **吐槽风格回复**: "又要开会？你们公司会议真多 🙄"
- ✅ **快速操作建议**: 提供相关操作按钮

#### API接口
```swift
struct AIResponse: Codable {
    let conclusion: String    // AI主要回复
    let sarcasm: String      // 吐槽内容（固定中度风格）
    let suggestion: String   // 操作建议
    let actionType: String   // 操作类型
}
```

### 3.2 日历视图模块 (`MainCalendarAIView`)

#### 功能描述
主要日历界面，支持月/周/日视图切换，事项的可视化管理。

#### 技术实现
**框架**: SwiftUI Calendar组件  
**数据源**: `EventStorageManager.shared.events`  
**实时更新**: `@ObservedObject` 响应式更新

#### 页面功能
- ✅ **多视图切换**: 月视图(默认)、周视图、日视图
- ✅ **快速创建**: 点击日期快速添加无时间事项
- ✅ **拖拽重新安排**: 事项卡片支持拖拽改期
- ✅ **自定义背景**: 支持用户上传个人背景图片
- ✅ **事项状态展示**: 颜色编码显示事项类型和紧急程度

#### 关键接口
```swift
// 事项筛选接口
func eventsForDate(_ date: Date) -> [Event]

// 快速创建接口  
func createEvent(title: String, date: Date) -> Event

// 拖拽更新接口
func updateEventDate(event: Event, newDate: Date)
```

### 3.3 事项编辑模块 (`EventEditView`)

#### 功能描述
完整的事项编辑界面，支持详细时间、推送设置、内容编辑。

#### 技术实现
**模式**: `.create` 创建模式 / `.edit(Event)` 编辑模式  
**自动保存**: 延迟0.5秒自动保存机制  
**推送集成**: 集成本地通知调度

#### 页面功能
- ✅ **完整时间设置**: 开始时间、结束时间、无时间选项
- ✅ **多级推送提醒**: 8种提醒时间的多选界面
- ✅ **实时预览**: 推送设置的可视化展示
- ✅ **智能归属日期**: 无时间事项的日期归属设置
- ✅ **自动保存**: 编辑过程中自动持久化

#### 推送设置界面
```swift
// 8种推送提醒选项
enum PushReminderOption: String, CaseIterable {
    case none = "none"           // 不提醒
    case atTime = "at_time"      // 准点提醒
    case minutes15 = "15_minutes" // 15分钟前  
    case minutes30 = "30_minutes" // 30分钟前
    case hours1 = "1_hour"       // 1小时前
    case hours2 = "2_hours"      // 2小时前
    case dayBefore = "1_day"     // 1天前
    case weekBefore = "1_week"   // 1周前
}
```

### 3.4 紧急事项模块 (`EverythingsView`)

#### 功能描述
展示所有未完成事项的倒计时视图，按紧急程度排序。

#### 技术实现
**排序逻辑**: 距离当前时间越近优先级越高  
**实时倒计时**: Timer每秒更新显示  
**紧急度指示**: 颜色渐变表示紧急程度

#### 页面功能
- ✅ **倒计时显示**: "还有2天3小时"的动态倒计时
- ✅ **紧急度排序**: 红色(紧急) → 黄色(注意) → 绿色(正常)
- ✅ **快速操作**: 长按删除、点击编辑
- ✅ **无事项状态**: 友好的空状态提示

### 3.5 设置模块 (`SettingsView`)

#### 功能描述
用户偏好设置、推送权限管理、账户信息管理。

#### 技术实现
**推送管理**: `PushNotificationManager` 集成  
**账户系统**: Supabase Authentication  
**偏好存储**: UserDefaults持久化

#### 页面功能
- ✅ **推送权限设置**: 系统权限状态检查和引导
- ✅ **默认推送偏好**: 新事项的默认推送设置
- ✅ **账户信息**: Apple Sign In集成
- ✅ **数据管理**: 清空本地数据选项
- ❌ **主题设置**: 计划支持深色/浅色模式切换

---

## 4. 数据模型设计

### 4.1 核心数据模型

#### Event (事项模型)
```swift
struct Event: Codable, Identifiable {
    let id: UUID
    var title: String                    // 事项标题
    var startAt: Date?                   // 开始时间(可选)
    var endAt: Date?                     // 结束时间(可选)  
    var details: String?                 // 详情(可选)
    let createdAt: Date                  // 创建时间
    var intendedDate: Date?              // 归属日期(无时间事项专用)
    var pushReminders: [PushReminderOption] // 推送提醒数组
    var pushStatus: PushStatus           // 推送状态跟踪
    var isSynced: Bool                   // 同步状态(防重复同步)
}
```

#### User (用户模型)
```swift
struct User: Codable, Identifiable {
    let id: UUID
    let email: String
    var timezone: String                 // 时区设置
    var defaultPushDayBefore: Bool       // 默认1天前推送
    var defaultPushWeekBefore: Bool      // 默认1周前推送
}
```

### 4.2 数据库设计 (PostgreSQL)

#### events表结构
```sql
CREATE TABLE events (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id),
    title TEXT NOT NULL,
    start_at TIMESTAMPTZ,
    end_at TIMESTAMPTZ,  
    details TEXT,
    intended_date TIMESTAMPTZ,           -- 新增：归属日期字段
    push_reminders TEXT[],               -- 推送选项数组
    push_day_before BOOLEAN DEFAULT true, -- 向后兼容
    push_week_before BOOLEAN DEFAULT false,
    push_status JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## 5. 推送通知系统

### 5.1 混合推送架构

#### 架构设计理念
采用**本地 + 服务端**混合推送，确保准确性和可靠性：

```
短期提醒 (本地通知)     长期提醒 (服务端推送)
├─ 准点提醒             ├─ 1天前提醒  
├─ 15分钟前             └─ 1周前提醒
├─ 30分钟前                    ↓
├─ 1小时前              Edge Function调度
└─ 2小时前              (pg_cron每5分钟)
       ↓                        ↓
iOS本地通知调度          APNs推送服务
```

### 5.2 技术实现

#### 本地推送 (`PushNotificationManager`)
```swift
// 本地通知调度
func scheduleLocalNotifications(for event: Event) {
    event.pushReminders.forEach { reminder in
        if isShortTermReminder(reminder) {
            scheduleLocalNotification(event: event, reminder: reminder)
        }
    }
}
```

#### 服务端推送 (Edge Function)
```typescript
// 推送调度逻辑 (每5分钟执行)
const events = await queryEventsNeedingNotification()
const notifications = groupEventsByUserAndType(events)
await sendBatchNotifications(notifications)
```

### 5.3 推送文案系统
**固定中度吐槽风格**，不再支持用户调节：

```javascript
// 推送文案模板
const templates = {
  "1_day_single": "明天「{title}」，别又临时找借口说忘了！",
  "1_day_batch": "明天「{title}」、「{title2}」等{count}件事等着，忙死你了吧？",
  "1_week_single": "一周后「{title}」，现在不准备待会儿又手忙脚乱？"
}
```

---

## 6. 技术栈与依赖

### 6.1 iOS客户端
- **框架**: SwiftUI (iOS 18.5+)
- **架构**: MVVM + ObservableObject
- **存储**: UserDefaults (本地优先) + Supabase (云同步)
- **推送**: UserNotifications + APNs
- **认证**: AuthenticationServices (Apple Sign In)

### 6.2 后端服务
- **数据库**: Supabase PostgreSQL
- **实时同步**: Supabase Realtime
- **推送调度**: Edge Functions + pg_cron  
- **认证**: Supabase Auth (Apple Provider)

### 6.3 关键依赖版本
```
- iOS Deployment Target: 18.5+
- Supabase-swift: ^2.x  
- Bundle ID: com.chenzhencong.HiCalendar
- APNs Environment: development (测试) / production (发布)
```

---

## 7. 开发状态与路线图

### 7.1 当前完成状态 (80%)

#### ✅ 已完成功能
- [x] 核心事项CRUD操作
- [x] AI自然语言交互  
- [x] 多视图日历界面
- [x] 8种推送提醒设置
- [x] 混合推送架构 (本地+服务端)
- [x] Apple Sign In认证
- [x] Supabase数据同步
- [x] 防重复同步机制 (`isSynced`字段)
- [x] 自定义背景图片
- [x] Neobrutalism设计系统

#### 🔄 进行中功能  
- [ ] APNs推送调试 (逻辑完成，设备接收待调试)
- [ ] 推送权限优化引导
- [ ] 事项拖拽重新安排

#### 📋 待开发功能
- [ ] 事项分类和标签系统
- [ ] 日程冲突检测优化  
- [ ] 数据导入导出功能
- [ ] Widget小组件支持
- [ ] 国际化支持 (英文版)

### 7.2 技术债务
- [ ] 单元测试覆盖率提升 (当前<30%)
- [ ] 性能优化 (大量事项场景)
- [ ] 错误处理机制完善
- [ ] 离线模式优化

---

## 8. API接口文档

### 8.1 本地存储接口

#### EventStorageManager
```swift
class EventStorageManager: ObservableObject {
    // 事项管理
    func addEvent(_ event: Event)
    func updateEvent(_ updatedEvent: Event)  
    func deleteEvent(_ event: Event)
    func eventsForDate(_ date: Date) -> [Event]
    
    // 快速创建
    func createEvent(title: String, date: Date) -> Event
    func createEvent(title: String, date: Date, startAt: Date?, 
                    endAt: Date?, details: String?) -> Event
    
    // 同步管理
    private func syncEventToSupabase(_ event: Event) async
    private func markEventAsSynced(_ eventId: UUID)
}
```

### 8.2 推送通知接口

#### PushNotificationManager
```swift
class PushNotificationManager: ObservableObject {
    // 权限管理
    func requestNotificationPermission() async -> Bool
    func checkNotificationStatus() async -> UNAuthorizationStatus
    
    // 本地通知
    func scheduleLocalNotifications(for event: Event)
    func cancelLocalNotifications(for event: Event)
    
    // 设备Token管理
    func updateDeviceToken(_ token: String) async
    func syncPushSettingsToSupabase() async
}
```

### 8.3 Supabase API接口

#### 事项同步
```typescript
// POST /functions/v1/sync-event
{
  "id": "uuid",
  "user_id": "uuid", 
  "title": "事项标题",
  "start_at": "2025-09-04T10:00:00Z",
  "end_at": "2025-09-04T11:00:00Z",
  "intended_date": "2025-09-04T00:00:00Z",  // 新增
  "push_reminders": ["1_day", "at_time"],
  "push_status": {"day_before_sent": false}
}
```

#### 推送调度
```typescript  
// POST /functions/v1/push-scheduler (Cron调用)
{
  "scheduled": true,
  "timestamp": 1725434221
}

// Response
{
  "success": true,
  "sent": 3,
  "failed": 0, 
  "total": 3
}
```

---

## 9. 性能指标与监控

### 9.1 性能目标
- **启动时间**: < 2秒 (冷启动)
- **事项创建**: < 500ms (本地响应)
- **推送延迟**: < 5分钟 (长期提醒)
- **同步成功率**: > 95% (有网络环境)

### 9.2 监控指标
- 事项创建/编辑/删除成功率
- 推送发送成功率和到达率
- Supabase API调用延迟
- 用户留存率和活跃度

---

## 10. 安全与隐私

### 10.1 数据安全
- **本地加密**: UserDefaults敏感数据加密存储
- **传输安全**: HTTPS + SSL证书验证
- **认证机制**: JWT Token + Apple Sign In
- **权限控制**: Row Level Security (RLS)

### 10.2 隐私保护
- **数据最小化**: 仅收集必要的事项和推送数据
- **用户控制**: 支持数据删除和账户注销
- **透明度**: 明确的隐私政策和数据使用说明

---

## 11. 部署与发布

### 11.1 环境配置
```bash
# 开发环境
SUPABASE_URL=https://ngzzciukzokypzzpcbvj.supabase.co
APNS_ENVIRONMENT=development

# 生产环境  
SUPABASE_URL=https://ngzzciukzokypzzpcbvj.supabase.co
APNS_ENVIRONMENT=production
```

### 11.2 发布检查清单
- [ ] APNs生产证书配置
- [ ] App Store审核指南符合性
- [ ] 隐私标签和权限说明
- [ ] 本地化资源完整性
- [ ] 性能测试和兼容性验证

---

**文档维护者**: Claude Code  
**最后更新**: 2025-09-04  
**下次评审**: 2025-09-11