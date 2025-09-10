-- 创建立即可测试的推送事件
-- 在Supabase SQL编辑器中执行

-- 1. 创建测试用户（如果不存在）
INSERT INTO auth.users (id, email, created_at, updated_at)
VALUES 
(
    'test-user-uuid-12345678',
    'test@hicalendar.com',
    NOW(),
    NOW()
) ON CONFLICT (id) DO NOTHING;

-- 2. 创建用户扩展信息
INSERT INTO public.users (id, email, sarcasm_level, default_push_day_before, default_push_week_before)
VALUES 
(
    'test-user-uuid-12345678',
    'test@hicalendar.com', 
    2,  -- 中等吐槽等级
    true, 
    true
) ON CONFLICT (id) DO UPDATE SET
    sarcasm_level = EXCLUDED.sarcasm_level,
    default_push_day_before = EXCLUDED.default_push_day_before,
    default_push_week_before = EXCLUDED.default_push_week_before;

-- 3. 创建明天的测试事件（触发1天前推送）
INSERT INTO events (id, user_id, title, start_at, end_at, details, push_day_before, push_week_before, push_status)
VALUES 
(
    gen_random_uuid(),
    'test-user-uuid-12345678',
    '重要测试会议 📋',
    NOW() + INTERVAL '1 day',  -- 明天
    NOW() + INTERVAL '1 day' + INTERVAL '1 hour',
    '这是一个推送测试事件',
    true,   -- 开启1天前推送
    false,  -- 关闭1周前推送
    '{}'    -- 空的推送状态
) ON CONFLICT DO NOTHING;

-- 4. 创建7天后的测试事件（触发1周前推送）
INSERT INTO events (id, user_id, title, start_at, end_at, details, push_day_before, push_week_before, push_status)
VALUES 
(
    gen_random_uuid(),
    'test-user-uuid-12345678',
    '团队聚餐 🍽️',
    NOW() + INTERVAL '7 days',  -- 7天后
    NOW() + INTERVAL '7 days' + INTERVAL '2 hours',
    '团队聚餐活动，地点待定',
    true,   -- 开启1天前推送
    true,   -- 开启1周前推送
    '{}'    -- 空的推送状态
) ON CONFLICT DO NOTHING;

-- 5. 创建测试设备Token
INSERT INTO user_devices (id, user_id, device_token, platform, is_active)
VALUES 
(
    gen_random_uuid(),
    'test-user-uuid-12345678',
    'test_device_token_for_push_notification_testing',
    'ios',
    true
) ON CONFLICT (device_token) DO NOTHING;

-- 6. 验证创建的测试数据
SELECT 'Test events that should trigger push:' as info;

SELECT 
    e.title,
    e.start_at,
    e.push_day_before,
    e.push_week_before,
    EXTRACT(days FROM (e.start_at - NOW())) as days_until_event,
    u.sarcasm_level
FROM events e
JOIN public.users u ON e.user_id = u.id
WHERE e.user_id = 'test-user-uuid-12345678'
ORDER BY e.start_at;

SELECT 'Active device tokens:' as info;
SELECT device_token, is_active FROM user_devices WHERE user_id = 'test-user-uuid-12345678';