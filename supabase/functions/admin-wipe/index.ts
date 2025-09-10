// Minimal admin endpoint to wipe all rows in events
// Protected by a static token set in project secrets (ADMIN_TASK_TOKEN)

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
const ADMIN_TASK_TOKEN = Deno.env.get('ADMIN_TASK_TOKEN') || ''

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

serve(async (req) => {
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-admin-token'
  }

  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    if (req.method !== 'POST') {
      return new Response(JSON.stringify({ error: 'Method Not Allowed' }), { status: 405, headers: corsHeaders })
    }

    // Simple header token auth
    const token = req.headers.get('x-admin-token') || ''
    if (!ADMIN_TASK_TOKEN || token !== ADMIN_TASK_TOKEN) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401, headers: corsHeaders })
    }

    // Delete all rows in events (match-all using IS NOT NULL)
    const { error, count } = await supabase
      .from('events')
      .delete({ count: 'exact' })
      .not('id', 'is', null)

    if (error) {
      console.error('Wipe events error:', error.message)
      return new Response(JSON.stringify({ success: false, error: error.message }), { status: 500, headers: corsHeaders })
    }

    return new Response(JSON.stringify({ success: true, deleted: count || 0 }), { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  } catch (e) {
    return new Response(JSON.stringify({ success: false, error: e.message }), { status: 500, headers: corsHeaders })
  }
})

