// HiCalendar Push Notification Scheduler
// Supabase Edge Function for sending scheduled push notifications

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"
import * as jose from "https://deno.land/x/jose@v4.14.4/index.ts"

// Environment variables - 从Supabase环境变量获取
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
const SUPABASE_ANON_KEY = Deno.env.get('SUPABASE_ANON_KEY') || ''
const APNS_KEY_ID = Deno.env.get('APNS_KEY_ID')!
const APNS_TEAM_ID = Deno.env.get('APNS_TEAM_ID')!  
const APNS_PRIVATE_KEY = Deno.env.get('APNS_PRIVATE_KEY')!
const BUNDLE_ID = Deno.env.get('BUNDLE_ID') || 'com.chenzhencong.HiCalendar'
const APNS_ENV = (Deno.env.get('APNS_ENV') || 'sandbox').toLowerCase() // 'sandbox' | 'production'

// APNs settings
const APNS_HOST = APNS_ENV === 'production' ? 'api.push.apple.com' : 'api.sandbox.push.apple.com'

// Initialize Supabase client (may be overridden per-request to include Authorization header)
let supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY || SUPABASE_ANON_KEY)

interface Event {
  id: string
  title: string
  start_at: string | null
  user_id: string
  created_at: string
  intended_date: string | null  // 新增：事件归属日期字段
  push_day_before: boolean
  push_week_before: boolean
  push_reminders: string[]  // 新增：推送提醒选项数组
  push_status: any
}

interface UserProfile {
  timezone: string
}

interface DeviceToken {
  device_token: string
}

type ReminderType = 'at_time' | '15_minutes' | '30_minutes' | '1_hour' | '2_hours' | '1_day' | '1_week'

interface NotificationPayload {
  events: Event[]  // 改为支持多个事件
  type: ReminderType
  message: string
  deviceTokens: string[]
  userId: string
}

