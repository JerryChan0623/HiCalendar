#!/usr/bin/env python3
"""
简化的推送测试工具 - 模拟Edge Function的完整流程
"""
import requests
import jwt
import time
import json

# 配置信息
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
    """生成APNs JWT token"""
    headers = {
        "alg": "ES256",
        "kid": APNS_KEY_ID
    }
    
    payload = {
        "iss": APNS_TEAM_ID,
        "iat": int(time.time())
    }
    
    return jwt.encode(payload, APNS_PRIVATE_KEY, algorithm="ES256", headers=headers)

def test_push_notification():
    """模拟Edge Function发送推送"""
    print("🚀 开始模拟Edge Function推送测试...")
    
    try:
        # 1. 生成JWT
        print("🔑 生成JWT Token...")
        token = generate_jwt_token()
        print(f"✅ JWT生成成功: {token[:30]}...")
        
        # 2. 准备推送payload（模拟Edge Function的格式）
        payload = {
            "aps": {
                "alert": {
                    "title": "HiCalendar提醒",
                    "body": "模拟Edge Function推送测试"
                },
                "badge": 1,
                "sound": "default",
                "mutable-content": 1
            },
            "event_id": "test-event-id",
            "notification_type": "1_day",
            "event_count": 1
        }
        
        print(f"📦 推送Payload: {json.dumps(payload, indent=2)}")
        
        # 3. 发送推送（使用requests模拟，不强制HTTP/2）
        url = f"https://{APNS_HOST}/3/device/{DEVICE_TOKEN}"
        headers = {
            'Authorization': f'Bearer {token}',
            'apns-topic': BUNDLE_ID,
            'apns-push-type': 'alert',
            'apns-priority': '10',
            'Content-Type': 'application/json'
        }
        
        print(f"🌐 发送到: {url}")
        print(f"📋 Headers: {headers}")
        
        # 4. 发送请求
        print("📤 发送推送请求...")
        response = requests.post(url, json=payload, headers=headers, timeout=15)
        
        print(f"📊 响应状态: {response.status_code}")
        print(f"📋 响应头: {dict(response.headers)}")
        
        if response.status_code == 200:
            print("🎉 推送发送成功!")
            apns_id = response.headers.get('apns-id', 'N/A')
            print(f"📱 APNs ID: {apns_id}")
        else:
            print(f"❌ 推送失败: {response.status_code}")
            if response.text:
                error_data = json.loads(response.text)
                print(f"🔍 错误详情: {error_data}")
                print(f"📝 错误原因: {error_data.get('reason', 'Unknown')}")
        
    except Exception as e:
        print(f"💥 测试异常: {str(e)}")
        import traceback
        print(traceback.format_exc())

if __name__ == "__main__":
    test_push_notification()