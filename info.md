# HiCalendar Supabase 配置信息

## 项目信息
- **项目ID**: ngzzciukzokypzzpcbvj
- **项目名称**: HiCalendar
- **区域**: Southeast Asia (Singapore)

## 访问凭证

### Supabase Access Token
```
sbp_e0cb607213c322adb626e7fedef7d958e45eaf36
```

### Service Role Key (JWT)
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5nenpjaXVrem9reXB6enBjYnZqIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NTY4MzcwNSwiZXhwIjoyMDcxMjU5NzA1fQ.V-JcSzeVbv7CL3zvKXjzsNfFsW-A8uDiK51G5mOxzU8
```

### Database Password
```
GgUFBSOifzhTqt0j
```

## API 端点
- **Project URL**: https://ngzzciukzokypzzpcbvj.supabase.co
- **REST API**: https://ngzzciukzokypzzpcbvj.supabase.co/rest/v1/
- **Edge Functions**: https://ngzzciukzokypzzpcbvj.supabase.co/functions/v1/

## CLI 使用示例

### 设置环境变量
```bash
export SUPABASE_ACCESS_TOKEN="sbp_e0cb607213c322adb626e7fedef7d958e45eaf36"
```

### 项目操作
```bash
# 查看项目列表
supabase projects list

# 部署Edge Function
supabase functions deploy push-scheduler --project-ref ngzzciukzokypzzpcbvj

# 链接到项目（需要数据库密码）
supabase link --project-ref ngzzciukzokypzzpcbvj
```

### 数据库连接信息
```
Host: aws-1-ap-southeast-1.pooler.supabase.com
Database: postgres
User: postgres.ngzzciukzokypzzpcbvj
Password: GgUFBSOifzhTqt0j
Port: 5432
```

## 安全提醒
⚠️ 这些凭证具有完整的项目访问权限，请妥善保管，不要提交到公开代码仓库。