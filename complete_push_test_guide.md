# 📱 HiCalendar 完整推送测试指南

## 🧪 要在手机上收到真实推送，需要完成以下步骤：

### 1. iOS端准备 📲
```bash
# 先编译并运行iOS应用
cd "/Users/jerry/Documents/Xcode Pro/HiCalendar"
xcodebuild -project HiCalendar.xcodeproj -scheme HiCalendar -destination 'platform=iOS Simulator,name=iPhone 16' build
```

### 2. 在iOS应用中完成 📋
- ✅ **启动HiCalendar应用**
- ✅ **登录Apple账号**（获取真实user_id）
- ✅ **进入设置页面**
- ✅ **允许推送权限**（获取真实device_token）
- ✅ **创建明天的事件**（开启推送选项）

### 3. 验证数据是否正确 🔍
在Supabase SQL编辑器中查询：
```sql
-- 检查真实用户数据
SELECT * FROM public.users ORDER BY created_at DESC LIMIT 5;

-- 检查真实设备Token
SELECT * FROM user_devices WHERE is_active = true ORDER BY created_at DESC LIMIT 5;

-- 检查需要推送的事件
SELECT 
    e.title,
    e.start_at,
    e.push_day_before,
    EXTRACT(days FROM (e.start_at - NOW())) as days_until_event
FROM events e
WHERE e.start_at > NOW() 
AND e.push_day_before = true
AND EXTRACT(days FROM (e.start_at - NOW())) BETWEEN 0.5 AND 1.5;
```

### 4. 手动触发真实推送 🚀
```bash
curl -X POST 'https://ngzzciukzokypzzpcbvj.supabase.co/functions/v1/push-scheduler' \
  -H 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5nenpjaXVrem9reXB6enBjYnZqIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NTY4MzcwNSwiZXhwIjoyMDcxMjU5NzA1fQ.V-JcSzeVbv7CL3zvKXjzsNfFsW-A8uDiK51G5mOxzU8' \
  -H 'Content-Type: application/json' \
  -d '{"manual_trigger": true}'
```

### 5. 推送测试的前提条件 ⚠️
❌ **模拟器无法收到真实推送** - 需要真实iPhone设备
❌ **需要Apple Developer证书** - 用于APNs认证
❌ **需要真实Bundle ID配置** - com.chenzhencong.HiCalendar

## 🔧 快速测试方案

### 方案A: 本地推送测试（iOS模拟器可用）
在iOS应用的设置页面有"发送测试推送"按钮 - 这个是本地推送，可以在模拟器测试

### 方案B: 创建测试数据验证逻辑
执行 `create_test_event_now.sql` 创建测试事件，然后触发Edge Function验证推送逻辑

## ✅ 当前系统状态
- 🟢 Edge Function: 正常运行
- 🟢 数据库结构: 完整
- 🟢 环境变量: 已配置
- 🟠 测试数据: 需要创建
- 🟠 iOS设备Token: 需要注册
- 🔴 真实推送: 需要真实设备 + 完整流程

**推送系统基础设施已完成，现在需要完整的端到端测试！**