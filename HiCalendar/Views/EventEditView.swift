//
//  EventEditView.swift
//  HiCalendar
//
//  Created on 2024. Neobrutalism Event Editor
//

import SwiftUI

struct EventEditView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var storageManager = EventStorageManager.shared
    
    // 编辑模式：创建新事项 或 编辑现有事项
    let editMode: EditMode
    let initialDate: Date
    
    // 事项数据
    @State private var title: String = ""
    @State private var eventDate: Date = Date()  // 事项日期
    @State private var eventTime: Date = Date()  // 事项时间
    @State private var details: String = ""
    @State private var hasTime: Bool = false
    
    // 自动保存状态
    @State private var hasUnsavedChanges: Bool = false
    
    // UI状态
    @State private var showingDeleteAlert = false
    @State private var isDatePickerExpanded = false
    @State private var isTimePickerExpanded = false
    @FocusState private var isTitleFocused: Bool
    
    enum EditMode {
        case create
        case edit(Event)
        
        var navigationTitle: String {
            switch self {
            case .create: return "新建事项"
            case .edit: return "编辑事项"
            }
        }
        
        var saveButtonTitle: String {
            switch self {
            case .create: return "创建"
            case .edit: return "保存"
            }
        }
    }
    
    init(mode: EditMode, initialDate: Date = Date()) {
        self.editMode = mode
        self.initialDate = initialDate
        
        // 初始化状态
        let calendar = Calendar.current
        let defaultTime = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
        
        self._eventTime = State(initialValue: defaultTime)
        self._eventDate = State(initialValue: initialDate)
        
        switch mode {
        case .create:
            self._hasTime = State(initialValue: false)
            
        case .edit(let event):
            self._title = State(initialValue: event.title)
            self._details = State(initialValue: event.details ?? "")
            self._hasTime = State(initialValue: event.startAt != nil)
            
            // 如果事项有日期，提取日期部分
            if let eventStartAt = event.startAt {
                self._eventDate = State(initialValue: calendar.startOfDay(for: eventStartAt))
                
                // 提取时间部分
                let hour = calendar.component(.hour, from: eventStartAt)
                let minute = calendar.component(.minute, from: eventStartAt)
                let extractedTime = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? defaultTime
                self._eventTime = State(initialValue: extractedTime)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: BrandSpacing.xl) {
                    // 标题输入
                    titleSection
                    
                    // 日期设置
                    dateSection
                    
                    // 时间设置
                    timeSection
                    
                    // 详情输入
                    detailsSection
                }
                .padding(BrandSpacing.lg)
            }
            .background(Color.white.ignoresSafeArea())
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
                    Button("完成") {
                        dismiss()
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
                title: "删除事项",
                message: "确定要删除这个事项吗？此操作无法撤销。",
                isPresented: $showingDeleteAlert
            ) {
                HStack(spacing: BrandSpacing.lg) {
                    Button("取消") {
                        showingDeleteAlert = false
                    }
                    .buttonStyle(AlertButtonStyle(isDestructive: false))
                    
                    Button("删除") {
                        deleteEvent()
                    }
                    .buttonStyle(AlertButtonStyle(isDestructive: true))
                }
            } : nil
        )
    }
    
    // MARK: - 标题输入区域
    private var titleSection: some View {
        CuteCard(backgroundColor: BrandSolid.cardWhite) {
            VStack(alignment: .leading, spacing: BrandSpacing.md) {
                HStack {
                    Text("事项标题")
                        .font(BrandFont.body(size: 16, weight: .bold))
                        .foregroundColor(BrandColor.neutral900)
                    
                    Spacer()
                    
                    Text("*")
                        .font(BrandFont.body(size: 16, weight: .bold))
                        .foregroundColor(BrandColor.danger)
                }
                
                TextField("例如：团队会议", text: $title)
                    .font(BrandFont.body(size: 16, weight: .medium))
                    .padding(.horizontal, BrandSpacing.lg)
                    .frame(height: BrandSize.inputHeight)
                    .background(BrandColor.neutral100)
                    .neobrutalStyle(cornerRadius: BrandRadius.sm,
                                   borderWidth: BrandBorder.regular)
                    .focused($isTitleFocused)
                    .onChange(of: title) { _, _ in
                        autoSave()
                    }
            }
        }
    }
    
    // MARK: - 日期设置区域
    private var dateSection: some View {
        CuteCard(backgroundColor: BrandSolid.cardWhite) {
            VStack(alignment: .leading, spacing: BrandSpacing.md) {
                // 可点击的日期显示区域
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isDatePickerExpanded.toggle()
                    }
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("日期")
                                .font(BrandFont.body(size: 16, weight: .bold))
                                .foregroundColor(BrandColor.neutral900)
                            Text(eventDate.formatted(.dateTime.year().month().day().weekday(.wide)))
                                .font(BrandFont.body(size: 14, weight: .medium))
                                .foregroundColor(BrandColor.neutral700)
                        }
                        
                        Spacer()
                        
                        Image(systemName: isDatePickerExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(BrandColor.neutral500)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                // 展开的日期选择器
                if isDatePickerExpanded {
                    DatePicker("", selection: $eventDate, displayedComponents: [.date])
                        .datePickerStyle(.graphical)
                        .onChange(of: eventDate) { _, _ in
                            autoSave()
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
    }
    
    // MARK: - 时间设置区域
    private var timeSection: some View {
        CuteCard(backgroundColor: BrandSolid.cardWhite) {
            VStack(alignment: .leading, spacing: BrandSpacing.md) {
                // 时间设置头部区域
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("时间设置")
                            .font(BrandFont.body(size: 16, weight: .bold))
                            .foregroundColor(BrandColor.neutral900)
                        if hasTime {
                            Text(eventTime.formatted(.dateTime.hour().minute()))
                                .font(BrandFont.body(size: 14, weight: .medium))
                                .foregroundColor(BrandColor.neutral700)
                        } else {
                            Text("全天事项")
                                .font(BrandFont.body(size: 14, weight: .medium))
                                .foregroundColor(BrandColor.neutral500)
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
                            Text("调整时间")
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
        CuteCard(backgroundColor: BrandSolid.cardWhite) {
            VStack(alignment: .leading, spacing: BrandSpacing.md) {
                Text("事项详情")
                    .font(BrandFont.body(size: 16, weight: .bold))
                    .foregroundColor(BrandColor.neutral900)
                
                ZStack(alignment: .topLeading) {
                    // 背景
                    RoundedRectangle(cornerRadius: BrandRadius.sm)
                        .fill(BrandColor.neutral100)
                        .neobrutalStyle(cornerRadius: BrandRadius.sm,
                                       borderWidth: BrandBorder.regular)
                        .frame(minHeight: 120)
                    
                    // 占位文字
                    if details.isEmpty {
                        Text("添加更多详情信息，如地点、备注等...")
                            .font(BrandFont.body(size: 16, weight: .regular))
                            .foregroundColor(BrandColor.neutral500)
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
    
    
    // MARK: - 计算属性
    
    // MARK: - 操作方法
    
    /// 自动保存方法 - 当用户修改任何字段时触发
    private func autoSave() {
        // 防抖处理，避免频繁保存
        hasUnsavedChanges = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if hasUnsavedChanges {
                saveEvent()
                hasUnsavedChanges = false
            }
        }
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
            let newEvent = storageManager.createEvent(
                title: trimmedTitle,
                date: eventDate,
                startAt: eventStartDate,
                endAt: eventEndDate,
                details: eventDetails
            )
            print("✅ 自动保存新事项：\(newEvent.title)")
            
        case .edit(let existingEvent):
            storageManager.updateEvent(
                existingEvent,
                title: trimmedTitle,
                startAt: eventStartDate,
                endAt: eventEndDate,
                details: eventDetails
            )
            print("✅ 自动保存更新事项：\(trimmedTitle)")
        }
    }
    
    private func deleteEvent() {
        if case .edit(let event) = editMode {
            storageManager.deleteEvent(event)
            print("🗑️ 删除事项：\(event.title)")
        }
        dismiss()
    }
}

// MARK: - Preview
#Preview("创建新事项") {
    EventEditView(mode: .create, initialDate: Date())
}

#Preview("编辑现有事项") {
    EventEditView(mode: .edit(Event.sampleEvents.first!))
}