serve(async (req) => {
  // 设置CORS headers
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type'
  }
  
  // 处理OPTIONS请求
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }
  
  try {
    console.log('🔔 Push Scheduler started at:', new Date().toISOString())
    
    // 不检查认证 - 这个函数应该只能通过内部调用访问（cron或手动管理员调用）
    console.log('🔍 Request received from:', req.headers.get('user-agent') || 'unknown')
    console.log('📍 Request URL:', req.url)
    console.log('🔓 Auth check bypassed - internal function')
    
    // 检查环境变量
    console.log('🔧 Checking environment variables...')
    const envCheck = {
      SUPABASE_URL: !!SUPABASE_URL,
      SUPABASE_SERVICE_ROLE_KEY: !!SUPABASE_SERVICE_ROLE_KEY,
      APNS_KEY_ID: !!APNS_KEY_ID,
      APNS_TEAM_ID: !!APNS_TEAM_ID,
      APNS_PRIVATE_KEY: !!APNS_PRIVATE_KEY && APNS_PRIVATE_KEY.length > 100,
      BUNDLE_ID: BUNDLE_ID,
      APNS_HOST: APNS_HOST
    }
    console.log('🔧 Environment check:', JSON.stringify(envCheck))

    // Recreate Supabase client per-request to include Authorization header when needed
    const authHeader = req.headers.get('authorization') || ''
    if (!SUPABASE_SERVICE_ROLE_KEY && SUPABASE_ANON_KEY) {
      console.warn('⚠️ Using anon key with request Authorization header (ensure it is service role for RLS updates).')
      supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
        global: { headers: { Authorization: authHeader } }
      })
    } else if (SUPABASE_SERVICE_ROLE_KEY) {
      // Prefer service role env (bypasses RLS)
      supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)
    }

    // 0. Clean up old push data first (方案2: 推送优化清理)
    const cleanupResult = await cleanupOldPushData()
    console.log(`🧹 Cleanup completed: ${JSON.stringify(cleanupResult)}`)

    // 1. Query events that need push notifications
    const events = await queryEventsNeedingNotification()
    console.log(`📅 Found ${events.length} events needing notifications`)
    console.log(`📅 Event details:`, events.map(e => ({id: e.id, title: e.title, user_id: e.user_id})))

    if (events.length === 0) {
      return new Response(JSON.stringify({ 
        success: true, 
        message: 'No notifications to send',
        sent: 0,
        cleanup: cleanupResult,
        envCheck: envCheck
      }), {
        headers: { 'Content-Type': 'application/json' }
      })
    }

    // 2. Group events by user and notification type for batch sending
    const userNotificationGroups = await groupEventsByUserAndType(events)
    console.log(`👥 Grouped into ${userNotificationGroups.length} user notification batches`)

    // 3. Send batch notifications
    let successCount = 0
    let failureCount = 0

    for (const notification of userNotificationGroups) {
      try {
        console.log(`🚀 Attempting to send notification for user ${notification.userId}`)
        console.log(`📱 Device tokens: ${notification.deviceTokens.length} devices`)
        console.log(`📝 Message: ${notification.message}`)
        
        // Step 1: Send push notification (tolerate partial failures)
        const pushResult = await sendPushNotification(notification)
        const pushSent = pushResult.successCount > 0
        console.log(`📤 APNs push result for user ${notification.userId} -> success: ${pushResult.successCount}, fail: ${pushResult.failureCount}`)
        if (!pushSent) {
          // No device received the push; treat as failure for this batch
          throw new Error(`APNs push failed for all devices in batch (failures: ${pushResult.failureCount})`)
        }
        
        // Step 2: Update database status (critical - must succeed if push succeeded)
        try {
          await markBatchNotificationAsSent(notification)
          console.log(`💾 Database status updated successfully for user ${notification.userId}`)
        } catch (dbError) {
          console.error(`🚨 CRITICAL: APNs succeeded but database update failed for user ${notification.userId}`)
          console.error(`🚨 This will cause duplicate pushes! Error: ${dbError.message}`)
          // Even though push succeeded, we must treat this as failure to prevent duplicates
          throw new Error(`Database update failure after successful push: ${dbError.message}`)
        }
        
        successCount++
        console.log(`✅ Batch notification sent for user ${notification.userId}: ${notification.events.length} events`)
      } catch (error) {
        failureCount++
        console.error(`❌ Failed to send batch notification for user ${notification.userId}`)
        console.error(`❌ Error details:`, error)
        console.error(`❌ Error message:`, error.message)
        console.error(`❌ Error stack:`, error.stack)
        await logBatchNotificationFailure(notification, error)
      }
    }

    console.log(`🎉 Push Scheduler completed: ${successCount} sent, ${failureCount} failed`)

    return new Response(JSON.stringify({ 
      success: true,
      sent: successCount,
      failed: failureCount,
      total: userNotificationGroups.length,
      cleanup: cleanupResult,
      timestamp: new Date().toISOString()
    }), {
      headers: { 'Content-Type': 'application/json' }
    })

  } catch (error) {
    console.error('💥 Push Scheduler error:', error)
    return new Response(JSON.stringify({ 
      success: false, 
      error: error.message 
    }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    })
  }
})

// Query events that need notifications
async function queryEventsNeedingNotification(): Promise<Event[]> {
  const now = new Date()

  // 查询所有事件，包括没有具体时间的
  const { data: events, error } = await supabase
    .from('events')
    .select(`
      id, title, start_at, user_id, created_at, intended_date,
      push_day_before, push_week_before, push_reminders, push_status
    `)
    // 移除 .not('start_at', 'is', null) 限制

  if (error) {
    throw new Error(`Failed to query events: ${error.message}`)
  }

  // Filter events that need notifications
  return (events || []).filter((event: Event) => {
    // 统一处理：使用intended_date字段来确定事件归属日期
    let eventDate: Date
    let isNoTimeEvent = false
    
    if (event.start_at) {
      eventDate = new Date(event.start_at)
      // 只处理未来的有时间事件
      if (eventDate <= now) {
        return false
      }
    } else {
      // 无时间事件：使用intended_date字段确定事件归属日期
      isNoTimeEvent = true
      
      if (event.intended_date) {
        // 如果有intended_date，使用该日期的00:00 UTC作为事件时间
        const intendedDate = new Date(event.intended_date)
        eventDate = new Date(Date.UTC(intendedDate.getUTCFullYear(), intendedDate.getUTCMonth(), intendedDate.getUTCDate(), 0, 0, 0))
      } else {
        // 向后兼容：如果没有intended_date，回退到使用created_at
        const createdDate = new Date(event.created_at)
        eventDate = new Date(Date.UTC(createdDate.getUTCFullYear(), createdDate.getUTCMonth(), createdDate.getUTCDate(), 0, 0, 0))
      }
      
      // 对于无时间事件，不过滤已过期的，因为它们可能需要在未来推送
      // 例如：今天创建的无时间事件，明天需要1天前提醒
    }
    
    const timeDiffMs = eventDate.getTime() - now.getTime()
    const minutesDiff = Math.round(timeDiffMs / (1000 * 60))
    const daysDiff = Math.ceil(timeDiffMs / (1000 * 60 * 60 * 24))
    
    // 对于无时间事件，检查是否需要推送
    let adjustedDaysDiff = daysDiff
    if (isNoTimeEvent && daysDiff <= 0) {
      // 如果无时间事件已经是今天或更早，不应该再推送1天前提醒了
      // 因为1天前提醒应该在昨天就发送
      return false
    }

    // 检查新的push_reminders字段（使用调整后的daysDiff）
    const reminders = event.push_reminders || []
    for (const reminder of reminders) {
      const needsNotification = checkIfReminderNeeded(reminder, minutesDiff, adjustedDaysDiff, event.push_status)
      if (needsNotification) {
        return true
      }
    }

    // 保持向后兼容：检查旧字段（使用调整后的daysDiff）
    const needDayBefore = adjustedDaysDiff === 1 && 
                         event.push_day_before && 
                         !event.push_status?.day_before_sent

    const needWeekBefore = adjustedDaysDiff === 7 && 
                          event.push_week_before && 
                          !event.push_status?.week_before_sent

    return needDayBefore || needWeekBefore
  })
}


