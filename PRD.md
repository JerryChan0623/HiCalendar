

PRD：Cute Calendar AI – SwiftUI 可爱风日历 AI 助手

1. 产品定位

一句话就能创建/查询/修改日程，AI 自动检测冲突并用嘴贱人格提醒你。事件会在开始前 1 天 和 1 周通过推送通知提醒。整体 UI 采用 可爱风（Cute Style），让日历也有温度。

⸻

2. 核心功能

模块	功能点	说明
事件管理	自然语言创建事件	解析日期、时间、标题、地点，自动保存到日历
	检查时间冲突并提示	硬冲突/软冲突分类，给替代选项
	查询空闲时间	返回可用时间段
	修改事件	单个/重复事件修改
	删除事件	单个/批量删除
AI 吐槽	嘴贱人格输出	结论 + 吐槽 + 操作建议
	吐槽程度调节	温和/正常/重嘴贱
推送提醒	事件前 1 天推送（默认）	用户可关闭
	事件前 1 周推送（可选）	用户可开启
	推送文案个性化	按吐槽程度匹配模板
账号&设备	用户注册/登录（Supabase Auth）	邮箱 / Apple 登录
	设备 token 存储	用于 APNs 推送
日历视图	月 / 周 / 日视图切换	支持点击日期查看详情
	拖拽改期	触发冲突检测与二次确认


⸻

3. 页面与布局（SwiftUI 可爱风）

A. 登录 / 注册页

目标：账户创建、登录、设备 token 记录、推送权限获取
布局：
	•	顶部：Logo（可爱插画）+ 标语「先上车再说，行程我替你操心」
	•	中间：圆润输入框（邮箱/密码）+ 胶囊按钮（渐变背景）
	•	底部：Apple 登录按钮（圆角胶囊）
	•	首登后引导：插画弹窗请求推送权限

⸻

B. 首页（AI 对话）

目标：一句话操作日历，查看今日概况
布局：
	•	顶部：今日摘要卡片（背景渐变 + Emoji）
示例：「今天你有 2 个会 + 1 个摸鱼时段 🐣」
	•	中间：AI 输入框（文本 + 麦克风按钮）
	•	底部：最近三条事件卡片（颜色区分冲突状态）

⸻

C. 日历页

目标：传统方式查看和编辑日程
布局：
	•	顶部：月/周/日切换胶囊按钮
	•	主体：自定义日历（参考 SwiftUICalendar）
	•	月视图：当天高亮圆形背景，事件小圆点
	•	周视图：时间轴栅格，事件块可拖拽
	•	底部抽屉：当天事件卡片（渐变背景、圆角）

⸻

D. 事件详情页

目标：展示并管理单个事件
布局：
	•	渐变背景大卡片显示标题、时间、地点
	•	冲突状态条（红/黄/绿）
	•	推送设置开关（1天/1周）
	•	操作按钮（胶囊样式：「编辑」「删除」「改时间」）

⸻

E. 事件列表页

目标：快速浏览全部事件
布局：
	•	搜索框（圆角）
	•	日期分组列表（带冲突标识）
	•	筛选：今天 / 本周 / 本月

⸻

F. 设置页

目标：调整应用偏好
布局：
	•	用户信息（邮箱、登出按钮）
	•	吐槽程度 Slider（渐变轨道）
	•	推送全局开关（1天/1周）
	•	时区显示（自动获取，可手动修改）

⸻

4. UI 风格规范（Cute Style）
	•	色彩方案（马卡龙系）：
	•	主色：#FFB6C1（浅粉）、#A3D8F4（天蓝）
	•	辅色：#FFF6B7（奶油黄）、#C1E1C1（薄荷绿）
	•	背景：浅色渐变（粉→白、蓝→白）
	•	字体：
	•	标题：Google Fonts – Nunito / Baloo 2（圆润）
	•	正文：系统 .rounded
	•	按钮样式：
	•	胶囊形状（Capsule()）
	•	渐变背景 + 阴影
	•	卡片：
	•	圆角 16–24pt
	•	柔和阴影（opacity 0.1，radius 4）
	•	动效：
	•	弹跳动画（spring）
	•	页面切换淡入淡出

⸻

5. 数据结构（Supabase）

users

id uuid primary key
email text unique
timezone text default 'Asia/Tokyo'
sarcasm_level int2 default 1  -- 0-3
default_push_day_before boolean default true
default_push_week_before boolean default false
created_at timestamptz default now()

user_devices

id uuid primary key default gen_random_uuid()
user_id uuid references auth.users(id)
device_token text not null
platform text check (platform in ('ios'))
created_at timestamptz default now()

events

id uuid primary key
user_id uuid references auth.users(id)
title text
start_at timestamptz
end_at timestamptz
timezone text
location text
busy boolean default true
push_day_before boolean default true
push_week_before boolean default false
push_status jsonb default '{}' -- {"day_before": true, "week_before": false}
created_at timestamptz
updated_at timestamptz


⸻

6. 推送逻辑
	•	触发时机：
	•	事件开始前 1 天（默认）
	•	事件开始前 1 周（可选）
	•	服务：
	•	SwiftUI → APNs（苹果官方推送，免费）
	•	流程：
	1.	用户登录 → 获取 device_token → 存 Supabase
	2.	Edge Function 每天 0:05 检查符合条件的事件
	3.	生成推送文案（按吐槽程度选择模板）
	4.	调用 APNs API 发送
	5.	更新 push_status 防止重复发送

⸻

7. 嘴贱推送文案示例

前一天
	•	「明天你有『{title}』，早点睡，别赖我叫不醒你。」
	•	「还有 1 天，别找借口放鸽子 → {title}」

前一周
	•	「7 天后是『{title}』，先洗衣服别到时候乱穿。」
	•	「一周后，你会在『{title}』。做好心理准备吧。」

⸻

8. 验收标准
	•	登录注册成功率 ≥ 98%
	•	自然语言解析准确率 ≥ 90%
	•	冲突检测准确率 ≥ 90%
	•	推送触达率 ≥ 95%
	•	推送重复率 ≤ 1%

⸻

