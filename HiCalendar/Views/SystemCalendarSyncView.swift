//
//  SystemCalendarSyncView.swift
//  HiCalendar
//
//  Created on 2025. System Calendar Sync Settings Interface
//

import SwiftUI
import EventKit

struct SystemCalendarSyncView: View {
    @StateObject private var syncManager = SystemCalendarManager.shared
    @State private var showPermissionAlert = false
    @State private var showSyncError = false
    @State private var showPermissionGuide = false

    var body: some View {
        NavigationView {
            List {
                // Premium Feature Section
                if syncManager.isPremiumFeature {
                    premiumRequiredSection
                } else {
                    // Sync Enable/Disable
                    syncToggleSection

                    if syncManager.hasCalendarAccess && syncManager.syncEnabled {
                        // Sync Configuration
                        syncDirectionSection
                        syncFrequencySection
                        calendarSelectionSection

                        // Sync Actions
                        syncActionsSection

                        // Sync Status
                        syncStatusSection
                    }
                }
            }
            .navigationTitle(L10n.systemCalendarSync)
            .navigationBarTitleDisplayMode(.large)
            .alert(L10n.calendarPermissionRequired, isPresented: $showPermissionAlert) {
                Button(L10n.ok) { }
            } message: {
                Text(syncManager.errorMessage ?? L10n.calendarPermissionDenied)
            }
            .alert(L10n.syncError(""), isPresented: $showSyncError) {
                Button(L10n.ok) {
                    syncManager.errorMessage = nil
                }
            } message: {
                Text(syncManager.errorMessage ?? L10n.somethingWentWrong)
            }
            .onChange(of: syncManager.errorMessage) { _, newValue in
                if newValue != nil {
                    showSyncError = true
                }
            }
            .alert("需要日历权限", isPresented: $showPermissionGuide) {
                Button("去设置") {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }
                Button("取消", role: .cancel) { }
            } message: {
                Text("为了与系统日历同步，HiCalendar需要访问您的日历。\n\n请在系统设置中开启权限：\n设置 → 隐私与安全性 → 日历 → HiCalendar")
            }
        }
    }

