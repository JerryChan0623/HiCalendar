// Debug APNs推送测试脚本
const testAPNsConfig = {
  APNS_KEY_ID: "MB9AZXA948",
  APNS_TEAM_ID: "G8Q7A2K656", 
  APNS_PRIVATE_KEY: `-----BEGIN PRIVATE KEY-----
MIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQgDim66VUBksg8k6Rl
60v2SOgWFgFSnx460K5kW5hDaYqgCgYIKoZIzj0DAQehRANCAARAqi9aGR9Li9/m
oQnQbkzqyUJ89+OYWhw/FjRFatmmjeBxD9cM/kr9WlyrRyLsPeRKCU3qAG0VMEBK
DYhUn66v
-----END PRIVATE KEY-----`,
  BUNDLE_ID: "com.chenzhencong.HiCalendar",
  DEVICE_TOKEN: "8d6324688e1841ae76dbbdd2a1bd4657dc8abaf5309780ed94714eec21c99d72"
}

// 创建简单的APNs JWT Token进行测试
const jwt = require('jsonwebtoken');
const crypto = require('crypto');

try {
  // 生成JWT Token用于APNs认证
  const token = jwt.sign(
    {},
    testAPNsConfig.APNS_PRIVATE_KEY,
    {
      algorithm: 'ES256',
      keyid: testAPNsConfig.APNS_KEY_ID,
      issuer: testAPNsConfig.APNS_TEAM_ID,
      expiresIn: '1h'
    }
  );
  
  console.log("✅ JWT Token生成成功");
  console.log("📱 设备Token:", testAPNsConfig.DEVICE_TOKEN);
  console.log("🔑 Key ID:", testAPNsConfig.APNS_KEY_ID);
  console.log("👥 Team ID:", testAPNsConfig.APNS_TEAM_ID);
  
  // 测试推送payload
  const payload = {
    aps: {
      alert: {
        title: "HiCalendar测试",
        body: "APNs配置测试推送"
      },
      badge: 1,
      sound: "default"
    }
  };
  
  console.log("📦 推送Payload:", JSON.stringify(payload, null, 2));
  
  // 下一步：可以用curl手动测试APNs
  const curlCommand = `curl -v \\
    -d '${JSON.stringify(payload)}' \\
    -H "authorization: bearer ${token}" \\
    -H "apns-id: 123e4567-e89b-12d3-a456-426614174000" \\
    -H "apns-push-type: alert" \\
    -H "apns-priority: 10" \\
    -H "apns-topic: ${testAPNsConfig.BUNDLE_ID}" \\
    --http2 \\
    https://api.sandbox.push.apple.com/3/device/${testAPNsConfig.DEVICE_TOKEN}`;
    
  console.log("\n📋 手动测试命令：");
  console.log(curlCommand);
  
} catch (error) {
  console.error("❌ 配置测试失败:", error.message);
}