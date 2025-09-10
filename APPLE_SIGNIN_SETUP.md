# Apple Sign-In 配置检查清单

## ✅ Xcode项目配置

### 1. 添加Sign in with Apple Capability
1. 选择HiCalendar项目
2. 选择HiCalendar target
3. 点击 **Signing & Capabilities** 标签
4. 点击 **+ Capability** 按钮
5. 搜索并添加 **Sign in with Apple**

### 2. 确认Bundle ID
- 确保Bundle ID是: `com.example.HiCalendar` (或你自己的Bundle ID)
- 这个Bundle ID必须在Apple Developer中注册

## ✅ Apple Developer配置

### 1. App ID配置
1. 登录 [Apple Developer](https://developer.apple.com)
2. 进入 **Certificates, Identifiers & Profiles**
3. 选择 **Identifiers**
4. 找到你的App ID (例如: com.example.HiCalendar)
5. 编辑并确保勾选了 **Sign in with Apple**

### 2. Service ID配置 (用于Supabase)
- Service ID: `com.chenzhencong.hicalendar.supabase`
- 已配置域名: `ngzzciukzokypzzpcbvj.supabase.co`
- 回调URL: `https://ngzzciukzokypzzpcbvj.supabase.co/auth/v1/callback`

### 3. 密钥信息
- Team ID: `G8Q7A2K656`
- Key ID: `MB9AZXA948`
- Client Secret已生成并保存在: `apple_client_secret_20250820_221913.txt`

## ✅ Supabase配置

### 在Supabase Dashboard中:
1. 进入 **Authentication > Providers**
2. 启用 **Apple** provider
3. 填写:
   - **Client ID**: `com.chenzhencong.hicalendar.supabase`
   - **Secret Key**: (使用生成的JWT Client Secret)

## 🧪 测试步骤

### 1. 在真机上测试
Apple Sign-In需要在真机上测试，模拟器可能无法正常工作。

### 2. 测试流程
1. 运行应用
2. 进入设置页面
3. 点击"通过 Apple 登录"按钮
4. 使用你的Apple ID登录
5. 授权应用访问你的信息
6. 检查控制台输出，应该看到:
   - "✅ Apple登录成功: [用户ID]"

### 3. 常见问题

#### 问题: "Invalid client" 错误
- 检查Service ID是否正确
- 确认Client Secret没有过期
- 验证Supabase配置是否正确

#### 问题: "User cancelled" 错误
- 这是正常的，用户取消了登录

#### 问题: 无法显示登录界面
- 确保在真机上测试
- 检查是否添加了Sign in with Apple capability
- 验证Bundle ID配置正确

## 📱 调试提示

在控制台查看详细日志:
- `✅` 表示操作成功
- `❌` 表示操作失败

查看Supabase日志:
1. 登录Supabase Dashboard
2. 进入 **Authentication > Logs**
3. 查看认证请求记录

## 🔄 Client Secret更新

Client Secret有效期为180天，需要定期更新:
1. 运行: `python3 generate_apple_client_secret.py`
2. 复制新的JWT
3. 更新Supabase中的Secret Key
4. 记录更新日期

当前Client Secret有效期至: **2026-02-16**