    // MARK: - Premium Required Section
    private var premiumRequiredSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "calendar.badge.plus")
                        .foregroundColor(.blue)
                        .font(.title2)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.systemCalendarSync)
                            .font(.headline)
                        Text(L10n.systemCalendarRequiresPremium)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: "crown.fill")
                        .foregroundColor(.yellow)
                        .font(.title3)
                }

                Text("与系统日历双向同步，永不丢失重要事项")
                    .font(.body)
                    .foregroundColor(.primary)

                NavigationLink(destination: PremiumView()) {
                    HStack {
                        Text(L10n.upgradeNow)
                            .font(.headline)
                        Spacer()
                        Image(systemName: "arrow.right")
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
            }
            .padding(.vertical, 8)
        }
    }

    // MARK: - Sync Toggle Section
    private var syncToggleSection: some View {
        Section {
            HStack {
                Image(systemName: "calendar.badge.plus")
                    .foregroundColor(.blue)

                VStack(alignment: .leading) {
                    Text(L10n.enableCalendarSync)
                        .font(.headline)
                    if !syncManager.hasCalendarAccess {
                        Text(L10n.calendarPermissionRequired)
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }

                Spacer()

                Toggle("", isOn: Binding(
                    get: { syncManager.syncEnabled && syncManager.hasCalendarAccess },
                    set: { isEnabled in
                        Task {
                            if isEnabled {
                                // 清除之前的错误消息
                                syncManager.errorMessage = nil

                                let hasPermission = await syncManager.requestCalendarPermission()
                                if hasPermission {
                                    await syncManager.enableSync()
                                } else {
                                    // 权限被拒绝，显示引导
                                    showPermissionGuide = true
                                }
                            } else {
                                syncManager.disableSync()
                            }
                        }
                    }
                ))
                .disabled(syncManager.isLoading)
            }
        } footer: {
            Text("启用后将与系统日历进行双向同步，确保数据安全")
                .font(.caption)
        }
    }

    // MARK: - Sync Direction Section
    private var syncDirectionSection: some View {
        Section(header: Text(L10n.syncDirectionTitle)) {
            ForEach(SystemCalendarManager.SyncDirection.allCases, id: \.self) { direction in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(direction.displayName)
                            .font(.body)
                        Text(direction.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    if syncManager.syncDirection == direction {
                        Image(systemName: "checkmark")
                            .foregroundColor(.blue)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    syncManager.syncDirection = direction
                }
            }
        }
    }

    // MARK: - Sync Frequency Section
    private var syncFrequencySection: some View {
        Section(header: Text(L10n.syncFrequencyTitle)) {
            ForEach(SystemCalendarManager.SyncFrequency.allCases, id: \.self) { frequency in
                HStack {
                    Text(frequency.displayName)

                    Spacer()

                    if syncManager.syncFrequency == frequency {
                        Image(systemName: "checkmark")
                            .foregroundColor(.blue)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    syncManager.syncFrequency = frequency
                }
            }
        }
    }

    // MARK: - Calendar Selection Section
    private var calendarSelectionSection: some View {
        Section(
            header: Text(L10n.selectedCalendarsTitle),
            footer: Text("选择要同步的日历，建议创建专用的HiCalendar日历以便管理").font(.caption)
        ) {
            // 创建HiCalendar专用日历选项
            let hasHiCalendar = syncManager.availableCalendars.contains { $0.title == "HiCalendar" }

            if !hasHiCalendar {
                Button(action: {
                    Task {
                        let success = await syncManager.createHiCalendarDedicatedCalendar()
                        if success {
                            print("✅ HiCalendar日历创建成功")
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.green)

                        VStack(alignment: .leading) {
                            Text("创建HiCalendar专用日历")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text("推荐：为HiCalendar事件创建专用分类")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Image(systemName: "arrow.right")
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.vertical, 4)
            }

            ForEach(syncManager.availableCalendars, id: \.calendarIdentifier) { calendar in
                HStack {
                    Circle()
                        .fill(Color(calendar.cgColor))
                        .frame(width: 12, height: 12)

                    VStack(alignment: .leading) {
                        Text(calendar.title)
                            .foregroundColor(.primary)

                        if calendar.title == "HiCalendar" {
                            Text("HiCalendar专用日历")
                                .font(.caption)
                                .foregroundColor(.blue)
                        } else {
                            Text(calendar.source.title)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    if syncManager.selectedCalendars.contains(calendar.calendarIdentifier) {
                        Image(systemName: "checkmark")
                            .foregroundColor(.blue)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    syncManager.toggleCalendarSelection(calendar)
                }
            }
        }
    }

    // MARK: - Sync Actions Section
    private var syncActionsSection: some View {
        Section(header: Text("同步操作")) {
            Button(action: {
                Task {
                    await syncManager.performSync()
                }
            }) {
                HStack {
                    if syncManager.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }

                    Text(syncManager.isLoading ? L10n.syncInProgress : L10n.performManualSync)
                }
                .foregroundColor(syncManager.isLoading ? .secondary : .blue)
            }
            .disabled(syncManager.isLoading || syncManager.selectedCalendars.isEmpty)

            Button(action: {
                Task {
                    await syncManager.cleanupSystemCalendarDuplicates()
                }
            }) {
                HStack {
                    Image(systemName: "trash.circle")
                        .foregroundColor(.orange)

                    Text("清理重复事件")
                        .foregroundColor(.primary)
                }
            }
            .disabled(syncManager.isLoading)

            Button(action: {
                Task {
                    let success = await syncManager.switchToHiCalendarOnly()
                    if success {
                        print("✅ 成功切换到HiCalendar专用日历")
                    }
                }
            }) {
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundColor(.blue)

                    VStack(alignment: .leading) {
                        Text("切换到HiCalendar日历")
                            .foregroundColor(.primary)
                        Text("解决事件被分配到其他日历的问题")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .disabled(syncManager.isLoading)
        }
    }

    // MARK: - Sync Status Section
    private var syncStatusSection: some View {
        Section {
            HStack {
                Text(L10n.lastSyncTime)
                    .foregroundColor(.secondary)

                Spacer()

                if let lastSync = syncManager.lastSyncDate {
                    Text(formatDate(lastSync))
                        .foregroundColor(.secondary)
                } else {
                    Text("从未同步")
                        .foregroundColor(.orange)
                }
            }
        }
    }

    // MARK: - Helper Methods
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
}

#Preview {
    SystemCalendarSyncView()
}