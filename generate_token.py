#!/usr/bin/env python3
import jwt
import time

# APNs配置
APNS_KEY_ID = "MB9AZXA948"
APNS_TEAM_ID = "G8Q7A2K656"
APNS_PRIVATE_KEY = """-----BEGIN PRIVATE KEY-----
MIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQgDim66VUBksg8k6Rl
60v2SOgWFgFSnx460K5kW5hDaYqgCgYIKoZIzj0DAQehRANCAARAqi9aGR9Li9/m
oQnQbkzqyUJ89+OYWhw/FjRFatmmjeBxD9cM/kr9WlyrRyLsPeRKCU3qAG0VMEBK
DYhUn66v
-----END PRIVATE KEY-----"""

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

if __name__ == "__main__":
    token = generate_jwt_token()
    print(token)