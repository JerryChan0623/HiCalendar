# CLAUDE.md - HiCalendar Push Scheduler Edge Function

This file provides guidance to Claude Code when working with the HiCalendar push notification Edge Function.

## Function Overview

`push-scheduler` 是HiCalendar的核心推送调度Edge Function，负责：
- 检查需要推送的事项
- 发送APNs推送通知 
- 更新推送状态
- 批量处理优化
- 清理历史数据

## Architecture

### 混合推送架构
- **本地推送**: iOS本地通知处理短期提醒 (`at_time`, `15_minutes`, `30_minutes`, `1_hour`, `2_hours`)
- **服务端推送**: Edge Function处理长期提醒 (`1_day`, `1_week`)
- **定时调度**: pg_cron每5分钟执行一次 (`*/5 * * * *`)

### Core Components

1. **Event Query System** (`queryEventsNeedingNotification`)
   - 支持有时间事项 (`start_at`) 和无时间事项 (`intended_date`)
   - 使用 `intendedDate` 字段解决日期归属问题
   - 智能时间差计算和推送时机判断

2. **Batch Processing System** (`groupEventsByUserAndType`)  
   - 按用户和提醒类型分组
   - 批量消息生成和发送
   - 减少推送频次，提升用户体验

3. **APNs Integration** (`sendPushNotification`)
   - JWT token生成 (ES256算法)
   - HTTP/2 APNs连接
   - 沙盒/生产环境自适应

4. **Status Management** (`markBatchNotificationAsSent`)
   - **新系统**: `1_day_sent`, `1_week_sent` 字段
   - **向后兼容**: `day_before_sent`, `week_before_sent` 字段
   - 防重复推送机制

## Data Structures

### Event Interface
```typescript
interface Event {
  id: string
  title: string
  start_at: string | null           // 有时间事项的开始时间
  intended_date: string | null      // ✨新增：无时间事项的归属日期
  user_id: string
  push_reminders: string[]          // ['1_day', '1_week', 'at_time', etc.]
  push_day_before: boolean          // 向后兼容字段
  push_week_before: boolean         // 向后兼容字段
  push_status: any                  // 推送状态记录
}
```

### Push Reminder Types
- `'1_day'` - 1天前提醒 (服务端处理)
- `'1_week'` - 1周前提醒 (服务端处理)
- `'at_time'` - 准点提醒 (iOS本地处理)
- `'15_minutes'` - 15分钟前 (iOS本地处理)  
- `'30_minutes'` - 30分钟前 (iOS本地处理)
- `'1_hour'` - 1小时前 (iOS本地处理)
- `'2_hours'` - 2小时前 (iOS本地处理)

## Configuration

### Environment Variables (Supabase Secrets)
```
SUPABASE_URL                 - Supabase项目URL
SUPABASE_SERVICE_ROLE_KEY    - 服务角色密钥
APNS_KEY_ID                  - Apple Push服务Key ID
APNS_TEAM_ID                 - Apple开发者团队ID  
APNS_PRIVATE_KEY             - APNs私钥 (ES256格式)
```

### APNs Settings
```typescript
const BUNDLE_ID = 'com.chenzhencong.HiCalendar'
const APNS_HOST = 'api.sandbox.push.apple.com'  // 开发环境
// const APNS_HOST = 'api.push.apple.com'       // 生产环境
```

## Database Schema Dependencies

### Required Tables
- `events` - 事项表，包含push_reminders和push_status字段
- `users` - 用户表，包含时区和推送偏好设置
- `user_devices` - 设备Token管理表
- `push_notifications` - 推送记录日志表

### Critical Fields
```sql
-- events表的关键字段
intended_date: TIMESTAMPTZ        -- ✨核心：无时间事项的日期归属
push_reminders: TEXT[]            -- 推送提醒选项数组
push_status: JSONB                -- 推送状态 {"1_day_sent": false, "1_week_sent": false}

-- user_devices表
device_token: TEXT                -- APNs设备Token
is_active: BOOLEAN                -- 设备活跃状态
```

## Push Message Templates (固定中度吐槽风格)

