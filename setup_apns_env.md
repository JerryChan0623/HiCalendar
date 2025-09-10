# APNs环境变量配置指南

## 🔧 需要在Supabase项目中配置的环境变量

基于你的证书文件和Team ID，需要在Supabase控制台中配置以下环境变量：

### 1. 登录Supabase控制台
访问：https://supabase.com/dashboard/project/ngzzciukzokypzzpcbvj

### 2. 进入Edge Functions设置
导航到：Project Settings > Edge Functions > Environment Variables

### 3. 添加以下环境变量

#### APNS_KEY_ID
```
MB9AZXA948
```

#### APNS_TEAM_ID  
```
G8Q7A2K656
```

#### APNS_PRIVATE_KEY
```
-----BEGIN PRIVATE KEY-----
MIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQgDim66VUBksg8k6Rl
60v2SOgWFgFSnx460K5kW5hDaYqgCgYIKoZIzj0DAQehRANCAARAqi9aGR9Li9/m
oQnQbkzqyUJ89+OYWhw/FjRFatmmjeBxD9cM/kr9WlyrRyLsPeRKCU3qAG0VMEBK
DYhUn66v
-----END PRIVATE KEY-----
```

## ⚠️ 重要提醒

1. **开发环境设置**：当前Edge Function已配置为开发环境(`api.sandbox.push.apple.com`)
2. **设备Token匹配**：确保iOS应用获取的是开发环境的设备Token
3. **证书权限**：确保APNs密钥已启用推送通知权限

## 🧪 配置完成后的测试步骤

1. 保存环境变量后，等待5-10分钟让配置生效
2. 手动触发Edge Function测试：
   ```bash
   curl -X POST "https://ngzzciukzokypzzpcbvj.supabase.co/functions/v1/push-scheduler" \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5nenpjaXVrem9reXB6enBjYnZqIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NTY4MzcwNSwiZXhwIjoyMDcxMjU5NzA1fQ.V-JcSzeVbv7CL3zvKXjzsNfFsW-A8uDiK51G5mOxzU8" \
     -d '{}'
   ```
3. 检查推送记录：
   ```sql
   SELECT * FROM push_notifications ORDER BY sent_at DESC LIMIT 5;
   ```

## 🔄 生产环境切换

当准备发布到App Store时，需要：
1. 将Edge Function中的`APNS_HOST`改为`api.push.apple.com`
2. 确保设备Token是生产环境获取的
3. 重新部署Edge Function