// 统一检查是否已发送推送（检查新旧两套系统的状态）
function isAlreadySent(pushStatus: any, reminderType: string): boolean {
  if (!pushStatus) return false
  
  // 检查新系统状态字段
  const newSystemKey = `${reminderType}_sent`
  if (pushStatus[newSystemKey] === true) {
    return true
  }
  
  // 检查旧系统状态字段（向后兼容）
  const legacyKey = getLegacyStatusKey(reminderType)
  if (legacyKey && pushStatus[legacyKey] === true) {
    return true
  }
  
  return false
}

// 获取旧系统对应的状态字段名
function getLegacyStatusKey(reminderType: string): string | null {
  switch (reminderType) {
    case '1_day':
      return 'day_before_sent'
    case '1_week':
      return 'week_before_sent'
    default:
      return null
  }
}

// 获取旧系统状态更新对象
function getLegacyStatusUpdate(reminderType: string): Record<string, boolean> {
  switch (reminderType) {
    case '1_day':
      return { 'day_before_sent': true }
    case '1_week':
      return { 'week_before_sent': true }
    default:
      return {}
  }
}


// 检查特定提醒是否需要发送（只处理长期提醒）
function checkIfReminderNeeded(reminder: string, minutesDiff: number, daysDiff: number, pushStatus: any): boolean {
  // 使用统一的已发送检查
  if (isAlreadySent(pushStatus, reminder)) {
    return false
  }
  
  // Edge Function只处理长期提醒，短期提醒由iOS本地通知处理
  switch (reminder) {
    case '1_day':
      return daysDiff === 1
    case '1_week':
      return daysDiff === 7
    // 短期提醒由iOS本地通知处理，这里跳过
    case 'at_time':
    case '15_minutes':
    case '30_minutes':
    case '1_hour':
    case '2_hours':
      console.log(`⏭️ 跳过短期提醒 ${reminder}，由iOS本地通知处理`)
      return false
    default:
      return false
  }
}

