// APNs推送测试 Edge Function
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import * as jose from "https://deno.land/x/jose@v4.14.4/index.ts"

// Environment variables - 从Supabase环境变量获取
const APNS_KEY_ID = Deno.env.get('APNS_KEY_ID')!
const APNS_TEAM_ID = Deno.env.get('APNS_TEAM_ID')!
const APNS_PRIVATE_KEY = Deno.env.get('APNS_PRIVATE_KEY')!
const BUNDLE_ID = 'com.chenzhencong.HiCalendar'
const APNS_HOST = 'api.sandbox.push.apple.com'

// 测试设备token（从数据库中获取的真实token）
const TEST_DEVICE_TOKEN = '8d6324688e1841ae76dbbdd2a1bd4657dc8abaf5309780ed94714eec21c99d72'

serve(async (req) => {
  try {
    console.log('🧪 APNs Push Test started')
    
    // 检查环境变量
    const envCheck = {
      APNS_KEY_ID: !!APNS_KEY_ID,
      APNS_TEAM_ID: !!APNS_TEAM_ID,
      APNS_PRIVATE_KEY_EXISTS: !!APNS_PRIVATE_KEY,
      APNS_PRIVATE_KEY_LENGTH: APNS_PRIVATE_KEY?.length || 0,
      APNS_PRIVATE_KEY_STARTS_WITH: APNS_PRIVATE_KEY?.substring(0, 30) || 'N/A',
      BUNDLE_ID: BUNDLE_ID,
      APNS_HOST: APNS_HOST,
      TEST_DEVICE_TOKEN: TEST_DEVICE_TOKEN
    }
    
    console.log('🔧 Environment check:', JSON.stringify(envCheck, null, 2))
    
    // 1. 测试JWT生成
    console.log('🔑 Step 1: Testing JWT generation...')
    let jwt
    try {
      console.log('🔑 Importing private key...')
      const privateKey = await jose.importPKCS8(APNS_PRIVATE_KEY, 'ES256')
      console.log('🔑 Private key imported successfully')
      
      jwt = await new jose.SignJWT({})
        .setProtectedHeader({
          alg: 'ES256',
          kid: APNS_KEY_ID
        })
        .setIssuedAt()
        .setIssuer(APNS_TEAM_ID)
        .setExpirationTime('1h')
        .sign(privateKey)
        
      console.log('✅ JWT generated successfully')
    } catch (error) {
      console.error('❌ JWT generation failed:', error.message)
      return new Response(JSON.stringify({
        success: false,
        step: 'jwt_generation',
        error: error.message,
        envCheck: envCheck
      }), {
        status: 500,
        headers: { 'Content-Type': 'application/json' }
      })
    }
    
    // 2. 测试APNs连接和推送
    console.log('📱 Step 2: Testing APNs push...')
    const payload = {
      aps: {
        alert: {
          title: "🧪 APNs测试",
          body: "如果你收到这条消息，说明推送配置正确！"
        },
        badge: 1,
        sound: "default"
      },
      test: true,
      timestamp: new Date().toISOString()
    }
    
    console.log('📤 Sending push notification...')
    console.log('📦 Payload:', JSON.stringify(payload))
    
    try {
      const response = await fetch(`https://${APNS_HOST}/3/device/${TEST_DEVICE_TOKEN}`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${jwt}`,
          'apns-topic': BUNDLE_ID,
          'apns-push-type': 'alert',
          'apns-expiration': '0',
          'apns-priority': '10',
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(payload)
      })

      const responseText = await response.text()
      const apnsId = response.headers.get('apns-id')
      
      if (!response.ok) {
        console.error('❌ APNs push failed')
        console.error('❌ Status:', response.status)
        console.error('❌ Response:', responseText)
        console.error('❌ Headers:', Object.fromEntries(response.headers.entries()))
        
        return new Response(JSON.stringify({
          success: false,
          step: 'apns_push',
          apns_status: response.status,
          apns_response: responseText,
          apns_id: apnsId,
          headers: Object.fromEntries(response.headers.entries()),
          envCheck: envCheck
        }), {
          status: 200,
          headers: { 'Content-Type': 'application/json' }
        })
      } else {
        console.log('✅ APNs push successful!')
        console.log('✅ APNs ID:', apnsId)
        
        return new Response(JSON.stringify({
          success: true,
          step: 'completed',
          message: 'Push notification sent successfully!',
          apns_id: apnsId,
          apns_status: response.status,
          envCheck: envCheck
        }), {
          headers: { 'Content-Type': 'application/json' }
        })
      }
      
    } catch (error) {
      console.error('❌ Network error:', error.message)
      return new Response(JSON.stringify({
        success: false,
        step: 'network_error',
        error: error.message,
        envCheck: envCheck
      }), {
        status: 500,
        headers: { 'Content-Type': 'application/json' }
      })
    }
    
  } catch (error) {
    console.error('💥 General error:', error.message)
    return new Response(JSON.stringify({
      success: false,
      step: 'general_error',
      error: error.message
    }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    })
  }
})