import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

interface Database {
  public: {
    Tables: {
      users: {
        Row: {
          id: string
          email: string | null
          timezone: string | null
          sarcasm_level: number | null
          default_push_day_before: boolean | null
          default_push_week_before: boolean | null
          is_member: boolean | null
          membership_expires_at: string | null
          created_at: string | null
          updated_at: string | null
        }
        Insert: {
          id: string
          email?: string | null
          timezone?: string | null
          sarcasm_level?: number | null
          default_push_day_before?: boolean | null
          default_push_week_before?: boolean | null
          is_member?: boolean | null
          membership_expires_at?: string | null
        }
        Update: {
          email?: string | null
          timezone?: string | null
          sarcasm_level?: number | null
          default_push_day_before?: boolean | null
          default_push_week_before?: boolean | null
          is_member?: boolean | null
          membership_expires_at?: string | null
          updated_at?: string | null
        }
      }
      events: {
        Row: {
          id: string
          user_id: string
          title: string
          start_at: string | null
          end_at: string | null
          details: string | null
          intended_date: string | null
          push_reminders: string[] | null
          push_day_before: boolean | null
          push_week_before: boolean | null
          push_status: any | null
          created_at: string | null
          updated_at: string | null
        }
        Insert: {
          id?: string
          user_id: string
          title: string
          start_at?: string | null
          end_at?: string | null
          details?: string | null
          intended_date?: string | null
          push_reminders?: string[] | null
          push_day_before?: boolean | null
          push_week_before?: boolean | null
          push_status?: any | null
        }
        Update: {
          title?: string
          start_at?: string | null
          end_at?: string | null
          details?: string | null
          intended_date?: string | null
          push_reminders?: string[] | null
          push_day_before?: boolean | null
          push_week_before?: boolean | null
          push_status?: any | null
          updated_at?: string | null
        }
      }
      user_devices: {
        Row: {
          id: string
          user_id: string | null
          device_token: string
          platform: string | null
          is_active: boolean | null
          created_at: string | null
          updated_at: string | null
        }
      }
      sync_queue: {
        Row: {
          id: number
          table_name: string
          row_id: string
          operation: string
          payload: any
          created_at: string | null
          processed: boolean | null
          processed_at: string | null
          error_message: string | null
        }
        Update: {
          processed?: boolean
          processed_at?: string
          error_message?: string | null
        }
      }
    }
  }
}

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
}