// Process a single event and generate notifications
async function processEvent(event: Event): Promise<NotificationPayload[]> {
  const notifications: NotificationPayload[] = []
  const now = new Date()
  const eventDate = new Date(event.start_at)
  const daysDiff = Math.ceil((eventDate.getTime() - now.getTime()) / (1000 * 60 * 60 * 24))

  // Get user profile information
  const { data: userProfile, error: userError } = await supabase
    .from('users')
    .select('timezone')
    .eq('id', event.user_id)
    .single()

  if (userError) {
    console.warn(`Failed to get user profile for ${event.user_id}: ${userError.message}`)
    // Use defaults if user profile not found
    userProfile = { timezone: 'Asia/Shanghai' }
  }

  // Get user's active device tokens
  const { data: devices, error: deviceError } = await supabase
    .from('user_devices')
    .select('device_token')
    .eq('user_id', event.user_id)
    .eq('is_active', true)

  if (deviceError || !devices || devices.length === 0) {
    console.warn(`No active devices found for user ${event.user_id}`)
    return notifications
  }

  const deviceTokens = devices.map((d: DeviceToken) => d.device_token)

  // Generate 1-day before notification
  if (daysDiff === 1 && event.push_day_before && !event.push_status?.day_before_sent) {
    const message = generateMessage(event, 'day_before')
    notifications.push({
      event,
      type: 'day_before',
      message,
      deviceTokens
    })
  }

  // Generate 1-week before notification
  if (daysDiff === 7 && event.push_week_before && !event.push_status?.week_before_sent) {
    const message = generateMessage(event, 'week_before')
    notifications.push({
      event,
      type: 'week_before', 
      message,
      deviceTokens
    })
  }

  return notifications
}

// Group events by user and notification type for batch sending
async function groupEventsByUserAndType(events: Event[]): Promise<NotificationPayload[]> {
  const userGroups: Map<string, Map<string, Event[]>> = new Map()
  const notifications: NotificationPayload[] = []

  // First pass: group events by user and type
  for (const event of events) {
    const now = new Date()
    
    // 统一处理：使用intended_date字段来确定事件归属日期
    let eventDate: Date
    let isNoTimeEvent = false
    
    if (event.start_at) {
      eventDate = new Date(event.start_at)
    } else {
      // 无时间事件：使用intended_date字段确定事件归属日期
      isNoTimeEvent = true
      
      if (event.intended_date) {
        // 如果有intended_date，使用该日期的00:00 UTC作为事件时间
        const intendedDate = new Date(event.intended_date)
        eventDate = new Date(Date.UTC(intendedDate.getUTCFullYear(), intendedDate.getUTCMonth(), intendedDate.getUTCDate(), 0, 0, 0))
      } else {
        // 向后兼容：如果没有intended_date，回退到使用created_at
        const createdDate = new Date(event.created_at)
        eventDate = new Date(Date.UTC(createdDate.getUTCFullYear(), createdDate.getUTCMonth(), createdDate.getUTCDate(), 0, 0, 0))
      }
    }
    
    const timeDiffMs = eventDate.getTime() - now.getTime()
    const minutesDiff = Math.round(timeDiffMs / (1000 * 60))
    const daysDiff = Math.ceil(timeDiffMs / (1000 * 60 * 60 * 24))
    
    // 对于无时间事件，检查是否需要推送
    let adjustedDaysDiff = daysDiff
    if (isNoTimeEvent && daysDiff <= 0) {
      // 如果无时间事件已经是今天或更早，不应该再推送1天前提醒了
      // 因为1天前提醒应该在昨天就发送
      continue
    }

    // Determine notification types needed for this event
    const notificationTypes: string[] = []
    
    // 简化推送判断逻辑：优先新系统，向后兼容旧系统
    const reminders = event.push_reminders || []
    
    // 1. 处理新系统配置的提醒
    for (const reminder of reminders) {
      const needsNotification = checkIfReminderNeeded(reminder, minutesDiff, adjustedDaysDiff, event.push_status)
      if (needsNotification) {
        notificationTypes.push(reminder)
      }
    }
    
    // 2. 向后兼容：处理旧系统配置（仅当新系统没有配置对应提醒时）
    if (!reminders.includes('1_day') && adjustedDaysDiff === 1 && event.push_day_before && !isAlreadySent(event.push_status, '1_day')) {
      notificationTypes.push('1_day')
    }
    
    if (!reminders.includes('1_week') && adjustedDaysDiff === 7 && event.push_week_before && !isAlreadySent(event.push_status, '1_week')) {
      notificationTypes.push('1_week')
    }

    // Group by user and type
    for (const type of notificationTypes) {
      if (!userGroups.has(event.user_id)) {
        userGroups.set(event.user_id, new Map())
      }
      
      const userTypeGroups = userGroups.get(event.user_id)!
      if (!userTypeGroups.has(type)) {
        userTypeGroups.set(type, [])
      }
      
      userTypeGroups.get(type)!.push(event)
    }
  }

  // Second pass: create notification payloads for each user-type group
  for (const [userId, typeGroups] of userGroups) {
    // Get user's active device tokens
    const { data: devices, error: deviceError } = await supabase
      .from('user_devices')
      .select('device_token')
      .eq('user_id', userId)
      .eq('is_active', true)

    if (deviceError || !devices || devices.length === 0) {
      console.warn(`No active devices found for user ${userId}`)
      continue
    }

    const deviceTokens = devices.map((d: DeviceToken) => d.device_token)

    // Create notification for each type
    for (const [type, eventsOfType] of typeGroups) {
      const message = await generateBatchMessage(eventsOfType, type as ReminderType)
      
      notifications.push({
        events: eventsOfType,
        type: type as ReminderType,
        message,
        deviceTokens,
        userId
      })
    }
  }

  return notifications
}

