// HiCalendar Push Notification Cron Scheduler
// 专门用于cron调用的Edge Function，不需要Authorization header
// 在内部调用push-scheduler function

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

serve(async (req) => {
  try {
    console.log('🕒 Push Cron triggered at:', new Date().toISOString())
    
    // 调用push-scheduler Edge Function
    const response = await fetch('https://ngzzciukzokypzzpcbvj.supabase.co/functions/v1/push-scheduler', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5nenpjaXVrem9reXB6enBjYnZqIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NTY4MzcwNSwiZXhwIjoyMDcxMjU5NzA1fQ.V-JcSzeVbv7CL3zvKXjzsNfFsW-A8uDiK51G5mOxzU8'
      },
      body: '{}'
    })
    
    const result = await response.json()
    console.log('📋 Push scheduler result:', result)
    
    return new Response(JSON.stringify({
      success: true,
      timestamp: new Date().toISOString(),
      scheduler_result: result
    }), {
      headers: { 'Content-Type': 'application/json' }
    })
    
  } catch (error) {
    console.error('❌ Push Cron error:', error)
    return new Response(JSON.stringify({
      success: false,
      error: error.message,
      timestamp: new Date().toISOString()
    }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    })
  }
})