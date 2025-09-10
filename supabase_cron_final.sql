-- HiCalendar Push Notification Cron Job Setup (Final Version)
-- 在Supabase SQL编辑器中执行

-- 1. 启用pg_cron扩展（如果未启用）
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- 2. 删除旧的定时任务（如果存在）
SELECT cron.unschedule('hicalendar-push-scheduler');

-- 3. 创建新的定时任务
-- 每天北京时间上午9:00执行（UTC+8 = 01:00 UTC）
SELECT cron.schedule(
    'hicalendar-push-scheduler',
    '0 1 * * *',  -- 每天UTC 1点 = 北京时间9点
    $$
    SELECT
        net.http_post(
            url := 'https://ngzzciukzokypzzpcbvj.supabase.co/functions/v1/push-scheduler',
            headers := jsonb_build_object(
                'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5nenpjaXVrem9reXB6enBjYnZqIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NTY4MzcwNSwiZXhwIjoyMDcxMjU5NzA1fQ.V-JcSzeVbv7CL3zvKXjzsNfFsW-A8uDiK51G5mOxzU8',
                'Content-Type', 'application/json'
            ),
            body := jsonb_build_object(
                'scheduled', true,
                'timestamp', extract(epoch from now())
            )
        ) as request_id;
    $$
);

-- 4. 验证定时任务是否创建成功
SELECT jobname, schedule, active, 
       'Scheduled for Beijing Time 9:00 AM daily (UTC 1:00)' as description
FROM cron.job 
WHERE jobname = 'hicalendar-push-scheduler';

-- 5. 手动触发测试推送
SELECT 'Manual test trigger:' as info,
    net.http_post(
        url := 'https://ngzzciukzokypzzpcbvj.supabase.co/functions/v1/push-scheduler',
        headers := jsonb_build_object(
            'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5nenpjaXVrem9reXB6enBjYnZqIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NTY4MzcwNSwiZXhwIjoyMDcxMjU5NzA1fQ.V-JcSzeVbv7CL3zvKXjzsNfFsW-A8uDiK51G5mOxzU8',
            'Content-Type', 'application/json'
        ),
        body := jsonb_build_object(
            'manual_trigger', true,
            'timestamp', extract(epoch from now())
        )
    ) as response;

COMMENT ON EXTENSION pg_cron IS 'HiCalendar推送通知定时任务扩展';

-- 6. 显示系统状态
SELECT 'System Status Check:' as info;

-- 检查推送模板
SELECT 'Push templates count:' as info, COUNT(*) as count FROM push_templates;

-- 检查用户数量
SELECT 'Users count:' as info, COUNT(*) as count FROM public.users;

-- 检查事件数量
SELECT 'Events count:' as info, COUNT(*) as count FROM events;

-- 检查设备数量
SELECT 'Active devices:' as info, COUNT(*) as count FROM user_devices WHERE is_active = true;

-- 7. 查看定时任务执行历史（调试用）
-- 执行完成后可以用这个查询检查执行历史
-- SELECT jobname, runid, job_pid, database, username, command, status, return_message, start_time, end_time
-- FROM cron.job_run_details 
-- WHERE jobname = 'hicalendar-push-scheduler'
-- ORDER BY start_time DESC
-- LIMIT 10;