### 单个事项
```typescript
const templates = {
  '1_day': `明天「${title}」，别又临时找借口说忘了！`,
  '1_week': `一周后「${title}」，现在不准备待会儿又手忙脚乱？`
}
```

### 批量事项
```typescript
const templates = {
  '1_day': `明天${titleText}等${count}件事等着，忙死你了吧？`,
  '1_week': `下周${titleText}等${count}个安排，别到时候又说没时间！`
}
```

### 无时间事项
```typescript
const templates = {
  '1_day': `别忘了「${title}」这事儿，拖了这么久该动手了吧？`,
  '1_week': `「${title}」都一周了还没搞，再不动手就凉了！`
}
```

## Development & Debugging

### Deployment
```bash
# 部署到Supabase
supabase functions deploy push-scheduler --project-ref ngzzciukzokypzzpcbvj

# 查看函数日志
supabase functions logs push-scheduler --project-ref ngzzciukzokypzzpcbvj
```

### Database Testing
```sql
-- 手动触发推送测试
SELECT http(
    ('POST', 
     'https://ngzzciukzokypzzpcbvj.supabase.co/functions/v1/push-scheduler',
     ARRAY[http_header('Authorization', 'Bearer SERVICE_ROLE_KEY')],
     'application/json',
     '{"scheduled": true, "timestamp": ' || extract(epoch from now()) || '}')::http_request
);

-- 检查cron任务状态
SELECT jobname, schedule, active FROM cron.job WHERE jobname = 'hicalendar-push-scheduler';

-- 查看推送记录
SELECT user_id, type, message, status, sent_at FROM push_notifications ORDER BY sent_at DESC LIMIT 5;
```

### Common Issues & Solutions

#### 1. Cron任务执行失败
**症状**: `ERROR: function http_post(...) does not exist`
**原因**: PostgreSQL http扩展函数签名错误
**解决**: 使用 `http((...args)::http_request)` 而非 `http_post(..., ARRAY[headers])`

#### 2. 重复推送问题  
**症状**: 同一事项重复收到推送通知
**原因**: `getUpdateKeyForReminderType()` 返回错误的字段名
**解决**: 确保新系统使用 `1_day_sent`, `1_week_sent` 字段名

#### 3. 无时间事项推送时机错误
**症状**: 今天创建明天的事项，今天就收到提醒
**原因**: 使用 `created_at` 而非 `intended_date` 计算推送时机  
**解决**: 优先使用 `intended_date` 字段，回退到 `created_at`

#### 4. APNs连接失败
**症状**: `APNs error 403: Forbidden`  
**原因**: JWT token生成错误或设备Token无效
**解决**: 检查APNs密钥配置和设备Token注册状态

## Testing Strategy

### Unit Testing
- 测试推送时机判断逻辑
- 验证批量消息生成
- 检查状态更新正确性

### Integration Testing  
- 端到端推送流程测试
- APNs沙盒环境验证
- 数据库状态一致性检查

### Production Monitoring
- 推送成功率监控
- Cron任务执行状态
- 错误日志分析和告警

## Performance Optimization

### Batch Processing
- 同用户同类型事项批量推送
- 减少APNs请求次数
- 优化数据库查询性能

### Data Cleanup  
- 定期清理30天前推送记录
- 重置过期事项推送状态
- 维护数据库索引优化

## Security Considerations

- APNs私钥安全存储在Supabase Secrets
- JWT token定期刷新 (1小时过期)
- RLS策略保护用户数据隔离
- 设备Token去重和验证

---

**最后更新**: 2025-09-04  
**版本**: v9 (修复push_status更新错误)
**维护者**: Claude Code AI Assistant

## Development Notes

当修改此Edge Function时，请注意：
1. **状态一致性**: 确保推送查询逻辑与状态更新逻辑使用相同字段名
2. **时区处理**: 所有时间计算使用UTC，避免时区转换问题  
3. **错误处理**: 添加适当的try-catch和日志记录
4. **向后兼容**: 保持对旧数据结构的兼容性支持
5. **测试覆盖**: 修改后务必进行端到端测试验证