// 映射新系统类型到数据库类型
function mapTypeToDbType(type: ReminderType): string | null {
  switch (type) {
    case '1_day':
      return 'day_before'
    case '1_week':
      return 'week_before'
    default:
      return null
  }
}

// 从数据库随机获取推送模板
async function getRandomPushTemplate(type: ReminderType): Promise<string | null> {
  try {
    // 映射新系统类型到数据库类型
    const dbType = mapTypeToDbType(type)
    if (!dbType) {
      console.warn(`No database type mapping for: ${type}`)
      return null
    }
    
    const { data: templates, error } = await supabase
      .from('push_templates')
      .select('template')
      .eq('type', dbType)
    
    if (error) {
      console.warn(`Failed to fetch templates for ${dbType}: ${error.message}`)
      return null
    }
    
    if (!templates || templates.length === 0) {
      console.warn(`No templates found for type: ${dbType}`)
      return null
    }
    
    // 随机选择一个模板
    const randomIndex = Math.floor(Math.random() * templates.length)
    console.log(`🎭 随机选择模板 ${dbType}: ${randomIndex + 1}/${templates.length}`)
    return templates[randomIndex].template
    
  } catch (error) {
    console.error(`Error fetching template: ${error}`)
    return null
  }
}

// Generate batch push message with random templates from database
async function generateBatchMessage(events: Event[], type: ReminderType): Promise<string> {
  const count = events.length
  
  // 尝试从数据库获取随机模板
  const dbTemplate = await getRandomPushTemplate(type)
  
  if (count === 1) {
    const event = events[0]
    const title = event.title
    
    // 如果有数据库模板，使用模板
    if (dbTemplate) {
      return dbTemplate.replace('{title}', title)
    }
    
    // 回退到硬编码模板（兼容性保证）
    // 针对无时间事件的文案
    if (!event.start_at) {
      const templates = {
        '1_day': `别忘了「${title}」这事儿，拖了这么久该动手了吧？`,
        '1_week': `「${title}」都一周了还没搞，再不动手就凉了！`
      }
      return templates[type] || `「${title}」该处理了`
    }
    
    // 有具体时间的事件文案
    const templates = {
      '1_day': `明天「${title}」，别又临时找借口说忘了！`,
      '1_week': `一周后「${title}」，现在不准备待会儿又手忙脚乱？`
    }
    return templates[type] || `「${title}」提醒`
  } else {
    // 批量事件：优先使用硬编码逻辑（因为数据库模板主要针对单个事件）
    const displayTitles = events.slice(0, 3).map(e => `「${e.title}」`)
    const titleText = displayTitles.join('、')
    
    // 检查是否包含无时间事件
    const hasNoTimeEvents = events.some(e => !e.start_at)
    
    // 混合事件的文案
    if (hasNoTimeEvents) {
      const templates = {
        '1_day': `${titleText}等${count}件事，有的该做了，有的明天要开始，别都堆一块儿！`,
        '1_week': `${titleText}等${count}个安排，该准备的准备，该处理的处理！`
      }
      return templates[type] || `${count}件事需要关注`
    }
    
    // 纯时间事件的文案
    const templates = {
      '1_day': `明天${titleText}等${count}件事等着，忙死你了吧？`,
      '1_week': `下周${titleText}等${count}个安排，别到时候又说没时间！`
    }
    return templates[type] || `${count}件事提醒`
  }
}

// Keep the old function for backward compatibility
async function generateMessage(event: Event, type: ReminderType): Promise<string> {
  return await generateBatchMessage([event], type)
}

