# Apple Sign In 配置指南

## 🍎 在Apple Developer配置

### 1. 创建App ID
1. 登录 [Apple Developer](https://developer.apple.com)
2. 进入 Certificates, Identifiers & Profiles
3. 选择 Identifiers > 点击 + 
4. 选择 App IDs > Continue
5. 填写信息并勾选 "Sign in with Apple"

### 2. 创建Service ID (用于Web/Supabase)
1. 在 Identifiers 页面点击 +
2. 选择 Services IDs > Continue
3. 填写:
   - Description: `HiCalendar Service`
   - Identifier: `com.yourcompany.hicalendar.service` (记住这个，这是你的SERVICE_ID)
4. 保存后，编辑这个Service ID
5. 勾选 "Sign in with Apple"
6. 配置域名和回调URL:
   - Domain: `ngzzciukzokypzzpcbvj.supabase.co`
   - Return URL: `https://ngzzciukzokypzzpcbvj.supabase.co/auth/v1/callback`

### 3. 创建Sign in with Apple密钥
1. 进入 Keys 页面
2. 点击 + 创建新密钥
3. 填写密钥名称
4. 勾选 "Sign in with Apple"
5. 点击Configure，选择你的App ID
6. 下载.p8密钥文件（只能下载一次！）
7. 记录Key ID（例如: ABCD1234EF）

### 4. 获取Team ID
1. 在Apple Developer账户设置中查看
2. 通常是10位字符（例如: ABC123DEF4）

## 🔐 生成Client Secret

### 安装依赖
```bash
pip install -r requirements.txt
```

### 配置并运行脚本
1. 编辑 `generate_apple_client_secret.py`
2. 修改config部分:
```python
config = {
    "TEAM_ID": "你的Team ID",           # 例如: "ABC123DEF4"
    "SERVICE_ID": "你的Service ID",     # 例如: "com.yourcompany.hicalendar.service"
    "KEY_ID": "你的Key ID",             # 例如: "ABCD1234EF"
    "PRIVATE_KEY_PATH": "AuthKey_XXX.p8",  # 你的.p8文件路径
    "EXPIRATION_DAYS": 180
}
```

3. 运行脚本:
```bash
python generate_apple_client_secret.py
```

4. 脚本会生成JWT格式的Client Secret

## 🔧 在Supabase配置

1. 登录 [Supabase控制台](https://app.supabase.com)
2. 进入你的项目
3. Authentication > Providers > Apple
4. 启用Apple provider
5. 填写:
   - **Client ID (Services ID)**: 你的Service ID (例如: com.yourcompany.hicalendar.service)
   - **Secret Key**: 生成的JWT Client Secret
6. 保存

## 📱 在iOS应用中配置

### Xcode项目设置
1. 选择项目 > Signing & Capabilities
2. 点击 + Capability
3. 添加 "Sign in with Apple"
4. 确保Bundle ID与App ID一致

### Info.plist (如果需要)
无需额外配置

## ⚠️ 重要提醒

1. **Client Secret有效期**: 最长180天，需要定期更新
2. **.p8文件安全**: 妥善保管，不要提交到Git
3. **Bundle ID一致性**: iOS应用的Bundle ID必须与App ID一致
4. **Service ID**: Web/Supabase使用Service ID，不是App ID

## 🔍 测试检查清单

- [ ] Apple Developer配置完成
- [ ] Service ID创建并配置域名
- [ ] Sign in with Apple密钥已创建
- [ ] Client Secret已生成
- [ ] Supabase配置完成
- [ ] Xcode项目添加了Sign in with Apple capability
- [ ] 测试Apple登录功能

## 📚 参考链接

- [Apple: Sign in with Apple](https://developer.apple.com/sign-in-with-apple/)
- [Supabase: Apple OAuth](https://supabase.com/docs/guides/auth/social-login/auth-apple)
- [JWT.io](https://jwt.io/) - 用于验证生成的JWT