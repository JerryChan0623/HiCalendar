# 数据下载同步实现方案

## 问题分析
当前只实现了本地→云端的上传同步，缺少云端→本地的下载同步。

## 需要实现的功能

### 1. SupabaseManager.fetchAllEvents() 真实实现
```swift
func fetchAllEvents() async -> [Event] {
    do {
        let authUser = try await client.auth.user
        guard let user = authUser else { return [] }

        let response: [EventRow] = try await client
            .from("events")
            .select("*")
            .eq("user_id", value: user.id.uuidString)
            .order("updated_at", ascending: false)
            .execute()
            .value

        return response.compactMap { convertToEvent($0) }
    } catch {
        print("❌ 获取云端事件失败: \(error)")
        return []
    }
}
```

### 2. 下载时的去重和冲突处理
```swift
private func downloadCloudDataToLocal() async -> Int {
    let cloudEvents = await supabaseManager.fetchAllEvents()
    var downloadCount = 0

    for cloudEvent in cloudEvents {
        let localEvent = eventManager.events.first { $0.id == cloudEvent.id }

        if localEvent == nil {
            // 新事件，直接添加
            eventManager.addEvent(cloudEvent)
            downloadCount += 1
        } else if cloudEvent.updatedAt > localEvent.updatedAt {
            // 云端更新，覆盖本地
            eventManager.updateEvent(cloudEvent)
            downloadCount += 1
        }
        // 否则保持本地版本
    }

    return downloadCount
}
```

### 3. 双向同步时序
```
1. 上传本地未同步的事件
2. 下载云端更新的事件
3. 解决冲突（以云端时间戳为准）
4. 标记同步完成
```

## 当前影响
- 新设备登录无法获取历史数据
- 多设备间数据不同步
- 云端备份无法恢复到本地

## 建议优先级
🔥 高优先级 - 会员功能的核心价值