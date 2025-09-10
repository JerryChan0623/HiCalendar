//
//  EverythingsView.swift
//  HiCalendar
//
//  Created on 2024. 所有事项倒计时视图
//

import SwiftUI

struct EverythingsView: View {
    @StateObject private var storageManager = EventStorageManager.shared
    @Environment(\.colorScheme) var colorScheme
    @State private var searchText = ""
    @State private var selectedEvent: Event?
    @State private var isExpiredExpanded = false // 已过期事项是否展开
    
    // 计算倒计时天数 - 修复版本，正确处理无时间事项
    private func daysUntil(event: Event) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // 确定事项的目标日期
        let targetDate: Date
        if let startAt = event.startAt {
            // 有执行时间：使用执行日期
            targetDate = calendar.startOfDay(for: startAt)
        } else if let intendedDate = event.intendedDate {
            // 无执行时间但有归属日期：使用归属日期
            targetDate = calendar.startOfDay(for: intendedDate)
        } else {
            // 都没有：使用创建日期（向后兼容）
            targetDate = calendar.startOfDay(for: event.createdAt)
        }
        
        let components = calendar.dateComponents([.day], from: today, to: targetDate)
        return components.day ?? 0
    }
    
    // 过滤和排序事件
    private var sortedEvents: [Event] {
        let events = storageManager.events
        
        // 搜索过滤
        let filteredEvents = searchText.isEmpty ? events : events.filter { event in
            event.title.localizedCaseInsensitiveContains(searchText) ||
            (event.details ?? "").localizedCaseInsensitiveContains(searchText)
        }
        
        // 按日期排序（从近到远）
        return filteredEvents.sorted(by: { event1, event2 in
            // 使用相同的日期获取逻辑确保一致性
            
            let date1: Date
            if let startAt = event1.startAt {
                date1 = startAt
            } else if let intendedDate = event1.intendedDate {
                date1 = intendedDate
            } else {
                date1 = event1.createdAt
            }
            
            let date2: Date
            if let startAt = event2.startAt {
                date2 = startAt
            } else if let intendedDate = event2.intendedDate {
                date2 = intendedDate
            } else {
                date2 = event2.createdAt
            }
            
            return date1 < date2
        })
    }
    
    // 将事件按状态分组
    private var groupedEvents: (urgent: [Event], upcoming: [Event], later: [Event], past: [Event]) {
        var urgent: [Event] = []
        var upcoming: [Event] = []
        var later: [Event] = []
        var past: [Event] = []
        
        for event in sortedEvents {
            let days = daysUntil(event: event)
            switch days {
            case ..<0:
                past.append(event)
            case 0...2:
                urgent.append(event)
            case 3...14:
                upcoming.append(event)
            default:
                later.append(event)
            }
        }
        
        return (urgent, upcoming, later, past)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                BrandColor.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // 搜索栏
                        searchBar
                            .padding(.horizontal, BrandSpacing.lg)
                            .padding(.top, BrandSpacing.md)
                            .padding(.bottom, BrandSpacing.lg)
                        
                        // 事件列表
                        VStack(spacing: BrandSpacing.xl) {
                            let groups = groupedEvents
                            
                            // 紧急事项
                            if !groups.urgent.isEmpty {
                                eventSection(
                                    title: "🔥 紧急事项",
                                    events: groups.urgent,
                                    titleColor: BrandColor.danger
                                )
                            }
                            
                            // 即将到来
                            if !groups.upcoming.isEmpty {
                                eventSection(
                                    title: "📅 即将到来",
                                    events: groups.upcoming,
                                    titleColor: BrandColor.warning
                                )
                            }
                            
                            // 稍后事项
                            if !groups.later.isEmpty {
                                eventSection(
                                    title: "📌 稍后事项",
                                    events: groups.later,
                                    titleColor: BrandColor.primaryBlue
                                )
                            }
                            
                            // 已过期（可折叠）
                            if !groups.past.isEmpty {
                                VStack(alignment: .leading, spacing: BrandSpacing.md) {
                                    // 可点击的标题栏
                                    Button(action: {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            isExpiredExpanded.toggle()
                                        }
                                    }) {
                                        HStack {
                                            Text("⏰ 过期啦 💀 (\(groups.past.count))")
                                                .font(BrandFont.body(size: 18, weight: .bold))
                                                .foregroundColor(BrandColor.neutral500)
                                            
                                            Spacer()
                                            
                                            Image(systemName: isExpiredExpanded ? "chevron.up" : "chevron.down")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(BrandColor.neutral500)
                                        }
                                        .padding(.horizontal, BrandSpacing.xs)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    // 展开时显示事件
                                    if isExpiredExpanded || !searchText.isEmpty {
                                        VStack(spacing: BrandSpacing.md) {
                                            ForEach(groups.past) { event in
                                                eventCard(event)
                                            }
                                        }
                                        .transition(.opacity.combined(with: .move(edge: .top)))
                                    }
                                }
                            }
                            
                            // 空状态
                            if sortedEvents.isEmpty {
                                emptyState
                            }
                        }
                        .padding(.horizontal, BrandSpacing.lg)
                        .padding(.bottom, BrandSpacing.xxl)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(item: $selectedEvent) { event in
            NavigationStack {
                EventEditView(mode: .edit(event), initialDate: event.startAt ?? Date())
            }
        }
    }
    
    // MARK: - 搜索栏
    private var searchBar: some View {
        HStack(spacing: BrandSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(BrandColor.neutral500)
                .font(.body)
            
            TextField("搜索事项...", text: $searchText)
                .font(BrandFont.bodyMedium)
                .foregroundColor(BrandColor.neutral900)
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(BrandColor.neutral500)
                        .font(.body)
                }
            }
        }
        .padding(.horizontal, BrandSpacing.md)
        .padding(.vertical, BrandSpacing.sm)
        .background(BrandColor.surface)
        .neobrutalStyle(cornerRadius: BrandRadius.md, borderWidth: BrandBorder.regular)
    }
    
    // MARK: - 事件分组
    private func eventSection(title: String, events: [Event], titleColor: Color) -> some View {
        VStack(alignment: .leading, spacing: BrandSpacing.md) {
            // 分组标题
            Text(title)
                .font(BrandFont.body(size: 18, weight: .bold))
                .foregroundColor(titleColor)
                .padding(.horizontal, BrandSpacing.xs)
            
            // 事件卡片
            VStack(spacing: BrandSpacing.md) {
                ForEach(events) { event in
                    eventCard(event)
                }
            }
        }
    }
    
    // MARK: - 事件卡片
    private func eventCard(_ event: Event) -> some View {
        EventDetailCard(
            event: event,
            onDelete: {
                // 删除事项功能
                storageManager.deleteEvent(event)
            },
            onEdit: {
                selectedEvent = event
            },
            showTimePrompt: true  // 在全部安排页面显示时间提示
        )
        .onTapGesture {
            selectedEvent = event
        }
    }
    
    // MARK: - 空状态
    private var emptyState: some View {
        VStack(spacing: BrandSpacing.lg) {
            if searchText.isEmpty {
                // 无事项时显示全部完成动画
                CuteAllCompletedView()
            } else {
                // 搜索无结果时显示无事件动画
                AnimatedEmptyStateView(
                    type: .noEvents,
                    message: "未找到匹配的事项，尝试其他搜索关键词",
                    size: 100
                )
            }
        }
        .padding(BrandSpacing.xxl)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    EverythingsView()
}