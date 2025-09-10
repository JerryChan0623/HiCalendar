#!/usr/bin/env python3
import jwt
import json
import requests
import time
from datetime import datetime

# APNs配置
APNS_KEY_ID = "MB9AZXA948"
APNS_TEAM_ID = "G8Q7A2K656"
APNS_PRIVATE_KEY = """-----BEGIN PRIVATE KEY-----
MIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQgDim66VUBksg8k6Rl
60v2SOgWFgFSnx460K5kW5hDaYqgCgYIKoZIzj0DAQehRANCAARAqi9aGR9Li9/m
oQnQbkzqyUJ89+OYWhw/FjRFatmmjeBxD9cM/kr9WlyrRyLsPeRKCU3qAG0VMEBK
DYhUn66v
-----END PRIVATE KEY-----"""

BUNDLE_ID = "com.chenzhencong.HiCalendar"
DEVICE_TOKEN = "8d6324688e1841ae76dbbdd2a1bd4657dc8abaf5309780ed94714eec21c99d72"
APNS_HOST = "api.sandbox.push.apple.com"

def generate_jwt_token():
    """生成APNs JWT认证token"""
    headers = {
        "alg": "ES256",
        "kid": APNS_KEY_ID
    }
    
    payload = {
        "iss": APNS_TEAM_ID,
        "iat": int(time.time())
    }
    
    token = jwt.encode(payload, APNS_PRIVATE_KEY, algorithm="ES256", headers=headers)
    return token

def test_apns_push():
    """测试APNs推送"""
    try:
        print("🔧 生成JWT Token...")
        token = generate_jwt_token()
        print(f"✅ JWT Token: {token[:50]}...")
        
        print(f"📱 目标设备: {DEVICE_TOKEN}")
        print(f"🎯 APNs主机: {APNS_HOST}")
        print(f"📦 Bundle ID: {BUNDLE_ID}")
        
        # 推送payload
        payload = {
            "aps": {
                "alert": {
                    "title": "HiCalendar测试",
                    "body": "APNs直接测试推送 🚀"
                },
                "badge": 1,
                "sound": "default"
            }
        }
        
        print(f"📬 推送内容: {json.dumps(payload, indent=2)}")
        
        # 发送推送
        url = f"https://{APNS_HOST}/3/device/{DEVICE_TOKEN}"
        headers = {
            "authorization": f"bearer {token}",
            "apns-topic": BUNDLE_ID,
            "apns-push-type": "alert",
            "apns-priority": "10",
            "content-type": "application/json"
        }
        
        print(f"🌐 请求URL: {url}")
        print("📤 发送推送请求...")
        
        response = requests.post(url, json=payload, headers=headers, timeout=10)
        
        print(f"📊 响应状态: {response.status_code}")
        print(f"📋 响应头: {dict(response.headers)}")
        
        if response.status_code == 200:
            print("🎉 推送发送成功!")
            print(f"📱 apns-id: {response.headers.get('apns-id', 'N/A')}")
        else:
            print(f"❌ 推送失败: {response.status_code}")
            if response.text:
                print(f"📝 错误详情: {response.text}")
                error_data = json.loads(response.text)
                print(f"🔍 错误原因: {error_data.get('reason', 'Unknown')}")
        
    except Exception as e:
        print(f"💥 测试异常: {str(e)}")
        import traceback
        print(traceback.format_exc())

if __name__ == "__main__":
    print("🚀 开始APNs直接测试...")
    test_apns_push()