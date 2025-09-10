#!/usr/bin/env python3
"""
Apple Sign In Client Secret (JWT) Generator
用于生成Supabase等第三方服务所需的Apple登录客户端密钥

使用前准备:
1. 在Apple Developer中创建一个Key (用于Sign in with Apple)
2. 下载.p8密钥文件
3. 记录以下信息:
   - Key ID
   - Team ID
   - Service ID (client_id)
"""

import jwt
import time
from datetime import datetime, timedelta
import json
import sys
import os

def generate_apple_client_secret(
    team_id,
    service_id,
    key_id,
    private_key_path,
    expiration_days=180
):
    """
    生成Apple Client Secret (JWT)
    
    参数:
    - team_id: Apple开发者团队ID (在Apple Developer账户中查看)
    - service_id: Service ID (也称为client_id，在Certificates, Identifiers & Profiles中创建)
    - key_id: 密钥ID (创建Sign in with Apple密钥时获得)
    - private_key_path: .p8私钥文件路径
    - expiration_days: JWT过期天数 (最长180天)
    
    返回:
    - JWT token字符串
    """
    
    # 读取私钥文件
    try:
        with open(private_key_path, 'r') as f:
            private_key = f.read()
    except FileNotFoundError:
        print(f"❌ 错误: 找不到私钥文件: {private_key_path}")
        return None
    except Exception as e:
        print(f"❌ 错误: 读取私钥文件失败: {e}")
        return None
    
    # 设置JWT headers
    headers = {
        "alg": "ES256",
        "kid": key_id,
        "typ": "JWT"
    }
    
    # 设置JWT payload
    now = int(time.time())
    expiration = now + (expiration_days * 24 * 60 * 60)  # 转换天数为秒
    
    payload = {
        "iss": team_id,              # Issuer (你的Team ID)
        "iat": now,                  # Issued at time
        "exp": expiration,            # Expiration time
        "aud": "https://appleid.apple.com",  # Audience
        "sub": service_id             # Subject (你的Service ID/Client ID)
    }
    
    # 生成JWT
    try:
        client_secret = jwt.encode(
            payload,
            private_key,
            algorithm="ES256",
            headers=headers
        )
        return client_secret
    except Exception as e:
        print(f"❌ 错误: 生成JWT失败: {e}")
        return None

def main():
    print("=" * 60)
    print("🍎 Apple Sign In Client Secret (JWT) 生成器")
    print("=" * 60)
    print()
    
    # 配置信息 - 请根据你的实际信息修改
    config = {
        # TODO: 请填入你的实际信息
        "TEAM_ID": "G8Q7A2K656",           # 例如: "ABC123DEF4"
        "SERVICE_ID": "com.chenzhencong.hicalendar.supabase",     # 例如: "com.example.service"
        "KEY_ID": "MB9AZXA948",             # 例如: "ABCD1234EF"
        "PRIVATE_KEY_PATH": "AuthKey_MB9AZXA948.p8",  # 你的.p8文件路径
        "EXPIRATION_DAYS": 180               # JWT有效期（天）
    }
    
    # 检查是否已配置
    if config["TEAM_ID"] == "YOUR_TEAM_ID":
        print("⚠️  请先配置你的Apple开发者信息！")
        print()
        print("需要配置的信息:")
        print("1. TEAM_ID: 在Apple Developer账户设置中查看")
        print("2. SERVICE_ID: 在Certificates, Identifiers & Profiles > Identifiers中创建")
        print("3. KEY_ID: 在Keys中创建Sign in with Apple密钥时获得")
        print("4. PRIVATE_KEY_PATH: 下载的.p8密钥文件路径")
        print()
        print("配置示例:")
        print("-" * 40)
        print("config = {")
        print('    "TEAM_ID": "ABC123DEF4",')
        print('    "SERVICE_ID": "com.example.hicalendar.service",')
        print('    "KEY_ID": "ABCD1234EF",')
        print('    "PRIVATE_KEY_PATH": "AuthKey_ABCD1234EF.p8",')
        print('    "EXPIRATION_DAYS": 180')
        print("}")
        print("-" * 40)
        return
    
    print("📋 当前配置:")
    print(f"   Team ID: {config['TEAM_ID']}")
    print(f"   Service ID: {config['SERVICE_ID']}")
    print(f"   Key ID: {config['KEY_ID']}")
    print(f"   私钥文件: {config['PRIVATE_KEY_PATH']}")
    print(f"   有效期: {config['EXPIRATION_DAYS']} 天")
    print()
    
    # 生成Client Secret
    print("🔐 正在生成Client Secret...")
    client_secret = generate_apple_client_secret(
        team_id=config["TEAM_ID"],
        service_id=config["SERVICE_ID"],
        key_id=config["KEY_ID"],
        private_key_path=config["PRIVATE_KEY_PATH"],
        expiration_days=config["EXPIRATION_DAYS"]
    )
    
    if client_secret:
        print("✅ 生成成功！")
        print()
        print("=" * 60)
        print("CLIENT SECRET (JWT):")
        print("=" * 60)
        print(client_secret)
        print("=" * 60)
        print()
        
        # 计算过期时间
        expiration_date = datetime.now() + timedelta(days=config["EXPIRATION_DAYS"])
        print(f"⏰ 此密钥将于 {expiration_date.strftime('%Y-%m-%d %H:%M:%S')} 过期")
        print()
        
        # 保存到文件
        output_file = f"apple_client_secret_{datetime.now().strftime('%Y%m%d_%H%M%S')}.txt"
        with open(output_file, 'w') as f:
            f.write(f"Apple Client Secret\n")
            f.write(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
            f.write(f"Expires: {expiration_date.strftime('%Y-%m-%d %H:%M:%S')}\n")
            f.write(f"Team ID: {config['TEAM_ID']}\n")
            f.write(f"Service ID: {config['SERVICE_ID']}\n")
            f.write(f"Key ID: {config['KEY_ID']}\n")
            f.write(f"\n{client_secret}\n")
        
        print(f"💾 已保存到文件: {output_file}")
        print()
        print("📌 使用说明:")
        print("1. 将此Client Secret复制到Supabase控制台")
        print("2. 在Authentication > Providers > Apple中配置")
        print("3. 同时配置Service ID作为Client ID")
        print("4. 记得在过期前重新生成新的Client Secret")
        
    else:
        print("❌ 生成失败！请检查配置信息和私钥文件。")

if __name__ == "__main__":
    # 检查是否安装了PyJWT
    try:
        import jwt
    except ImportError:
        print("❌ 错误: 未安装PyJWT库")
        print("请运行: pip install PyJWT cryptography")
        print()
        sys.exit(1)
    
    main()