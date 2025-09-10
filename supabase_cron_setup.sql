-- HiCalendar Push Notification Cron Job Setup
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
            url := 'https://your-project.supabase.co/functions/v1/push-scheduler',
            headers := jsonb_build_object(
                'Authorization', 'Bearer your-service-role-key',
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
SELECT jobname, schedule, active FROM cron.job WHERE jobname = 'hicalendar-push-scheduler';

-- 5. 手动触发测试（可选，用于调试）
-- SELECT
--     net.http_post(
--         url := 'https://your-project.supabase.co/functions/v1/push-scheduler',
--         headers := jsonb_build_object(
--             'Authorization', 'Bearer your-service-role-key',
--             'Content-Type', 'application/json'
--         ),
--         body := jsonb_build_object(
--             'manual_trigger', true,
--             'timestamp', extract(epoch from now())
--         )
--     ) as request_id;

-- 注意：
-- 1. 需要将 'https://your-project.supabase.co' 替换为你的实际Supabase项目URL
-- 2. 需要将 'your-service-role-key' 替换为你的Service Role Key
-- 3. 确保Edge Function 'push-scheduler' 已部署
-- 4. 定时任务将在每天北京时间9:00执行，可以根据需要调整时间

COMMENT ON EXTENSION pg_cron IS 'HiCalendar推送通知定时任务扩展';

-- 查看定时任务执行历史（调试用）
-- SELECT jobname, runid, job_pid, database, username, command, status, return_message, start_time, end_time
-- FROM cron.job_run_details 
-- WHERE jobname = 'hicalendar-push-scheduler'
-- ORDER BY start_time DESC
-- LIMIT 10;