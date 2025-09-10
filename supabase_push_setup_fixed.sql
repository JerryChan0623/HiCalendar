-- HiCalendar 推送通知数据库表结构（修复版）
-- 在Supabase SQL编辑器中执行

-- 1. 用户设备表（存储APNs device tokens）
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

-- 2. 扩展现有events表，添加推送相关字段
-- 先检查列是否存在，避免重复添加
DO $$ 
BEGIN 
    -- 添加push_day_before列
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name='events' AND column_name='push_day_before'
    ) THEN
        ALTER TABLE events ADD COLUMN push_day_before BOOLEAN DEFAULT true;
    END IF;
    
    -- 添加push_week_before列
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name='events' AND column_name='push_week_before'
    ) THEN
        ALTER TABLE events ADD COLUMN push_week_before BOOLEAN DEFAULT false;
    END IF;
    
    -- 添加push_status列
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name='events' AND column_name='push_status'
    ) THEN
        ALTER TABLE events ADD COLUMN push_status JSONB DEFAULT '{}';
    END IF;
END $$;

-- 3. 推送通知记录表（用于统计和调试）
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

-- 4. 扩展用户表，添加推送偏好
DO $$ 
BEGIN 
    -- 添加sarcasm_level列
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name='users' AND column_name='sarcasm_level'
    ) THEN
        ALTER TABLE users ADD COLUMN sarcasm_level INT2 DEFAULT 1 CHECK (sarcasm_level >= 0 AND sarcasm_level <= 3);
    END IF;
    
    -- 添加default_push_day_before列
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name='users' AND column_name='default_push_day_before'
    ) THEN
        ALTER TABLE users ADD COLUMN default_push_day_before BOOLEAN DEFAULT true;
    END IF;
    
    -- 添加default_push_week_before列
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name='users' AND column_name='default_push_week_before'
    ) THEN
        ALTER TABLE users ADD COLUMN default_push_week_before BOOLEAN DEFAULT false;
    END IF;
END $$;

-- 5. 创建索引优化查询性能
DROP INDEX IF EXISTS idx_user_devices_user_id;
CREATE INDEX idx_user_devices_user_id ON user_devices(user_id);

DROP INDEX IF EXISTS idx_user_devices_active;
CREATE INDEX idx_user_devices_active ON user_devices(is_active);

DROP INDEX IF EXISTS idx_events_start_at;
CREATE INDEX idx_events_start_at ON events(start_at);

DROP INDEX IF EXISTS idx_events_push_status;
CREATE INDEX idx_events_push_status ON events USING gin(push_status);

DROP INDEX IF EXISTS idx_push_notifications_sent_at;
CREATE INDEX idx_push_notifications_sent_at ON push_notifications(sent_at);

-- 6. 设置行级安全策略 (RLS)
ALTER TABLE user_devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE push_notifications ENABLE ROW LEVEL SECURITY;

-- 删除现有策略（如果存在）
DROP POLICY IF EXISTS "Users can manage own devices" ON user_devices;
DROP POLICY IF EXISTS "Users can view own push records" ON push_notifications;
DROP POLICY IF EXISTS "Service role can manage push records" ON push_notifications;

-- 用户设备表权限
CREATE POLICY "Users can manage own devices" ON user_devices
    FOR ALL USING (auth.uid() = user_id);

-- 推送记录权限
CREATE POLICY "Users can view own push records" ON push_notifications
    FOR SELECT USING (auth.uid() = user_id);

-- Service role可以插入推送记录（Edge Function需要）
CREATE POLICY "Service role can manage push records" ON push_notifications
    FOR ALL USING (auth.role() = 'service_role');

-- 7. 创建更新时间触发器函数
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 删除现有触发器（如果存在）
DROP TRIGGER IF EXISTS update_user_devices_updated_at ON user_devices;

-- 为user_devices表添加更新触发器
CREATE TRIGGER update_user_devices_updated_at 
    BEFORE UPDATE ON user_devices 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 8. 推送文案模板表
DROP TABLE IF EXISTS push_templates CASCADE;
CREATE TABLE push_templates (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    type TEXT CHECK (type IN ('day_before', 'week_before')),
    sarcasm_level INT2 CHECK (sarcasm_level >= 0 AND sarcasm_level <= 3),
    template TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 插入推送文案模板
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

-- RLS for templates
ALTER TABLE push_templates ENABLE ROW LEVEL SECURITY;

-- 删除现有策略
DROP POLICY IF EXISTS "Templates are publicly readable" ON push_templates;

-- 创建模板表策略
CREATE POLICY "Templates are publicly readable" ON push_templates
    FOR SELECT USING (true);

-- 9. 创建视图方便查询
CREATE OR REPLACE VIEW user_push_settings AS
SELECT 
    u.id as user_id,
    u.email,
    COALESCE(u.sarcasm_level, 1) as sarcasm_level,
    COALESCE(u.timezone, 'Asia/Shanghai') as timezone,
    COALESCE(u.default_push_day_before, true) as default_push_day_before,
    COALESCE(u.default_push_week_before, false) as default_push_week_before,
    array_agg(ud.device_token) FILTER (WHERE ud.is_active = true) as active_device_tokens,
    count(ud.device_token) FILTER (WHERE ud.is_active = true) as active_device_count
FROM auth.users u
LEFT JOIN user_devices ud ON u.id = ud.user_id
GROUP BY u.id, u.email, u.sarcasm_level, u.timezone, u.default_push_day_before, u.default_push_week_before;

-- 添加注释
COMMENT ON TABLE user_devices IS '用户设备表 - 存储APNs device tokens';
COMMENT ON TABLE push_notifications IS '推送通知记录表 - 记录所有发送的推送通知';
COMMENT ON TABLE push_templates IS '推送文案模板表 - 根据吐槽等级提供不同文案';
COMMENT ON VIEW user_push_settings IS '用户推送设置视图 - 聚合用户推送相关信息';

-- 执行完成
SELECT 'HiCalendar 推送通知数据库结构创建完成！' as status,
       'user_devices, push_notifications, push_templates 表已创建' as tables_created,
       '推送相关字段已添加到 events 和 users 表' as columns_added;