//
//  MemberDataBackupView.swift
//  HiCalendar
//
//  会员数据备份与恢复视图
//

import SwiftUI

struct MemberDataBackupView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var syncManager = MemberDataSyncManager.shared
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isCreatingBackup = false
    @State private var backupProgress: Double = 0.0

    var body: some View {
        NavigationStack {
            ZStack {
                // 背景
                BrandColor.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: BrandSpacing.xl) {
                        // 头部说明
                        headerSection

                        // 当前状态
                        statusSection

                        // 备份操作
                        backupSection

                        // 使用说明
                        instructionsSection

                        Spacer(minLength: BrandSpacing.xxl)
                    }
                    .padding(BrandSpacing.lg)
                }
            }
            .navigationTitle("数据备份与恢复")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                    .font(BrandFont.body(size: 16, weight: .medium))
                    .foregroundColor(BrandColor.primaryBlue)
                }
            }
        }
        .alert("提示", isPresented: $showingAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: BrandSpacing.md) {
            Text("🔒")
                .font(.system(size: 60))

            Text("保护您的数据")
                .font(BrandFont.headline(size: 24, weight: .bold))
                .foregroundColor(BrandColor.onSurface)

            Text("作为会员，您的所有日历数据都会安全地同步到云端，确保在任何设备上都不会丢失。")
                .font(BrandFont.body(size: 16, weight: .medium))
                .foregroundColor(BrandColor.onSurface.opacity(0.8))
                .multilineTextAlignment(.center)
                .lineLimit(nil)
        }
    }

    // MARK: - Status Section
    private var statusSection: some View {
        MD3Card(type: .filled) {
            VStack(spacing: BrandSpacing.md) {
                HStack {
                    Text("同步状态")
                        .font(BrandFont.body(size: 18, weight: .bold))
                        .foregroundColor(BrandColor.onSurface)
                    Spacer()
                }

                let stats = syncManager.getSyncStats()

                VStack(spacing: BrandSpacing.sm) {
                    statusRow(
                        icon: "iphone",
                        title: "本地事项",
                        value: "\(stats.localEvents)个",
                        color: BrandColor.primaryBlue
                    )

                    statusRow(
                        icon: "icloud",
                        title: "上次同步",
                        value: formatLastSync(stats.lastSync),
                        color: stats.isUpToDate ? BrandColor.success : BrandColor.warning
                    )

                    statusRow(
                        icon: "checkmark.shield",
                        title: "数据安全性",
                        value: "已加密保护",
                        color: BrandColor.success
                    )
                }

                // 同步进度条（仅在同步中显示）
                if syncManager.syncStatus == .syncing {
                    VStack(spacing: BrandSpacing.xs) {
                        ProgressView(value: syncManager.syncProgress)
                            .progressViewStyle(LinearProgressViewStyle(tint: BrandColor.primaryBlue))

                        Text("正在同步数据...")
                            .font(BrandFont.body(size: 14, weight: .medium))
                            .foregroundColor(BrandColor.primaryBlue)
                    }
                }
            }
            .padding(BrandSpacing.lg)
        }
    }

    // MARK: - Backup Section
    private var backupSection: some View {
        VStack(spacing: BrandSpacing.md) {
            HStack {
                Text("备份操作")
                    .font(BrandFont.body(size: 18, weight: .bold))
                    .foregroundColor(BrandColor.onSurface)
                Spacer()
            }

            VStack(spacing: BrandSpacing.sm) {
                // 创建备份按钮
                Button(action: {
                    createBackup()
                }) {
                    HStack {
                        if isCreatingBackup {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: BrandColor.onPrimary))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 18, weight: .medium))
                        }

                        Text(isCreatingBackup ? "创建备份中..." : "创建新备份")
                            .font(BrandFont.body(size: 16, weight: .medium))

                        Spacer()
                    }
                    .foregroundColor(BrandColor.onPrimary)
                    .padding(BrandSpacing.md)
                    .background(BrandColor.primaryBlue)
                    .neobrutalStyle(cornerRadius: BrandRadius.md, borderWidth: BrandBorder.thick)
                }
                .disabled(isCreatingBackup)

                // 手动同步按钮
                Button(action: {
                    performSync()
                }) {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 18, weight: .medium))
                        Text("立即同步")
                            .font(BrandFont.body(size: 16, weight: .medium))
                        Spacer()
                    }
                    .foregroundColor(BrandColor.primaryBlue)
                    .padding(BrandSpacing.md)
                    .background(BrandColor.primaryBlue.opacity(0.1))
                    .neobrutalStyle(cornerRadius: BrandRadius.md, borderWidth: BrandBorder.thin)
                }
                .disabled(syncManager.syncStatus == .syncing)

                // 恢复数据说明
                MD3Card(type: .outlined) {
                    VStack(alignment: .leading, spacing: BrandSpacing.sm) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(BrandColor.primaryBlue)
                            Text("数据恢复")
                                .font(BrandFont.body(size: 16, weight: .bold))
                                .foregroundColor(BrandColor.onSurface)
                        }

                        Text("如需恢复数据，只需在新设备上登录您的账户，所有数据将自动从云端同步到本地。")
                            .font(BrandFont.body(size: 14, weight: .medium))
                            .foregroundColor(BrandColor.onSurface.opacity(0.8))
                            .lineLimit(nil)
                    }
                    .padding(BrandSpacing.md)
                }
            }
        }
    }

    // MARK: - Instructions Section
    private var instructionsSection: some View {
        VStack(spacing: BrandSpacing.md) {
            HStack {
                Text("使用说明")
                    .font(BrandFont.body(size: 18, weight: .bold))
                    .foregroundColor(BrandColor.onSurface)
                Spacer()
            }

            VStack(spacing: BrandSpacing.sm) {
                instructionItem(
                    number: "1",
                    title: "自动同步",
                    description: "App会定期自动同步您的数据到云端，无需手动操作。"
                )

                instructionItem(
                    number: "2",
                    title: "手动备份",
                    description: "您可以随时创建手动备份，确保重要数据得到及时保护。"
                )

                instructionItem(
                    number: "3",
                    title: "数据安全",
                    description: "所有数据均采用端到端加密，只有您可以访问自己的数据。"
                )

                instructionItem(
                    number: "4",
                    title: "跨设备同步",
                    description: "在任何设备上登录，数据都会自动同步，保持一致。"
                )
            }
        }
    }

    // MARK: - Helper Views
    private func statusRow(icon: String, title: String, value: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(color)
                .frame(width: 20)

            Text(title)
                .font(BrandFont.body(size: 14, weight: .medium))
                .foregroundColor(BrandColor.onSurface)

            Spacer()

            Text(value)
                .font(BrandFont.body(size: 14, weight: .bold))
                .foregroundColor(color)
        }
    }

    private func instructionItem(number: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: BrandSpacing.md) {
            // 数字标识
            Text(number)
                .font(BrandFont.body(size: 14, weight: .bold))
                .foregroundColor(BrandColor.onPrimary)
                .frame(width: 24, height: 24)
                .background(BrandColor.primaryBlue)
                .clipShape(Circle())

            // 内容
            VStack(alignment: .leading, spacing: BrandSpacing.xs) {
                Text(title)
                    .font(BrandFont.body(size: 16, weight: .bold))
                    .foregroundColor(BrandColor.onSurface)

                Text(description)
                    .font(BrandFont.body(size: 14, weight: .medium))
                    .foregroundColor(BrandColor.onSurface.opacity(0.8))
                    .lineLimit(nil)
            }

            Spacer()
        }
        .padding(BrandSpacing.md)
        .background(BrandColor.surface)
        .neobrutalStyle(cornerRadius: BrandRadius.md, borderWidth: BrandBorder.thin)
    }

    // MARK: - Helper Methods
    private func formatLastSync(_ date: Date?) -> String {
        guard let date = date else { return "从未同步" }

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func createBackup() {
        isCreatingBackup = true

        Task {
            let success = await syncManager.createBackup()

            await MainActor.run {
                isCreatingBackup = false

                if success {
                    showAlert(message: "备份创建成功！您的数据已安全保存到云端。")
                } else {
                    showAlert(message: "备份创建失败，请检查网络连接后重试。")
                }
            }
        }
    }

    private func performSync() {
        Task {
            let result = await syncManager.performIncrementalSync()

            await MainActor.run {
                if result.success {
                    let message = "同步完成！\n上传：\(result.eventsUploaded)个事项\n下载：\(result.eventsDownloaded)个事项"
                    showAlert(message: message)
                } else {
                    showAlert(message: "同步失败：\(result.errorMessage ?? "网络连接异常")")
                }
            }
        }
    }

    private func showAlert(message: String) {
        alertMessage = message
        showingAlert = true
    }
}

#Preview {
    MemberDataBackupView()
}