// Generate JWT token for APNs
async function generateAPNsJWT(): Promise<string> {
  try {
    console.log('🔑 Generating APNs JWT token...')
    console.log(`🔑 Key ID: ${APNS_KEY_ID}`)
    console.log(`🔑 Team ID: ${APNS_TEAM_ID}`)
    console.log(`🔑 Private Key length: ${APNS_PRIVATE_KEY?.length || 0}`)
    
    const privateKey = await jose.importPKCS8(APNS_PRIVATE_KEY, 'ES256')
    console.log('🔑 Private key imported successfully')
    
    const jwt = await new jose.SignJWT({})
      .setProtectedHeader({
        alg: 'ES256',
        kid: APNS_KEY_ID
      })
      .setIssuedAt()
      .setIssuer(APNS_TEAM_ID)
      .setExpirationTime('1h')
      .sign(privateKey)

    console.log('🔑 JWT token generated successfully')
    return jwt
  } catch (error) {
    console.error('❌ Failed to generate APNs JWT token:', error)
    throw new Error(`JWT generation failed: ${error.message}`)
  }
}

type PushSendResult = {
  successCount: number
  failureCount: number
  failures: Array<{ token: string; status: number; body: string }>
}

// Send push notification via APNs
async function sendPushNotification(notification: NotificationPayload): Promise<PushSendResult> {
  const jwt = await generateAPNsJWT()
  
  const payload = {
    aps: {
      alert: {
        title: "HiCalendar提醒",
        body: notification.message
      },
      badge: 1,
      sound: "default",
      'mutable-content': 1
    },
    event_id: notification.events[0].id, // Use first event ID as representative
    notification_type: notification.type,
    event_count: notification.events.length // Add event count for batch tracking
  }

  // Send to all device tokens
  const promises = notification.deviceTokens.map(async (deviceToken) => {
    console.log(`📤 Sending push to device: ${deviceToken.substring(0, 8)}...`)
    console.log(`🔗 APNs Host: ${APNS_HOST}`)
    console.log(`📦 Payload: ${JSON.stringify(payload)}`)
    
    // Force HTTP/2 for APNs (Deno supports HTTP/2 by default with fetch)
    const response = await fetch(`https://${APNS_HOST}/3/device/${deviceToken}`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${jwt}`,
        'apns-topic': BUNDLE_ID,
        'apns-push-type': 'alert',
        'apns-expiration': '0',
        'apns-priority': '10',
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(payload),
      // Ensure HTTP/2 is used - Deno's fetch should use HTTP/2 by default for HTTPS
      // @ts-ignore - Deno specific fetch options
      http2: true
    })

    if (!response.ok) {
      const errorBody = await response.text()
      console.error(`🚨 APNs Push Failed:`)
      console.error(`  Status: ${response.status}`)
      console.error(`  Device Token: ${deviceToken}`)
      console.error(`  Response Body: ${errorBody}`)
      console.error(`  Response Headers:`, Object.fromEntries(response.headers.entries()))
      // Do not throw; let us record partial failures and continue
      return { ok: false as const, deviceToken, status: response.status, body: errorBody }
    } else {
      console.log(`✅ APNs Push Success to device: ${deviceToken.substring(0, 8)}...`)
      console.log(`  APNs ID: ${response.headers.get('apns-id') || 'N/A'}`)
      return { ok: true as const, deviceToken }
    }
  })

  const results = await Promise.all(promises)

  const successCount = results.filter((r: any) => r?.ok === true).length
  const failures = results
    .filter((r: any) => r?.ok === false)
    .map((r: any) => ({ token: r.deviceToken, status: r.status, body: r.body }))

  // Deactivate obviously invalid tokens
  const invalid = failures
    .filter(f => f.status === 400 || f.status === 410)
    .filter(f => /BadDeviceToken|Unregistered/i.test(f.body))
    .map(f => f.token)
  if (invalid.length > 0) {
    try {
      const { error } = await supabase
        .from('user_devices')
        .update({ is_active: false })
        .in('device_token', invalid)
      if (error) {
        console.warn(`Failed to deactivate invalid tokens: ${error.message}`)
      } else {
        console.log(`🧹 Deactivated ${invalid.length} invalid device tokens`)
      }
    } catch (e) {
      console.warn(`Error deactivating invalid tokens: ${e.message}`)
    }
  }

  return { successCount, failureCount: failures.length, failures }
}

// Mark batch notifications as sent in database
async function markBatchNotificationAsSent(notification: NotificationPayload) {
  // Update all events in the batch
  const updatePromises = notification.events.map(async (event) => {
    const pushStatus = {
      ...event.push_status,
      // 主要使用新系统状态字段
      [`${notification.type}_sent`]: true,
      // 同时更新旧系统字段以保持兼容性
      ...getLegacyStatusUpdate(notification.type)
    }

    const { error } = await supabase
      .from('events')
      .update({ push_status: pushStatus })
      .eq('id', event.id)

    if (error) {
      console.error(`Failed to update push status for event ${event.id}: ${error.message}`)
      throw new Error(`Database update failed for event ${event.id}: ${error.message}`)
    } else {
      console.log(`✅ Updated push_status for event ${event.id}: ${JSON.stringify(pushStatus)}`)
    }

    // Log individual notification for each event
    // 映射type值以符合数据库约束
    const dbType = mapTypeToDbType(notification.type) || notification.type
    
    const { error: logError } = await supabase
      .from('push_notifications')
      .insert({
        user_id: event.user_id,
        event_id: event.id,
        type: dbType, // 使用映射后的type值
        message: notification.message,
        sent_at: new Date().toISOString(),
        status: 'sent'
      })

    if (logError) {
      console.warn(`Failed to log notification for event ${event.id}:`, logError.message)
    }
  })

  await Promise.all(updatePromises)
}


// Log batch notification failure
async function logBatchNotificationFailure(notification: NotificationPayload, error: Error) {
  const logPromises = notification.events.map(async (event) => {
    // 映射type值以符合数据库约束
    const dbType = mapTypeToDbType(notification.type) || notification.type
    
    const { error: logError } = await supabase
      .from('push_notifications')
      .insert({
        user_id: event.user_id,
        event_id: event.id,
        type: dbType, // 使用映射后的type值
        message: notification.message,
        sent_at: new Date().toISOString(),
        status: 'failed',
        apns_response: error.message
      })

    if (logError) {
      console.warn(`Failed to log notification failure for event ${event.id}:`, logError.message)
    }
  })

  await Promise.all(logPromises)
}

// Keep old functions for backward compatibility
async function markNotificationAsSent(notification: NotificationPayload) {
  // Delegate to batch function for consistency
  await markBatchNotificationAsSent(notification)
}

async function logNotificationFailure(notification: NotificationPayload, error: Error) {
  // Delegate to batch function for consistency
  await logBatchNotificationFailure(notification, error)
}

// 推送优化清理：清理旧的推送数据但保留events数据
async function cleanupOldPushData() {
  const cleanupResult = {
    deletedNotifications: 0,
    resetPushStatus: 0,
    errors: []
  }

  try {
    // 1. 清理30天前的推送记录
    const { count: deletedCount, error: deleteError } = await supabase
      .from('push_notifications')
      .delete()
      .lt('sent_at', new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString())

    if (deleteError) {
      console.warn('Failed to delete old push notifications:', deleteError.message)
      cleanupResult.errors.push(`Delete notifications: ${deleteError.message}`)
    } else {
      cleanupResult.deletedNotifications = deletedCount || 0
      console.log(`🗑️ Deleted ${cleanupResult.deletedNotifications} old push notification records`)
    }

    // 2. 重置过期事件的push_status（更保守的策略：只重置明确过期的事件）
    // 只重置7天前的有时间事件 + 14天前的无时间事件
    const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString()
    const fourteenDaysAgo = new Date(Date.now() - 14 * 24 * 60 * 60 * 1000).toISOString()
    
    const { count: resetCount, error: resetError } = await supabase
      .from('events')
      .update({ push_status: null })
      .or(`start_at.lt.${sevenDaysAgo},and(start_at.is.null,created_at.lt.${fourteenDaysAgo})`)
      .not('push_status', 'is', null)

    if (resetError) {
      console.warn('Failed to reset push status for expired events:', resetError.message)
      cleanupResult.errors.push(`Reset push status: ${resetError.message}`)
    } else {
      cleanupResult.resetPushStatus = resetCount || 0
      console.log(`🔄 Reset push_status for ${cleanupResult.resetPushStatus} expired events`)
    }

  } catch (error) {
    console.error('Cleanup error:', error)
    cleanupResult.errors.push(`General error: ${error.message}`)
  }

  return cleanupResult
}
