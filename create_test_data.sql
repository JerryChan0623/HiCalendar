-- HiCalendar 推送系统测试数据
-- 在Supabase SQL编辑器中执行

-- 1. 创建测试用户（模拟注册用户）
-- 注意：实际环境中用户通过Apple登录自动创建
INSERT INTO public.users (id, email, sarcasm_level, default_push_day_before, default_push_week_before)
VALUES 
(
    gen_random_uuid(),
    'test@hicalendar.com', 
    2,  -- 中等吐槽等级
    true, 
    true
) ON CONFLICT (id) DO NOTHING;

-- 获取测试用户ID（用于后续插入）
-- 注意：实际使用时需要替换为真实的auth.users.id
\set test_user_id (SELECT id FROM public.users WHERE email = 'test@hicalendar.com' LIMIT 1)

-- 2. 创建明天的测试事件（应该触发1天前推送）
INSERT INTO events (id, user_id, title, start_at, end_at, details, push_day_before, push_week_before, push_status)
VALUES 
(
    gen_random_uuid(),
    (SELECT id FROM public.users WHERE email = 'test@hicalendar.com' LIMIT 1),
    '重要会议 📝',
    NOW() + INTERVAL '1 day' + INTERVAL '10 hours',  -- 明天上午10点
    NOW() + INTERVAL '1 day' + INTERVAL '11 hours',  -- 明天上午11点
    '这是一个测试会议，用于验证推送通知功能',
    true,   -- 开启1天前推送
    false,  -- 关闭1周前推送
    '{}'    -- 空的推送状态，表示还未发送
);

-- 3. 创建7天后的测试事件（应该触发1周前推送）
INSERT INTO events (id, user_id, title, start_at, end_at, details, push_day_before, push_week_before, push_status)
VALUES 
(
    gen_random_uuid(),
    (SELECT id FROM public.users WHERE email = 'test@hicalendar.com' LIMIT 1),
    '团队建设活动 🎯',
    NOW() + INTERVAL '7 days' + INTERVAL '14 hours', -- 7天后下午2点
    NOW() + INTERVAL '7 days' + INTERVAL '18 hours', -- 7天后下午6点
    '团队户外拓展活动，地点待定',
    true,   -- 开启1天前推送
    true,   -- 开启1周前推送
    '{}'    -- 空的推送状态，表示还未发送
);

-- 4. 创建测试设备Token（模拟iOS设备注册）
-- 注意：这是假的设备Token，仅用于测试数据结构
INSERT INTO user_devices (id, user_id, device_token, platform, is_active)
VALUES 
(
    gen_random_uuid(),
    (SELECT id FROM public.users WHERE email = 'test@hicalendar.com' LIMIT 1),
    'fake_device_token_for_testing_1234567890abcdef', -- 假的设备Token
    'ios',
    true
) ON CONFLICT (device_token) DO NOTHING;

-- 5. 验证测试数据
-- 查看创建的用户
SELECT 'Test User Created:' as info, id, email, sarcasm_level 
FROM public.users WHERE email = 'test@hicalendar.com';

-- 查看创建的事件
SELECT 'Test Events Created:' as info, id, title, start_at, push_day_before, push_week_before
FROM events 
WHERE user_id = (SELECT id FROM public.users WHERE email = 'test@hicalendar.com' LIMIT 1)
ORDER BY start_at;

-- 查看设备Token
SELECT 'Test Device Created:' as info, device_token, platform, is_active
FROM user_devices 
WHERE user_id = (SELECT id FROM public.users WHERE email = 'test@hicalendar.com' LIMIT 1);

-- 6. 手动触发Edge Function测试（可选）
-- 执行这个查询来手动测试推送功能
-- SELECT
--     net.http_post(
--         url := 'https://ngzzciukzokypzzpcbvj.supabase.co/functions/v1/push-scheduler',
--         headers := jsonb_build_object(
--             'Authorization', 'Bearer YOUR_SERVICE_ROLE_KEY_HERE',
--             'Content-Type', 'application/json'
--         ),
--         body := jsonb_build_object(
--             'manual_test', true,
--             'timestamp', extract(epoch from now())
--         )
--     ) as request_id;