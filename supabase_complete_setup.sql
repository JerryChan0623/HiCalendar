-- HiCalendar 完整数据库结构
-- 在Supabase SQL编辑器中执行

-- 1. 创建users扩展表（扩展auth.users）
-- 注意：Supabase的auth.users是系统表，我们需要创建一个public.users表来存储额外信息
DROP TABLE IF EXISTS public.users CASCADE;
CREATE TABLE public.users (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    email TEXT,
    timezone TEXT DEFAULT 'Asia/Shanghai',
    sarcasm_level INT2 DEFAULT 1 CHECK (sarcasm_level >= 0 AND sarcasm_level <= 3),
    default_push_day_before BOOLEAN DEFAULT true,
    default_push_week_before BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. 创建events表
DROP TABLE IF EXISTS events CASCADE;
CREATE TABLE events (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    title TEXT NOT NULL,
    start_at TIMESTAMPTZ,
    end_at TIMESTAMPTZ,
    details TEXT,
    push_day_before BOOLEAN DEFAULT true,
    push_week_before BOOLEAN DEFAULT false,
    push_status JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. 用户设备表（存储APNs device tokens）
DROP TABLE IF EXISTS user_devices CASCADE;
CREATE TABLE user_devices (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    device_token TEXT NOT NULL UNIQUE,
    platform TEXT DEFAULT 'ios' CHECK (platform IN ('ios')),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. 推送通知记录表（用于统计和调试）
DROP TABLE IF EXISTS push_notifications CASCADE;
CREATE TABLE push_notifications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    event_id UUID REFERENCES events(id) ON DELETE CASCADE,
    device_token TEXT,
    type TEXT CHECK (type IN ('day_before', 'week_before')),
    message TEXT,
    sent_at TIMESTAMPTZ DEFAULT NOW(),
    status TEXT DEFAULT 'sent' CHECK (status IN ('sent', 'failed', 'retry')),
    apns_response TEXT
);

-- 5. 推送文案模板表
DROP TABLE IF EXISTS push_templates CASCADE;
CREATE TABLE push_templates (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    type TEXT CHECK (type IN ('day_before', 'week_before')),
    sarcasm_level INT2 CHECK (sarcasm_level >= 0 AND sarcasm_level <= 3),
    template TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. 创建索引优化查询性能
-- users表索引
CREATE INDEX idx_users_id ON public.users(id);

-- events表索引
CREATE INDEX idx_events_user_id ON events(user_id);
CREATE INDEX idx_events_start_at ON events(start_at);
CREATE INDEX idx_events_push_status ON events USING gin(push_status);

-- user_devices表索引
CREATE INDEX idx_user_devices_user_id ON user_devices(user_id);
CREATE INDEX idx_user_devices_active ON user_devices(is_active);

-- push_notifications表索引
CREATE INDEX idx_push_notifications_user_id ON push_notifications(user_id);
CREATE INDEX idx_push_notifications_event_id ON push_notifications(event_id);
CREATE INDEX idx_push_notifications_sent_at ON push_notifications(sent_at);

-- 7. 设置行级安全策略 (RLS)
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE events ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE push_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE push_templates ENABLE ROW LEVEL SECURITY;

-- 删除现有策略（如果存在）
DROP POLICY IF EXISTS "Users can manage own profile" ON public.users;
DROP POLICY IF EXISTS "Users can manage own events" ON events;
DROP POLICY IF EXISTS "Users can manage own devices" ON user_devices;
DROP POLICY IF EXISTS "Users can view own push records" ON push_notifications;
DROP POLICY IF EXISTS "Service role can manage push records" ON push_notifications;
DROP POLICY IF EXISTS "Templates are publicly readable" ON push_templates;

-- Users表策略
CREATE POLICY "Users can manage own profile" ON public.users
    FOR ALL USING (auth.uid() = id);

-- Events表策略
CREATE POLICY "Users can manage own events" ON events
    FOR ALL USING (auth.uid() = user_id);

-- 用户设备表权限
CREATE POLICY "Users can manage own devices" ON user_devices
    FOR ALL USING (auth.uid() = user_id);

-- 推送记录权限
CREATE POLICY "Users can view own push records" ON push_notifications
    FOR SELECT USING (auth.uid() = user_id);

-- Service role可以插入推送记录（Edge Function需要）
CREATE POLICY "Service role can manage push records" ON push_notifications
    FOR ALL USING (auth.role() = 'service_role');

-- 模板表策略（公开可读）
CREATE POLICY "Templates are publicly readable" ON push_templates
    FOR SELECT USING (true);

-- 8. 创建更新时间触发器函数
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 删除现有触发器
DROP TRIGGER IF EXISTS update_users_updated_at ON public.users;
DROP TRIGGER IF EXISTS update_events_updated_at ON events;
DROP TRIGGER IF EXISTS update_user_devices_updated_at ON user_devices;

-- 添加更新触发器
CREATE TRIGGER update_users_updated_at 
    BEFORE UPDATE ON public.users 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_events_updated_at 
    BEFORE UPDATE ON events 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_devices_updated_at 
    BEFORE UPDATE ON user_devices 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 9. 插入推送文案模板
INSERT INTO push_templates (type, sarcasm_level, template) VALUES
-- 1天前推送文案
('day_before', 0, '明天有「{title}」哦，记得准时参加～'),
('day_before', 1, '明天你有『{title}』，别忘了哦！'),
('day_before', 2, '明天『{title}』，早点睡别赖我叫不醒你'),
('day_before', 3, '明天『{title}』，做好心理准备，别又临时找借口'),

-- 1周前推送文案  
('week_before', 0, '一周后是「{title}」，提前准备一下吧'),
('week_before', 1, '7天后『{title}』，现在开始准备还来得及'),
('week_before', 2, '一周后『{title}』，先洗洗衣服别到时候乱穿'),
('week_before', 3, '7天后『{title}』，赶紧准备吧，免得又手忙脚乱');

-- 10. 创建视图方便查询
CREATE OR REPLACE VIEW user_push_settings AS
SELECT 
    u.id as user_id,
    u.email,
    COALESCE(pu.sarcasm_level, 1) as sarcasm_level,
    COALESCE(pu.timezone, 'Asia/Shanghai') as timezone,
    COALESCE(pu.default_push_day_before, true) as default_push_day_before,
    COALESCE(pu.default_push_week_before, false) as default_push_week_before,
    array_agg(ud.device_token) FILTER (WHERE ud.is_active = true) as active_device_tokens,
    count(ud.device_token) FILTER (WHERE ud.is_active = true) as active_device_count
FROM auth.users u
LEFT JOIN public.users pu ON u.id = pu.id
LEFT JOIN user_devices ud ON u.id = ud.user_id
GROUP BY u.id, u.email, pu.sarcasm_level, pu.timezone, pu.default_push_day_before, pu.default_push_week_before;

-- 11. 创建用户注册时自动创建profile的函数
CREATE OR REPLACE FUNCTION handle_new_user() 
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.users (id, email)
    VALUES (NEW.id, NEW.email);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 删除现有触发器
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- 创建触发器：用户注册时自动创建profile
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- 12. 添加注释
COMMENT ON TABLE public.users IS 'HiCalendar用户扩展信息表';
COMMENT ON TABLE events IS 'HiCalendar事件表';
COMMENT ON TABLE user_devices IS '用户设备表 - 存储APNs device tokens';
COMMENT ON TABLE push_notifications IS '推送通知记录表 - 记录所有发送的推送通知';
COMMENT ON TABLE push_templates IS '推送文案模板表 - 根据吐槽等级提供不同文案';
COMMENT ON VIEW user_push_settings IS '用户推送设置视图 - 聚合用户推送相关信息';

-- 执行完成
SELECT 'HiCalendar 完整数据库结构创建完成！' as status,
       '已创建: users, events, user_devices, push_notifications, push_templates' as tables_created,
       '已添加: RLS策略, 索引, 触发器, 视图' as features_added;