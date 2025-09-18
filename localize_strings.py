#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
多语言本地化批量替换脚本
自动替换Swift代码中的中文字符串为本地化调用
"""

import os
import re
import sys

# 本地化字符串映射（中文 -> L10n调用）
LOCALIZATION_MAP = {
    # 基础UI
    '"设置"': 'L10n.settings',
    '"返回"': 'L10n.back',
    '"完成"': 'L10n.done',
    '"取消"': 'L10n.cancel',
    '"确定"': 'L10n.ok',
    '"保存"': 'L10n.save',
    '"删除"': 'L10n.delete',

    # Tab导航
    '"看日子"': 'L10n.calendarTab',
    '"全部安排"': 'L10n.everythingTab',
    '"AI助手"': 'L10n.aiAssistant',

    # 设置页面
    '"看看是谁在这儿 👀"': 'L10n.whoIsHere',
    '"就是你啦～"': 'L10n.itsYou',
    '"给日历换个皮肤 🎨"': 'L10n.changeCalendarSkin',
    '"现在的装扮"': 'L10n.currentLook',
    '"还没换装呢，素颜也挺好 ✨"': 'L10n.noBackgroundYet',
    '"朴素美也是美"': 'L10n.simpleBeauty',
    '"不要这张了啦"': 'L10n.dontWantThis',
    '"我再想想"': 'L10n.iThinkAgain',
    '"不要了！"': 'L10n.dontWantIt',
    '"要走了吗？"': 'L10n.leavingAlready',
    '"真的要走了吗？下次记得回来哦 👋"': 'L10n.reallyLeaving',
    '"拜拜～"': 'L10n.seeYouLater',
    '"溜了溜了 👋"': 'L10n.seeYouLater',

    # 背景设置
    '"选择背景图片"': 'L10n.chooseBackground',
    '"更换背景图片"': 'L10n.updateBackground',
    '"挑张好看的图，让日历也美美哒～记得选清晰的哦，不然字都看不清就尴尬了 😅"': 'L10n.backgroundTip',

    # 登录
    '"快来登录呀 🎪"': 'L10n.pleaseLogin',
    '"登录了就能在云端备份，妈妈再也不怕我丢数据了 ☁️"': 'L10n.loginBenefits',

    # 推送通知
    '"通知提醒设置 🔔"': 'L10n.notificationSettings',
    '"推送通知未开启"': 'L10n.pushNotEnabled',
    '"开启通知后可以在事件前收到贴心（嘴贱）提醒哦～"': 'L10n.enablePushTip',
    '"开启推送通知"': 'L10n.enablePush',
    '"事件前1天提醒"': 'L10n.dayBeforeReminder',
    '"默认开启，提前一天叫醒你"': 'L10n.dayBeforeDesc',
    '"事件前1周提醒"': 'L10n.weekBeforeReminder',
    '"提前一周开始准备，从容不迫"': 'L10n.weekBeforeDesc',

    # 会员功能
    '"升级 HiCalendar 会员"': 'L10n.upgradeHiCalendarPro',
    '"HiCalendar 会员"': 'L10n.hiCalendarMember',
    '"解锁：云同步 · 小组件 · 智能推送"': 'L10n.unlockFeatures',
    '"已解锁：云同步 · 小组件 · 智能推送"': 'L10n.alreadyUnlocked',
    '"云端同步"': 'L10n.cloudSync',
    '"桌面小组件"': 'L10n.desktopWidgets',
    '"智能推送"': 'L10n.smartPush',
    '"立即升级"': 'L10n.upgradeNow',
    '"恢复购买"': 'L10n.restorePurchase',
    '"已解锁 Pro 功能"': 'L10n.alreadyUnlockedPro',
    '"解锁 Pro 功能"': 'L10n.unlockProFeatures',
    '"购买中..."': 'L10n.purchasing',
    '"一次购买，终身使用"': 'L10n.lifetimeAccess',

    # 法律信息
    '"法律信息"': 'L10n.legalInfo',
    '"用户协议"': 'L10n.termsOfService',
    '"隐私政策"': 'L10n.privacyPolicy',
    '"和"': 'L10n.and',
    '"登录即表示您同意我们的"': 'L10n.loginAgreement',

    # 登录好处
    '"登录后解锁更多设置"': 'L10n.unlockMoreSettings',
    '"个性化背景设置"': 'L10n.personalizedBackground',
    '"成为会员解锁云端功能"': 'L10n.becomeMemberUnlock',

    # 通用状态
    '"加载中..."': 'L10n.loading',
    '"同步中..."': 'L10n.syncing',
    '"暂无事件"': 'L10n.noEvents',
    '"今天"': 'L10n.today',
    '"明天"': 'L10n.tomorrow',
    '"昨天"': 'L10n.yesterday',
}

def replace_strings_in_file(file_path):
    """替换文件中的字符串"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()

        original_content = content
        replacements_made = 0

        # 替换字符串
        for chinese_str, localized_str in LOCALIZATION_MAP.items():
            if chinese_str in content:
                content = content.replace(chinese_str, localized_str)
                replacements_made += 1
                print(f"  ✓ Replaced: {chinese_str} -> {localized_str}")

        # 处理带参数的本地化字符串
        # 例如：String(format: "登录错误: %@", error) -> L10n.loginError(error)

        # 如果有更改，写回文件
        if content != original_content:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"✅ Updated {file_path} with {replacements_made} replacements")
            return True
        else:
            print(f"⚪ No changes needed for {file_path}")
            return False

    except Exception as e:
        print(f"❌ Error processing {file_path}: {e}")
        return False

def process_swift_files(directory):
    """处理目录下的所有Swift文件"""
    total_files = 0
    updated_files = 0

    for root, dirs, files in os.walk(directory):
        # 跳过一些不需要本地化的目录
        dirs[:] = [d for d in dirs if not d.endswith('.lproj') and
                   d not in ['HiCalendarTests', 'HiCalendarUITests']]

        for file in files:
            if file.endswith('.swift'):
                file_path = os.path.join(root, file)
                print(f"\n📁 Processing: {file_path}")
                total_files += 1

                if replace_strings_in_file(file_path):
                    updated_files += 1

    print(f"\n🎉 Processing complete!")
    print(f"📊 Total Swift files processed: {total_files}")
    print(f"✨ Files updated: {updated_files}")

if __name__ == "__main__":
    project_dir = "/Users/jerry/Documents/Xcode Pro/HiCalendar/HiCalendar"

    if not os.path.exists(project_dir):
        print(f"❌ Project directory not found: {project_dir}")
        sys.exit(1)

    print("🚀 Starting localization replacement...")
    print(f"📂 Target directory: {project_dir}")

    process_swift_files(project_dir)