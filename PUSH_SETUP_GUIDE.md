# 🔔 HiCalendar推送通知部署指南

这是HiCalendar推送通知系统的完整部署指南，包含所有必需的步骤和配置。

## 📋 部署检查清单

- [ ] Apple Developer配置
- [ ] Supabase数据库设置  
- [ ] Edge Function部署
- [ ] 环境变量配置
- [ ] Cron定时任务设置
- [ ] iOS项目配置

## 🍎 1. Apple Developer配置

### 1.1 创建APNs Auth Key
1. 登录 [Apple Developer Console](https://developer.apple.com/)
2. 进入 Certificates, Identifiers & Profiles
3. 选择 Keys → 点击 + 创建新Key
4. 选择 Apple Push Notifications service (APNs)
5. 下载 `.p8` 私钥文件
6. 记录 **Key ID** 和 **Team ID**

### 1.2 配置App ID
1. 进入 Identifiers → App IDs
2. 找到你的App ID (`com.chenzhencong.HiCalendar`)
3. 确保勾选 **Push Notifications**
4. 点击 Configure 配置推送证书

### 1.3 更新Provisioning Profile
1. 进入 Profiles → Development/Distribution
2. 重新生成包含推送权限的Provisioning Profile
3. 下载并安装到Xcode

## 🗄️ 2. Supabase数据库设置

### 2.1 执行数据库迁移
1. 登录 [Supabase控制台](https://app.supabase.com)
2. 进入你的项目 SQL编辑器
3. 执行 `supabase_push_setup.sql` 文件中的所有SQL语句

```sql
-- 创建用户设备表
CREATE TABLE user_devices (...);

-- 扩展事件表
ALTER TABLE events ADD COLUMN push_day_before BOOLEAN DEFAULT true;

-- 更多SQL语句...
```

### 2.2 验证数据库表
执行以下查询验证表结构：
```sql
-- 检查表是否创建成功
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('user_devices', 'push_notifications', 'push_templates');

-- 检查事件表字段
SELECT column_name, data_type FROM information_schema.columns 
WHERE table_name = 'events' 
AND column_name LIKE 'push_%';
```

## ⚡ 3. Edge Function部署

### 3.1 安装Supabase CLI
```bash
npm install -g supabase
```

### 3.2 初始化项目
```bash
cd /path/to/HiCalendar
supabase init
```

### 3.3 部署Edge Function
```bash
# 部署push-scheduler函数
supabase functions deploy push-scheduler

# 验证部署
supabase functions list
```

### 3.4 测试Edge Function
```bash
# 手动触发测试
curl -X POST 'https://your-project.supabase.co/functions/v1/push-scheduler' \
  -H 'Authorization: Bearer your-anon-key' \
  -H 'Content-Type: application/json' \
  -d '{"test": true}'
```

## 🔐 4. 环境变量配置

### 4.1 在Supabase控制台设置环境变量
进入 Settings → Edge Functions，添加以下环境变量：

```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
APNS_KEY_ID=your-apns-key-id
APNS_TEAM_ID=your-team-id  
APNS_PRIVATE_KEY=-----BEGIN PRIVATE KEY-----
your-private-key-content
-----END PRIVATE KEY-----
```

### 4.2 获取必需的值

#### APNS_KEY_ID
从Apple Developer控制台的Key详情页获取

#### APNS_TEAM_ID  
从Apple Developer控制台的Membership页获取

#### APNS_PRIVATE_KEY
打开下载的 `.p8` 文件，复制完整内容：
```
-----BEGIN PRIVATE KEY-----
MIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQg...
-----END PRIVATE KEY-----
```

#### SUPABASE_SERVICE_ROLE_KEY
从Supabase控制台 Settings → API 获取

## ⏰ 5. Cron定时任务设置

### 5.1 执行Cron设置脚本
1. 在Supabase SQL编辑器中执行 `supabase_cron_setup.sql`
2. **重要**: 替换脚本中的占位符：
   - `https://your-project.supabase.co` → 你的实际项目URL
   - `your-service-role-key` → 你的Service Role Key

### 5.2 验证定时任务
```sql
-- 查看定时任务状态
SELECT jobname, schedule, active FROM cron.job 
WHERE jobname = 'hicalendar-push-scheduler';

-- 查看执行历史
SELECT * FROM cron.job_run_details 
WHERE jobname = 'hicalendar-push-scheduler'
ORDER BY start_time DESC LIMIT 5;
```

## 📱 6. iOS项目配置

### 6.1 添加推送权限
在 `HiCalendar.entitlements` 中确保包含：
```xml
<key>aps-environment</key>
<string>development</string> <!-- 生产环境用 production -->
```

### 6.2 更新Bundle ID配置
确保Xcode项目中的Bundle ID与Supabase中配置的一致：
- `com.chenzhencong.HiCalendar`

### 6.3 编译验证
```bash
xcodebuild -project HiCalendar.xcodeproj \
  -scheme HiCalendar \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build
```

## 🧪 7. 测试推送系统

### 7.1 iOS端测试
1. 运行应用，授权推送权限
2. 登录账号，Device Token会自动上传
3. 在设置页面发送测试推送

### 7.2 服务端测试
```bash
# 手动触发Edge Function
curl -X POST 'https://your-project.supabase.co/functions/v1/push-scheduler' \
  -H 'Authorization: Bearer your-service-role-key' \
  -H 'Content-Type: application/json'
```

### 7.3 数据库验证
```sql
-- 查看设备Token
SELECT * FROM user_devices WHERE is_active = true;

-- 查看推送记录
SELECT * FROM push_notifications ORDER BY sent_at DESC LIMIT 10;

-- 查看事件推送状态
SELECT id, title, push_day_before, push_week_before, push_status 
FROM events WHERE start_at > NOW();
```

## 🔍 8. 监控和调试

### 8.1 查看Edge Function日志
在Supabase控制台 Edge Functions → push-scheduler → Logs

### 8.2 监控推送发送率
```sql
-- 推送成功率统计
SELECT 
    status,
    COUNT(*) as count,
    COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() as percentage
FROM push_notifications 
WHERE sent_at >= NOW() - INTERVAL '7 days'
GROUP BY status;
```

### 8.3 常见问题排查
1. **Device Token未上传**: 检查iOS权限和登录状态
2. **推送未发送**: 查看Edge Function日志和Cron执行历史
3. **APNs认证失败**: 验证私钥格式和环境变量
4. **定时任务未执行**: 检查Cron配置和时区设置

## 📊 9. 费用预估

基于Supabase免费层：
- **Edge Functions**: 500万次/月 >> 每日30次调用
- **数据库**: 500MB >> 推送数据很小
- **带宽**: 5GB >> 推送数据微乎其微

预计可支持 **5000+活跃用户** 完全免费！

## 🚀 10. 生产环境部署

### 10.1 切换到生产APNs
将Edge Function中的APNs Host改为：
```typescript
const APNS_HOST = 'api.push.apple.com' // 生产环境
```

### 10.2 更新iOS配置
在 `HiCalendar.entitlements` 中：
```xml
<key>aps-environment</key>
<string>production</string>
```

### 10.3 App Store审核注意事项
1. 在App描述中说明推送功能
2. 确保推送权限请求时机合理
3. 提供推送设置页面让用户控制

---

## ✅ 部署完成检查

完成部署后，请确认：

- [ ] 数据库表创建成功
- [ ] Edge Function部署成功  
- [ ] 环境变量配置正确
- [ ] Cron定时任务运行正常
- [ ] iOS端可以收到测试推送
- [ ] Device Token正常上传
- [ ] 推送记录正常写入数据库

🎉 恭喜！你的HiCalendar推送通知系统已经部署完成！