//
//  CompactAIInputOverlay.swift
//  HiCalendar
//
//  轻量蒙层输入条：点击图标后仅浮出输入框，背景半透明
//

import SwiftUI
import UIKit

struct CompactAIInputOverlay: View {
    @Binding var isPresented: Bool
    @State private var text: String = ""
    @FocusState private var focused: Bool
    @State private var isProcessing = false
    @ObservedObject private var voice = AIVoiceManager.shared
    @State private var messages: [InlineMessage] = []
    
    var body: some View {
        ZStack {
            // 背景半透明蒙层（更深一些以聚焦输入）
            Color.black.opacity(0.44)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            // 底部输入条与消息区（贴近输入框）
            VStack(alignment: .leading, spacing: 0) {
                Spacer()

                // 最近消息（紧贴输入框上方，按顺序显示，无数量上限，可滚动）
                if !messages.isEmpty {
                    ScrollViewReader { proxy in
                        ScrollView(showsIndicators: false) {
                            HStack(alignment: .bottom, spacing: BrandSpacing.sm) {
                                VStack(spacing: BrandSpacing.xs) {
                                    Spacer(minLength: 0) // 将内容推到底部
                                    ForEach(messages) { m in
                                        Text(m.text)
                                            .font(BrandFont.body(size: 15, weight: .regular))
                                            .foregroundColor(m.isUser ? BrandColor.onPrimary : BrandColor.onSurface)
                                            .padding(.horizontal, BrandSpacing.md)
                                            .padding(.vertical, BrandSpacing.sm)
                                            .frame(minHeight: 52, alignment: .leading)
                                            .background(
                                                RoundedRectangle(cornerRadius: BrandRadius.lg, style: .continuous)
                                                    .fill(m.isUser ? BrandColor.primaryBlue : BrandColor.surface.opacity(0.96))
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: BrandRadius.lg, style: .continuous)
                                                    .stroke(m.isUser ? Color.clear : BrandColor.outline.opacity(0.08), lineWidth: 1)
                                            )
                                            .frame(maxWidth: .infinity, alignment: m.isUser ? .trailing : .leading)
                                            .id(m.id)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                // 预留与发送按钮等宽的占位，保证消息宽度与输入框一致
                                Color.clear.frame(width: 48)
                            }
                            .padding(.horizontal, BrandSpacing.md)
                            .padding(.bottom, BrandSpacing.xs)
                        }
                        .frame(maxHeight: UIScreen.main.bounds.height * 0.4)
                        .onChange(of: messages.count) { _ in
                            if let last = messages.last?.id {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    proxy.scrollTo(last, anchor: .bottom)
                                }
                            }
                        }
                    }
                }
                HStack(spacing: BrandSpacing.sm) {
                    // 一行输入框（无外层容器）
                    TextField("例如：明天9点和王强开会…", text: $text)
                        .font(BrandFont.body(size: 17, weight: .regular))
                        .padding(.horizontal, BrandSpacing.md)
                        .frame(height: 52)
                        .focused($focused)
                        .background(
                            RoundedRectangle(cornerRadius: BrandRadius.lg, style: .continuous)
                                .fill(BrandColor.surface.opacity(0.96))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: BrandRadius.lg, style: .continuous)
                                .stroke(BrandColor.outline.opacity(0.12), lineWidth: 1)
                        )
                        .frame(maxWidth: .infinity)

                    // 发送按钮
                    Button(action: send) {
                        Image(systemName: isProcessing ? "clock.arrow.circlepath" : "paperplane.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 48, height: 48)
                            .background(
                                Circle()
                                    .fill(canSend ? BrandColor.primaryBlue : BrandColor.outline.opacity(0.5))
                            )
                    }
                    .disabled(!canSend || isProcessing)
                }
                .padding(.horizontal, BrandSpacing.lg)
                .padding(.top, BrandSpacing.sm)
                .padding(.bottom, BrandSpacing.sm)
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { focused = true }
        }
        .onReceive(voice.$aiResponse) { resp in
            guard !resp.isEmpty else { return }
            // 避免重复插入相同回复
            if messages.last?.text != resp {
                messages.append(.init(text: resp, isUser: false))
            }
        }
    }
    
    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func send() {
        guard canSend, !isProcessing else { return }
        withAnimation(.easeInOut(duration: 0.15)) { isProcessing = true }
        let content = text.trimmingCharacters(in: .whitespacesAndNewlines)
        // 轻量流程：先回显用户消息
        withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
            messages.append(.init(text: content, isUser: true))
        }
        // 调用文本处理
        AIVoiceManager.shared.processText(content)
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        // 不立即关闭，等待用户查看；允许用户手动点背景关闭
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeInOut(duration: 0.15)) { isProcessing = false }
            text = ""
        }
    }
    
    private func dismiss() { isPresented = false }
}

private struct InlineMessage: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let isUser: Bool
}