serve(async (req) => {
  // 处理 CORS 预检请求
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders })
  }

  try {
    const supabaseClient = createClient<Database>(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const url = new URL(req.url)
    const action = url.searchParams.get('action') || 'sync'

    switch (action) {
      case 'sync':
        return await handleSync(supabaseClient)
      case 'backup':
        return await handleBackup(supabaseClient, req)
      case 'restore':
        return await handleRestore(supabaseClient, req)
      case 'member-upgrade':
        return await handleMemberUpgrade(supabaseClient, req)
      default:
        return new Response(
          JSON.stringify({ error: 'Invalid action' }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
    }
  } catch (error) {
    console.error('Edge Function error:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})

// 处理数据同步
async function handleSync(supabase: any) {
  console.log('Processing member data sync...')

  // 获取未处理的同步任务
  const { data: syncTasks, error: fetchError } = await supabase
    .from('sync_queue')
    .select('*')
    .eq('processed', false)
    .order('created_at', { ascending: true })
    .limit(100)

  if (fetchError) {
    throw new Error(`Failed to fetch sync tasks: ${fetchError.message}`)
  }

  if (!syncTasks || syncTasks.length === 0) {
    return new Response(
      JSON.stringify({
        message: 'No pending sync tasks',
        processed_count: 0
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }

  const results = []
  let successCount = 0
  let errorCount = 0

  // 处理每个同步任务
  for (const task of syncTasks) {
    try {
      await processSyncTask(supabase, task)

      // 标记为已处理
      await supabase
        .from('sync_queue')
        .update({
          processed: true,
          processed_at: new Date().toISOString()
        })
        .eq('id', task.id)

      results.push({
        task_id: task.id,
        status: 'success',
        table: task.table_name,
        operation: task.operation
      })
      successCount++
    } catch (error) {
      console.error(`Failed to process sync task ${task.id}:`, error)

      // 记录错误
      await supabase
        .from('sync_queue')
        .update({
          error_message: error.message
        })
        .eq('id', task.id)

      results.push({
        task_id: task.id,
        status: 'error',
        error: error.message
      })
      errorCount++
    }
  }

  // 更新同步元数据
  await supabase
    .from('sync_metadata')
    .upsert({
      key: 'last_sync_timestamp',
      value: new Date().toISOString(),
      updated_at: new Date().toISOString()
    })

  return new Response(
    JSON.stringify({
      message: 'Sync completed',
      total_tasks: syncTasks.length,
      success_count: successCount,
      error_count: errorCount,
      results: results
    }),
    { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
  )
}

// 处理单个同步任务
async function processSyncTask(supabase: any, task: any) {
  const { table_name, row_id, operation, payload } = task

  switch (operation.toLowerCase()) {
    case 'insert':
    case 'update':
      if (table_name === 'users') {
        await supabase
          .from('users')
          .upsert(payload, { onConflict: 'id' })
      } else if (table_name === 'events') {
        await supabase
          .from('events')
          .upsert(payload, { onConflict: 'id' })
      } else if (table_name === 'user_devices') {
        await supabase
          .from('user_devices')
          .upsert(payload, { onConflict: 'device_token' })
      }
      break

    case 'delete':
      await supabase
        .from(table_name)
        .delete()
        .eq('id', row_id)
      break

    default:
      throw new Error(`Unsupported operation: ${operation}`)
  }
}

// 处理会员升级
async function handleMemberUpgrade(supabase: any, req: Request) {
  const { user_id, membership_expires_at } = await req.json()

  if (!user_id) {
    throw new Error('user_id is required')
  }

  // 更新用户会员状态
  const { error } = await supabase
    .from('users')
    .update({
      is_member: true,
      membership_expires_at: membership_expires_at || null,
      updated_at: new Date().toISOString()
    })
    .eq('id', user_id)

  if (error) {
    throw new Error(`Failed to upgrade member: ${error.message}`)
  }

  // 添加到同步队列（如果需要同步到其他地方）
  await supabase
    .from('sync_queue')
    .insert({
      table_name: 'users',
      row_id: user_id,
      operation: 'update',
      payload: {
        id: user_id,
        is_member: true,
        membership_expires_at: membership_expires_at,
        updated_at: new Date().toISOString()
      }
    })

  return new Response(
    JSON.stringify({
      message: 'Member upgraded successfully',
      user_id: user_id
    }),
    { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
  )
}

// 处理数据备份
async function handleBackup(supabase: any, req: Request) {
  const { user_id } = await req.json()

  if (!user_id) {
    throw new Error('user_id is required')
  }

  // 获取用户信息
  const { data: user, error: userError } = await supabase
    .from('users')
    .select('*')
    .eq('id', user_id)
    .eq('is_member', true)
    .single()

  if (userError || !user) {
    throw new Error('Member user not found')
  }

  // 获取用户的所有事件
  const { data: events, error: eventsError } = await supabase
    .from('events')
    .select('*')
    .eq('user_id', user_id)
    .order('created_at', { ascending: false })

  if (eventsError) {
    throw new Error(`Failed to fetch events: ${eventsError.message}`)
  }

  // 获取用户设备
  const { data: devices, error: devicesError } = await supabase
    .from('user_devices')
    .select('*')
    .eq('user_id', user_id)

  if (devicesError) {
    throw new Error(`Failed to fetch devices: ${devicesError.message}`)
  }

  const backup = {
    user: user,
    events: events || [],
    devices: devices || [],
    backup_timestamp: new Date().toISOString(),
    version: '1.0'
  }

  return new Response(
    JSON.stringify({
      message: 'Backup created successfully',
      backup: backup,
      stats: {
        events_count: events?.length || 0,
        devices_count: devices?.length || 0
      }
    }),
    { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
  )
}

// 处理数据恢复
async function handleRestore(supabase: any, req: Request) {
  const { user_id, backup_data } = await req.json()

  if (!user_id || !backup_data) {
    throw new Error('user_id and backup_data are required')
  }

  const { user, events, devices } = backup_data

  // 恢复用户信息
  if (user) {
    await supabase
      .from('users')
      .upsert({
        ...user,
        updated_at: new Date().toISOString()
      }, { onConflict: 'id' })
  }

  // 恢复事件数据
  if (events && events.length > 0) {
    for (const event of events) {
      await supabase
        .from('events')
        .upsert({
          ...event,
          updated_at: new Date().toISOString()
        }, { onConflict: 'id' })
    }
  }

  // 恢复设备信息
  if (devices && devices.length > 0) {
    for (const device of devices) {
      await supabase
        .from('user_devices')
        .upsert({
          ...device,
          updated_at: new Date().toISOString()
        }, { onConflict: 'device_token' })
    }
  }

  return new Response(
    JSON.stringify({
      message: 'Data restored successfully',
      user_id: user_id,
      restored: {
        events_count: events?.length || 0,
        devices_count: devices?.length || 0
      }
    }),
    { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
  )
}