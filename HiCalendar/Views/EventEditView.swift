//
//  EventEditView.swift
//  HiCalendar
//
//  Created on 2024. Neobrutalism Event Editor
//

import SwiftUI
import UserNotifications

struct EventEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var storageManager = EventStorageManager.shared
    
    // 编辑模式：创建新事项 或 编辑现有事项
    let editMode: EditMode
    let initialDate: Date
    let onSave: (() -> Void)?  // 保存完成回调
    
    // 事项数据
    @State private var title: String = ""
    @State private var eventDate: Date = Date()  // 事项日期
    @State private var eventTime: Date = Date()  // 事项时间
    @State private var details: String = ""
    @State private var hasTime: Bool = false
    @State private var pushReminders: [PushReminderOption] = [.dayBefore] // 推送提醒设置
    
    // 周期性重复设置
    @State private var recurrenceType: RecurrenceType = .none
    @State private var recurrenceCount: Int? = nil
    @State private var recurrenceStartDate: Date = Date()  // 重复开始日期
    @State private var recurrenceEndDate: Date? = nil  // 重复结束日期，默认为nil表示不设置
    
    // 自动保存状态
    @State private var hasUnsavedChanges: Bool = false
    @State private var saveTask: DispatchWorkItem? // 保存任务，用于取消重复调用
    @State private var hasSavedOnce: Bool = false // 标记是否已经保存过，防止重复创建
    
    // UI状态
    @State private var showingDeleteAlert = false
    @State private var isDatePickerExpanded = false
    @State private var isTimePickerExpanded = false
    @State private var isPushReminderExpanded = false
    @State private var isRecurrenceExpanded = false
    @State private var isRecurrenceStartDateExpanded = false
    @State private var isRecurrenceEndDateExpanded = false
    @FocusState private var isTitleFocused: Bool
    
    // 计算属性：是否为重复事件
    private var isRecurringEvent: Bool {
        if case .edit(let event) = editMode {
            return event.recurrenceGroupId != nil
        }
        return recurrenceType != .none
    }
    
    enum EditMode {
        case create
        case edit(Event)
        
        var navigationTitle: String {
            switch self {
            case .create: return "又有新安排啦 📝"
            case .edit: return "改改这个安排"
            }
        }
        
        var saveButtonTitle: String {
            switch self {
            case .create: return "创建"
            case .edit: return "保存"
            }
        }
    }
    
    init(mode: EditMode, initialDate: Date = Date(), onSave: (() -> Void)? = nil) {
        self.editMode = mode
        self.initialDate = initialDate
        self.onSave = onSave
        
        // 初始化状态
        let calendar = Calendar.current
        let defaultTime = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
        
        self._eventTime = State(initialValue: defaultTime)
        self._recurrenceStartDate = State(initialValue: initialDate)
        
        switch mode {
        case .create:
            // 创建模式：使用传入的初始日期
            self._eventDate = State(initialValue: initialDate)
            self._hasTime = State(initialValue: false)
            
        case .edit(let event):
            self._title = State(initialValue: event.title)
            self._details = State(initialValue: event.details ?? "")
            self._hasTime = State(initialValue: event.startAt != nil)
            self._pushReminders = State(initialValue: event.pushReminders)
            self._recurrenceType = State(initialValue: event.recurrenceType)
            self._recurrenceCount = State(initialValue: event.recurrenceCount)
            self._recurrenceEndDate = State(initialValue: event.recurrenceEndDate)
            
            // 编辑模式：优先使用事项自身的日期信息
            if let eventStartAt = event.startAt {
                // 有具体时间的事项：提取日期和时间部分
                self._eventDate = State(initialValue: calendar.startOfDay(for: eventStartAt))
                
                // 提取时间部分
                let hour = calendar.component(.hour, from: eventStartAt)
                let minute = calendar.component(.minute, from: eventStartAt)
                let extractedTime = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? defaultTime
                self._eventTime = State(initialValue: extractedTime)
            } else if let intendedDate = event.intendedDate {
                // 无时间事项但有归属日期：使用归属日期
                self._eventDate = State(initialValue: calendar.startOfDay(for: intendedDate))
            } else {
                // 既没有startAt也没有intendedDate：使用创建日期（向后兼容）
                self._eventDate = State(initialValue: calendar.startOfDay(for: event.createdAt))
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: BrandSpacing.xl) {
                    // 重复事件提示（仅编辑模式且为重复事件时显示）
                    if case .edit(let event) = editMode, event.recurrenceGroupId != nil {
                        recurringEventNotice
                    }
                    
                    // 标题输入
                    titleSection
                    
                    // 日期设置
                    dateSection
                    
                    // 时间设置
                    timeSection
                    
                    // 推送提醒设置
                    pushReminderSection
                    
                    // 周期性重复设置
                    recurrenceSection
                    
                    // 详情输入
                    detailsSection
                }
                .padding(BrandSpacing.lg)
            }
            .background(BrandColor.background.ignoresSafeArea())
            .navigationTitle(editMode.navigationTitle)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                // 左边：删除按钮（仅编辑模式）
                if case .edit = editMode {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            showingDeleteAlert = true
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(BrandColor.danger)
                        }
                    }
                }
                
                // 右边：完成按钮
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isRecurringEvent ? "同步保存" : "搞定！") {
                        // 取消待执行的保存任务
                        saveTask?.cancel()
                        
                        // 立即保存最终状态
                        if hasUnsavedChanges {
                            saveEvent()
                        }
                        
                        // 如果有自定义回调，使用回调，否则使用默认的dismiss
                        if let onSave = onSave {
                            onSave()
                        } else {
                            dismiss()
                        }
                    }
                    .font(BrandFont.body(size: 16, weight: .bold))
                    .foregroundColor(BrandColor.primaryBlue)
                }
            }
        }
        .onAppear {
            // 页面出现时的初始化逻辑
        }
        .overlay(
            // 使用自定义Neobrutalism Alert
            showingDeleteAlert ? 
            NeobrutalismAlert(
                title: isRecurringEvent ? "删除整个重复事件组" : "不干这事儿了",
                message: isRecurringEvent ? "这会删除该重复组中的所有事件，包括过去和未来的。确定要全部删除吗？" : "真的不干了？删了就真没了，后悔药可没地儿买 💊",
                isPresented: $showingDeleteAlert
            ) {
                HStack(spacing: BrandSpacing.lg) {
                    Button("取消") {
                        showingDeleteAlert = false
                    }
                    .buttonStyle(MD3ButtonStyle(type: .text))
                    
                    Button(isRecurringEvent ? "全部删除" : "删掉删掉") {
                        deleteEvent()
                    }
                    .buttonStyle(MD3ButtonStyle(type: .filled))
                }
            } : nil
        )
    }
    
    // MARK: - 重复事件提示区域
    private var recurringEventNotice: some View {
        MD3Card(type: .outlined) {
            HStack(spacing: BrandSpacing.md) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(BrandColor.primaryYellow)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("重复事件同步修改")
                        .font(BrandFont.body(size: 16, weight: .bold))
                        .foregroundColor(BrandColor.onSurface)
                    
                    Text("修改此事件会同时更新该重复组中的所有其他事件")
                        .font(BrandFont.body(size: 14, weight: .regular))
                        .foregroundColor(BrandColor.onSurface.opacity(0.7))
                }
                
                Spacer()
            }
            .padding(BrandSpacing.md)
        }
        .background(
            RoundedRectangle(cornerRadius: BrandRadius.md)
                .fill(BrandColor.primaryYellow.opacity(0.05))
        )
    }
    
    // MARK: - 标题输入区域
    private var titleSection: some View {
        MD3Card(type: .elevated) {
            VStack(alignment: .leading, spacing: BrandSpacing.md) {
                HStack {
                    Text("这事儿叫啥？")
                        .font(BrandFont.body(size: 16, weight: .bold))
                        .foregroundColor(BrandColor.onSurface)
                    
                    Spacer()
                    
                    Text("*")
                        .font(BrandFont.body(size: 16, weight: .bold))
                        .foregroundColor(BrandColor.danger)
                }
                
                TextField("比如：摸鱼大会 🐟", text: $title)
                    .font(BrandFont.body(size: 16, weight: .medium))
                    .padding(.horizontal, BrandSpacing.lg)
                    .frame(height: BrandSize.inputHeight)
                    .background(BrandColor.surface)
                    .neobrutalStyle(cornerRadius: BrandRadius.sm,
                                   borderWidth: BrandBorder.regular)
                    .focused($isTitleFocused)
                    .onChange(of: title) { _, _ in
                        autoSave()
                    }
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            Button("收起") {
                                isTitleFocused = false
                            }
                            .foregroundColor(BrandColor.primaryBlue)
                        }
                    }
            }
        }
    }
    
    // MARK: - 日期设置区域
    private var dateSection: some View {
        MD3Card(type: .elevated) {
            VStack(alignment: .leading, spacing: BrandSpacing.md) {
                // 可点击的日期显示区域
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isDatePickerExpanded.toggle()
                    }
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("哪天的事儿？")
                                .font(BrandFont.body(size: 16, weight: .bold))
                                .foregroundColor(BrandColor.onSurface)
                            Text(eventDate.formatted(.dateTime.year().month().day().weekday(.wide)))
                                .font(BrandFont.body(size: 14, weight: .medium))
                                .foregroundColor(BrandColor.onSurface.opacity(0.8))
                        }
                        
                        Spacer()
                        
                        Image(systemName: isDatePickerExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(BrandColor.outline)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                // 展开的日期选择器
                if isDatePickerExpanded {
                    DatePicker("", selection: $eventDate, displayedComponents: [.date])
                        .datePickerStyle(.graphical)
                        .onChange(of: eventDate) { _, newValue in
                            // 同步更新重复开始日期
                            recurrenceStartDate = newValue
                            autoSave()
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
    }
    
    // MARK: - 时间设置区域
    private var timeSection: some View {
        MD3Card(type: .elevated) {
            VStack(alignment: .leading, spacing: BrandSpacing.md) {
                // 时间设置头部区域
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("几点开搞？")
                            .font(BrandFont.body(size: 16, weight: .bold))
                            .foregroundColor(BrandColor.onSurface)
                        if hasTime {
                            Text(eventTime.formatted(.dateTime.hour().minute()))
                                .font(BrandFont.body(size: 14, weight: .medium))
                                .foregroundColor(BrandColor.onSurface.opacity(0.8))
                        } else {
                            Text("一整天都是这事儿")
                                .font(BrandFont.body(size: 14, weight: .medium))
                                .foregroundColor(BrandColor.outline)
                        }
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $hasTime)
                        .labelsHidden()
                        .tint(BrandColor.primaryYellow)
                        .onChange(of: hasTime) { _, _ in
                            autoSave()
                        }
                }
                
                // 可点击的时间展开区域
                if hasTime {
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isTimePickerExpanded.toggle()
                        }
                    }) {
                        HStack {
                            Text("改个时间")
                                .font(BrandFont.body(size: 14, weight: .medium))
                                .foregroundColor(BrandColor.primaryBlue)
                            
                            Spacer()
                            
                            Image(systemName: isTimePickerExpanded ? "chevron.up" : "chevron.down")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(BrandColor.primaryBlue)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.top, BrandSpacing.sm)
                    
                    // 展开的时间选择器
                    if isTimePickerExpanded {
                        DatePicker("", selection: $eventTime, displayedComponents: [.hourAndMinute])
                            .datePickerStyle(.wheel)
                            .onChange(of: eventTime) { _, _ in
                                autoSave()
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }
        }
    }
    
    // MARK: - 详情输入区域
    private var detailsSection: some View {
        MD3Card(type: .elevated) {
            VStack(alignment: .leading, spacing: BrandSpacing.md) {
                Text("还有啥要补充的？")
                    .font(BrandFont.body(size: 16, weight: .bold))
                    .foregroundColor(BrandColor.onSurface)
                
                ZStack(alignment: .topLeading) {
                    // 背景
                    RoundedRectangle(cornerRadius: BrandRadius.sm)
                        .fill(BrandColor.surface)
                        .neobrutalStyle(cornerRadius: BrandRadius.sm,
                                       borderWidth: BrandBorder.regular)
                        .frame(minHeight: 120)
                    
                    // 占位文字
                    if details.isEmpty {
                        Text("在哪儿？带啥？穿啥？都可以写这儿～")
                            .font(BrandFont.body(size: 16, weight: .regular))
                            .foregroundColor(BrandColor.outline)
                            .padding(.horizontal, BrandSpacing.lg)
                            .padding(.vertical, BrandSpacing.md)
                    }
                    
                    // 文本编辑器
                    TextEditor(text: $details)
                        .font(BrandFont.body(size: 16, weight: .medium))
                        .padding(.horizontal, BrandSpacing.md)
                        .padding(.vertical, BrandSpacing.sm)
                        .background(Color.clear)
                        .scrollContentBackground(.hidden)
                        .onChange(of: details) { _, _ in
                            autoSave()
                        }
                }
            }
        }
    }
    
    // MARK: - 推送提醒设置区域
    private var pushReminderSection: some View {
        MD3Card(type: .elevated) {
            VStack(alignment: .leading, spacing: BrandSpacing.md) {
                // 推送提醒头部
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isPushReminderExpanded.toggle()
                    }
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("啥时候提醒你？")
                                .font(BrandFont.body(size: 16, weight: .bold))
                                .foregroundColor(BrandColor.onSurface)
                            
                            if pushReminders.isEmpty {
                                Text("不提醒 🔕")
                                    .font(BrandFont.body(size: 14, weight: .medium))
                                    .foregroundColor(BrandColor.outline)
                            } else {
                                Text(pushReminders.map { "\($0.emoji) \($0.displayName)" }.joined(separator: "、"))
                                    .font(BrandFont.body(size: 14, weight: .medium))
                                    .foregroundColor(BrandColor.onSurface.opacity(0.8))
                            }
                        }
                        
                        Spacer()
                        
                        Image(systemName: isPushReminderExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(BrandColor.outline)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                // 展开的推送选项
                if isPushReminderExpanded {
                    VStack(spacing: BrandSpacing.sm) {
                        ForEach(PushReminderOption.allCases, id: \.self) { option in
                            pushReminderOptionRow(option)
                        }
                    }
                    .padding(.top, BrandSpacing.sm)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
    }
    
    // 单个推送选项行
    private func pushReminderOptionRow(_ option: PushReminderOption) -> some View {
        Button(action: {
            toggleReminderOption(option)
            autoSave()
        }) {
            HStack {
                Text(option.emoji)
                    .font(.system(size: 18))
                
                Text(option.displayName)
                    .font(BrandFont.body(size: 15, weight: .medium))
                    .foregroundColor(BrandColor.onSurface)
                
                Spacer()
                
                Image(systemName: pushReminders.contains(option) ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(pushReminders.contains(option) ? BrandColor.primaryBlue : BrandColor.outline)
            }
            .padding(.horizontal, BrandSpacing.md)
            .padding(.vertical, BrandSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: BrandRadius.sm)
                    .fill(pushReminders.contains(option) ? BrandColor.primaryBlue.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // 切换提醒选项
    private func toggleReminderOption(_ option: PushReminderOption) {
        if option == .none {
            // 如果选择"不提醒"，清空所有其他选项
            pushReminders = [.none]
        } else {
            // 移除"不提醒"选项（如果存在）
            pushReminders.removeAll { $0 == .none }
            
            if pushReminders.contains(option) {
                // 如果已选中，则取消选择
                pushReminders.removeAll { $0 == option }
                
                // 如果没有任何选项，默认设为"不提醒"
                if pushReminders.isEmpty {
                    pushReminders = [.none]
                }
            } else {
                // 添加新选项
                pushReminders.append(option)
            }
        }
    }
    
    // MARK: - 周期性重复设置区域
    private var recurrenceSection: some View {
        MD3Card(type: .elevated) {
            VStack(alignment: .leading, spacing: BrandSpacing.md) {
                // 周期性重复头部
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isRecurrenceExpanded.toggle()
                    }
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("重复频率")
                                .font(BrandFont.body(size: 16, weight: .bold))
                                .foregroundColor(BrandColor.onSurface)
                            
                            Text("\(recurrenceType.emoji) \(recurrenceType.displayName)")
                                .font(BrandFont.body(size: 14, weight: .medium))
                                .foregroundColor(BrandColor.onSurface.opacity(0.8))
                        }
                        
                        Spacer()
                        
                        Image(systemName: isRecurrenceExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(BrandColor.outline)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                // 展开的周期性选项
                if isRecurrenceExpanded {
                    VStack(spacing: BrandSpacing.sm) {
                        ForEach(RecurrenceType.allCases, id: \.self) { type in
                            recurrenceOptionRow(type)
                        }
                        
                        // 如果选择了重复，显示额外设置
                        if recurrenceType != .none {
                            Divider()
                                .background(BrandColor.outlineVariant)
                            
                            recurrenceSettingsView
                        }
                    }
                    .padding(.top, BrandSpacing.sm)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
    }
    
    // 单个重复选项行
    private func recurrenceOptionRow(_ type: RecurrenceType) -> some View {
        Button(action: {
            recurrenceType = type
            autoSave()
        }) {
            HStack {
                Text(type.emoji)
                    .font(.system(size: 18))
                
                Text(type.displayName)
                    .font(BrandFont.body(size: 15, weight: .medium))
                    .foregroundColor(BrandColor.onSurface)
                
                Spacer()
                
                Image(systemName: recurrenceType == type ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(recurrenceType == type ? BrandColor.primaryBlue : BrandColor.outline)
            }
            .padding(.horizontal, BrandSpacing.md)
            .padding(.vertical, BrandSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: BrandRadius.sm)
                    .fill(recurrenceType == type ? BrandColor.primaryBlue.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // 重复设置详细选项
    private var recurrenceSettingsView: some View {
        VStack(alignment: .leading, spacing: BrandSpacing.md) {
            Text("重复设置")
                .font(BrandFont.body(size: 14, weight: .bold))
                .foregroundColor(BrandColor.onSurface)
            
            // 开始日期设置
            VStack(alignment: .leading, spacing: BrandSpacing.sm) {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isRecurrenceStartDateExpanded.toggle()
                    }
                }) {
                    HStack {
                        Text("开始日期")
                            .font(BrandFont.body(size: 14, weight: .medium))
                            .foregroundColor(BrandColor.onSurface)
                        
                        Spacer()
                        
                        Text(recurrenceStartDate.formatted(.dateTime.year().month().day()))
                            .font(BrandFont.body(size: 14, weight: .medium))
                            .foregroundColor(BrandColor.primaryBlue)
                        
                        Image(systemName: isRecurrenceStartDateExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(BrandColor.outline)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                if isRecurrenceStartDateExpanded {
                    DatePicker("", selection: $recurrenceStartDate, displayedComponents: [.date])
                        .datePickerStyle(.graphical)
                        .onChange(of: recurrenceStartDate) { _, _ in
                            autoSave()
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            
            Divider()
                .background(BrandColor.outlineVariant)
            
            // 结束日期设置（可选）
            VStack(alignment: .leading, spacing: BrandSpacing.sm) {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isRecurrenceEndDateExpanded.toggle()
                    }
                }) {
                    HStack {
                        Text("结束日期")
                            .font(BrandFont.body(size: 14, weight: .medium))
                            .foregroundColor(BrandColor.onSurface)
                        
                        Spacer()
                        
                        if let endDate = recurrenceEndDate {
                            Text(endDate.formatted(.dateTime.year().month().day()))
                                .font(BrandFont.body(size: 14, weight: .medium))
                                .foregroundColor(BrandColor.primaryBlue)
                        } else {
                            Text("无限期")
                                .font(BrandFont.body(size: 14, weight: .medium))
                                .foregroundColor(BrandColor.outline)
                        }
                        
                        Image(systemName: isRecurrenceEndDateExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(BrandColor.outline)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                if isRecurrenceEndDateExpanded {
                    VStack(spacing: BrandSpacing.sm) {
                        // 切换按钮：有结束日期 vs 无限期
                        HStack {
                            Button(action: {
                                // 设置结束日期为开始日期后30天
                                let calendar = Calendar.current
                                recurrenceEndDate = calendar.date(byAdding: .day, value: 30, to: recurrenceStartDate)
                                autoSave()
                            }) {
                                Text("设置结束日期")
                                    .font(BrandFont.body(size: 14, weight: .medium))
                                    .foregroundColor(recurrenceEndDate != nil ? BrandColor.onSurface : BrandColor.primaryBlue)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                recurrenceEndDate = nil
                                autoSave()
                            }) {
                                Text("无限期")
                                    .font(BrandFont.body(size: 14, weight: .medium))
                                    .foregroundColor(recurrenceEndDate == nil ? BrandColor.primaryBlue : BrandColor.onSurface)
                            }
                        }
                        .padding(.horizontal, BrandSpacing.sm)
                        
                        // 如果有结束日期，显示日期选择器
                        if recurrenceEndDate != nil {
                            DatePicker("", selection: Binding(
                                get: { recurrenceEndDate ?? Date() },
                                set: { recurrenceEndDate = $0 }
                            ), in: recurrenceStartDate..., displayedComponents: [.date])
                                .datePickerStyle(.graphical)
                                .onChange(of: recurrenceEndDate ?? Date()) { _, _ in
                                    autoSave()
                                }
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            
            Divider()
                .background(BrandColor.outlineVariant)
            
            // 重复次数设置（与结束日期互斥）
            HStack {
                Text("重复次数")
                    .font(BrandFont.body(size: 14, weight: .medium))
                    .foregroundColor(BrandColor.onSurface)
                    .opacity(recurrenceEndDate != nil ? 0.5 : 1.0)
                
                Spacer()
                
                if recurrenceEndDate != nil {
                    Text("已设置结束日期")
                        .font(BrandFont.body(size: 12, weight: .medium))
                        .foregroundColor(BrandColor.outline)
                } else if recurrenceCount == nil {
                    Text("无限重复")
                        .font(BrandFont.body(size: 14, weight: .medium))
                        .foregroundColor(BrandColor.primaryBlue)
                } else {
                    HStack(spacing: BrandSpacing.sm) {
                        Button("-") {
                            if let count = recurrenceCount, count > 1 {
                                recurrenceCount = count - 1
                                autoSave()
                            }
                        }
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(BrandColor.surface))
                        .disabled((recurrenceCount ?? 30) <= 1)
                        
                        Text("\(recurrenceCount ?? 30)次")
                            .font(BrandFont.body(size: 14, weight: .medium))
                            .frame(minWidth: 40)
                        
                        Button("+") {
                            if recurrenceCount == nil {
                                recurrenceCount = 30  // 从无限变为30次
                            } else {
                                recurrenceCount = (recurrenceCount ?? 0) + 1
                            }
                            autoSave()
                        }
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(BrandColor.surface))
                        
                        Button("无限") {
                            recurrenceCount = nil
                            autoSave()
                        }
                        .font(BrandFont.body(size: 12, weight: .medium))
                        .foregroundColor(BrandColor.primaryBlue)
                    }
                }
            }
            .disabled(recurrenceEndDate != nil)
        }
        .padding(BrandSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: BrandRadius.sm)
                .fill(BrandColor.surface.opacity(0.5))
        )
    }
    
    
    // MARK: - 计算属性
    
    // MARK: - 周期性创建方法
    
    /// 创建重复事项 - 简化版本
    private func createRecurrenceEvents(title: String, startAt: Date?, endAt: Date?, details: String?, 
                                       pushReminders: [PushReminderOption], baseDate: Date) {
        print("📊 createRecurrenceEvents - recurrenceType: \(recurrenceType), recurrenceCount: \(recurrenceCount?.description ?? "nil")")
        print("📅 开始日期: \(recurrenceStartDate), 结束日期: \(recurrenceEndDate?.description ?? "无限期")")
        
        // 使用用户选择的开始日期，而不是baseDate
        let events = Event.generateRecurrenceGroup(
            title: title,
            baseDate: recurrenceStartDate,  // 使用用户选择的开始日期
            startAt: startAt,
            endAt: endAt,
            details: details,
            pushReminders: pushReminders,
            recurrenceType: recurrenceType,
            recurrenceCount: recurrenceEndDate != nil ? nil : recurrenceCount,  // 如果设置了结束日期，不使用重复次数
            recurrenceEndDate: recurrenceEndDate
        )
        
        // 批量添加所有事件
        storageManager.addEvents(events)
        
        print("✅ 批量创建\(events.count)个重复事项：\(recurrenceType.displayName)")
    }
    
    // MARK: - 操作方法
    
    /// 自动保存方法 - 当用户修改任何字段时触发
    private func autoSave() {
        // 创建模式下禁用自动保存，避免过早创建事件
        guard case .edit(_) = editMode else {
            print("🚫 创建模式下跳过自动保存")
            hasUnsavedChanges = true
            return
        }
        
        // 取消之前的保存任务
        saveTask?.cancel()
        
        // 防抖处理，避免频繁保存
        hasUnsavedChanges = true
        
        let newTask = DispatchWorkItem {
            if hasUnsavedChanges {
                saveEvent()
                hasUnsavedChanges = false
            }
        }
        
        saveTask = newTask
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: newTask)
    }
    
    private func saveEvent() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        
        // 如果设置了时间，将选择的时间与事项日期结合
        let eventStartDate: Date?
        let eventEndDate: Date?
        
        if hasTime {
            let calendar = Calendar.current
            
            // 从eventTime提取时间，与eventDate的日期结合
            let hour = calendar.component(.hour, from: eventTime)
            let minute = calendar.component(.minute, from: eventTime)
            eventStartDate = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: eventDate)
            
            // 结束时间设为开始时间的1小时后
            eventEndDate = eventStartDate?.addingTimeInterval(3600)
        } else {
            // 即使没有设置具体时间，也要设置为对应日期的开始时间，确保事项归属到正确的日期
            let calendar = Calendar.current
            eventStartDate = calendar.startOfDay(for: eventDate)
            eventEndDate = nil
        }
        
        let eventDetails = details.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : details.trimmingCharacters(in: .whitespacesAndNewlines)
        
        switch editMode {
        case .create:
            // 防止重复创建：只有第一次保存时才创建事项
            guard !hasSavedOnce else { return }
            hasSavedOnce = true
            
            // 如果设置了周期性重复，创建多个事项
            print("🔍 保存事项时检查重复类型：\(recurrenceType)")
            if recurrenceType != .none {
                print("✅ 重复类型不为none，调用createRecurrenceEvents")
                createRecurrenceEvents(
                    title: trimmedTitle,
                    startAt: eventStartDate,
                    endAt: eventEndDate,
                    details: eventDetails,
                    pushReminders: pushReminders,
                    baseDate: eventDate
                )
            } else {
                print("📝 重复类型为none，创建单个事项")
                // 单个事项创建
                let newEvent = Event(
                    title: trimmedTitle,
                    startAt: eventStartDate,
                    endAt: eventEndDate,
                    details: eventDetails,
                    pushReminders: pushReminders,
                    createdAt: Date(), // 使用当前时间作为创建时间
                    intendedDate: eventStartDate == nil ? eventDate : nil  // 只有无时间事项才设置intendedDate
                )
                storageManager.addEvent(newEvent)
                
                // 调度本地通知
                scheduleLocalNotifications(for: newEvent)
            }
            
        case .edit(let existingEvent):
            // 先取消旧的本地通知
            cancelLocalNotifications(for: existingEvent)
            
            var updatedEvent = existingEvent
            updatedEvent.title = trimmedTitle
            updatedEvent.startAt = eventStartDate
            updatedEvent.endAt = eventEndDate
            updatedEvent.details = eventDetails
            updatedEvent.pushReminders = pushReminders
            updatedEvent.recurrenceType = recurrenceType
            updatedEvent.recurrenceCount = recurrenceCount
            updatedEvent.recurrenceEndDate = recurrenceEndDate
            
            storageManager.updateEvent(updatedEvent)
            
            // 调度新的本地通知
            scheduleLocalNotifications(for: updatedEvent)
            // 自动保存更新事项
        }
    }
    
    private func deleteEvent() {
        // 取消待执行的保存任务
        saveTask?.cancel()
        
        if case .edit(let event) = editMode {
            // 取消本地通知
            cancelLocalNotifications(for: event)
            
            // 检查是否为重复事件
            if event.recurrenceGroupId != nil {
                // 删除整个重复事件组
                storageManager.deleteRecurrenceGroup(event)
                print("🗑️ 删除重复事件组：\(event.title)")
            } else {
                // 删除单个事件
                storageManager.deleteEvent(event)
                print("🗑️ 删除单个事件：\(event.title)")
            }
        }
        
        // 如果有自定义回调，使用回调，否则使用默认的dismiss
        if let onSave = onSave {
            onSave()
        } else {
            dismiss()
        }
    }
    
    // MARK: - 本地通知管理
    
    /// 为事项调度本地通知
    private func scheduleLocalNotifications(for event: Event) {
        // 全部提醒类型都使用本地通知
        let localReminderTypes: [PushReminderOption] = [.atTime, .minutes15, .minutes30, .hours1, .hours2, .dayBefore, .weekBefore]
        
        for reminder in event.pushReminders {
            if localReminderTypes.contains(reminder) {
                if let startDate = event.startAt {
                    // 有执行时间：基于执行时间调度
                    scheduleLocalNotification(for: event, reminderType: reminder, startDate: startDate)
                } else if reminder == .dayBefore || reminder == .weekBefore {
                    // 无执行时间：只支持1天前和1周前提醒，基于创建时间的次日
                    let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: event.createdAt) ?? event.createdAt
                    scheduleLocalNotification(for: event, reminderType: reminder, startDate: nextDay)
                }
                // 无执行时间时跳过其他类型的提醒（准点、15分钟前等）
            }
        }
    }
    
    /// 调度单个本地通知
    private func scheduleLocalNotification(for event: Event, reminderType: PushReminderOption, startDate: Date) {
        let content = UNMutableNotificationContent()
        content.title = "HiCalendar提醒"
        
        // 生成本地通知文案，区分有时间和无时间事项
        let hasTime = event.startAt != nil
        
        switch reminderType {
        case .atTime:
            content.body = hasTime ? "「\(event.title)」开始啦，别躺平了快起来！" : "「\(event.title)」提醒"
        case .minutes15:
            content.body = hasTime ? "还有15分钟「\(event.title)」就要开始了，准备好了没？" : "「\(event.title)」提醒"
        case .minutes30:
            content.body = hasTime ? "半小时后「\(event.title)」，现在准备还来得及" : "「\(event.title)」提醒"
        case .hours1:
            content.body = hasTime ? "一小时后「\(event.title)」，别到时候又说来不及" : "「\(event.title)」提醒"
        case .hours2:
            content.body = hasTime ? "两小时后「\(event.title)」，提前准备一下吧" : "「\(event.title)」提醒"
        case .dayBefore:
            content.body = hasTime ? "明天「\(event.title)」，别又临时找借口说忘了！" : "别忘了「\(event.title)」这事儿，拖了这么久该动手了吧？"
        case .weekBefore:
            content.body = hasTime ? "一周后「\(event.title)」，现在不准备待会儿又手忙脚乱？" : "下周记得「\(event.title)」，别到时候又说没时间！"
        default:
            content.body = "「\(event.title)」提醒"
        }
        
        content.badge = 1
        content.sound = .default
        content.userInfo = ["eventId": event.id.uuidString, "reminderType": reminderType.rawValue]
        
        // 计算通知时间
        let notificationDate = startDate.addingTimeInterval(reminderType.timeOffsetSeconds)
        
        // 只调度未来的通知
        guard notificationDate > Date() else {
            print("⚠️ 通知时间已过，跳过：\(reminderType.displayName)")
            return
        }
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: notificationDate),
            repeats: false
        )
        
        let identifier = "\(event.id.uuidString)_\(reminderType.rawValue)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ 本地通知调度失败：\(error)")
            } else {
                print("✅ 本地通知已调度：\(reminderType.displayName) - \(event.title)")
            }
        }
    }
    
    /// 取消事项的所有本地通知
    private func cancelLocalNotifications(for event: Event) {
        let identifiers = PushReminderOption.allCases.map { "\(event.id.uuidString)_\($0.rawValue)" }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        print("🚫 已取消事项的本地通知：\(event.title)")
    }
}

// MARK: - Preview
#Preview("创建新事项") {
    EventEditView(mode: .create, initialDate: Date())
}

#Preview("编辑现有事项") {
    EventEditView(mode: .edit(Event.sampleEvents.first!))
}
