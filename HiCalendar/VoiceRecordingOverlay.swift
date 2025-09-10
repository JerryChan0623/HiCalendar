//
//  VoiceRecordingOverlay.swift
//  HiCalendar
//
//  Created on 2024. 录音蒙层界面 - 类似微信语音录音体验
//

import SwiftUI

// MARK: - 录音蒙层主界面
struct VoiceRecordingOverlay: View {
    @Binding var isPresented: Bool
    @ObservedObject var voiceManager: AIVoiceManager
    
    // 动画状态
    @State private var overlayOpacity: Double = 0
    @State private var recordingViewScale: CGFloat = 0.8
    @State private var waveAnimation: Bool = false
    
    var body: some View {
        ZStack {
            // 强化的背景蒙层效果 - 类似微信
            backgroundLayer
            
            // 录音主界面
            mainContentView
        }
        .opacity(overlayOpacity)
        .onAppear {
            showOverlay()
        }
        .onChange(of: isPresented) { _, newValue in
            if !newValue {
                hideOverlay()
            }
        }
    }
    
    // MARK: - 背景层
    private var backgroundLayer: some View {
        ZStack {
            // 深色背景
            Color.black.opacity(0.85)
            
            // 模糊效果
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.3)
        }
        .ignoresSafeArea()
        .onTapGesture {
            dismissRecording()
        }
    }
    
    // MARK: - 主内容视图
    private var mainContentView: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // 语音识别文本区域
            recognizedTextArea
            
            Spacer()
            
            // 音波条区域
            waveArea
            
            Spacer()
            
            // 底部操作区域
            bottomControlArea
        }
        .scaleEffect(recordingViewScale)
    }
    
    // MARK: - 识别文本区域
    private var recognizedTextArea: some View {
        VStack {
            if !voiceManager.recognizedText.isEmpty {
                VStack(spacing: BrandSpacing.sm) {
                    Text("识别中...")
                        .font(BrandFont.body(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                    
                    ScrollView {
                        Text(voiceManager.recognizedText)
                            .font(BrandFont.body(size: 20, weight: .medium))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, BrandSpacing.lg)
                            .padding(.vertical, BrandSpacing.lg)
                    }
                    .frame(maxHeight: 150)
                    .background(
                        RoundedRectangle(cornerRadius: BrandRadius.lg)
                            .fill(Color.white.opacity(0.15))
                            .overlay(
                                RoundedRectangle(cornerRadius: BrandRadius.lg)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                .padding(.horizontal, BrandSpacing.lg)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(minHeight: 180)
    }
    
    // MARK: - 音波区域
    private var waveArea: some View {
        Group {
            if voiceManager.isListening {
                audioWaveView
                    .padding(.vertical, BrandSpacing.xl)
            } else {
                Text("准备录音")
                    .font(BrandFont.body(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.vertical, BrandSpacing.xl)
            }
        }
    }
    
    // MARK: - 底部控制区域
    private var bottomControlArea: some View {
        VStack(spacing: BrandSpacing.lg) {
            // 主录音按钮
            recordingButtonArea
            
            // 提示文本
            instructionText
        }
        .padding(.bottom, BrandSpacing.xxl)
    }
    
    // MARK: - 音波条视图
    private var audioWaveView: some View {
        HStack(spacing: 4) {
            ForEach(0..<20, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white.opacity(0.8))
                    .frame(width: 3, height: waveHeight(for: index))
                    .animation(
                        .easeInOut(duration: Double.random(in: 0.3...0.8))
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.05),
                        value: waveAnimation
                    )
            }
        }
        .frame(height: 60)
        .onAppear {
            waveAnimation = true
        }
    }
    
    // 计算音波条高度
    private func waveHeight(for index: Int) -> CGFloat {
        let baseHeight: CGFloat = 8
        let maxHeight: CGFloat = 50
        
        if !waveAnimation {
            return baseHeight
        }
        
        // 模拟音频波形
        let phase = Double(index) * 0.3 + voiceManager.recordingDuration * 2
        let amplitude = sin(phase) * sin(phase * 1.3) * sin(phase * 0.7)
        let height = baseHeight + (maxHeight - baseHeight) * CGFloat(abs(amplitude))
        
        return height
    }
    
    // MARK: - 录音按钮区域
    private var recordingButtonArea: some View {
        ZStack {
            // 外圈波纹动画
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .stroke(
                        voiceManager.isListening ? 
                        Color.white.opacity(0.3 - Double(index) * 0.1) : 
                        Color.clear,
                        lineWidth: 2
                    )
                    .frame(width: 120 + CGFloat(index * 30), height: 120 + CGFloat(index * 30))
                    .scaleEffect(waveAnimation ? 1.2 : 1.0)
                    .animation(
                        .easeInOut(duration: 1.5)
                            .delay(Double(index) * 0.2)
                            .repeatForever(autoreverses: true),
                        value: waveAnimation
                    )
            }
            
            // 中心录音按钮
            Button(action: {}) {
                ZStack {
                    Circle()
                        .fill(
                            voiceManager.isListening ? 
                            BrandColor.danger : 
                            BrandColor.primaryYellow
                        )
                        .frame(width: 100, height: 100)
                        .shadow(
                            color: voiceManager.isListening ? 
                            BrandColor.danger.opacity(0.4) : 
                            BrandColor.primaryYellow.opacity(0.4),
                            radius: 12, x: 0, y: 6
                        )
                    
                    if voiceManager.isListening {
                        // 录音中 - 显示方形停止图标
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.white)
                            .frame(width: 24, height: 24)
                    } else {
                        // 未录音 - 显示麦克风图标
                        Image(systemName: "mic.fill")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .disabled(true) // 禁用点击，只通过长按手势控制
            .scaleEffect(voiceManager.isListening ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: voiceManager.isListening)
        }
        .onAppear {
            waveAnimation = true
        }
    }
    
    // MARK: - 指示文本
    private var instructionText: some View {
        VStack(spacing: BrandSpacing.xs) {
            if voiceManager.isListening {
                Text("松开发送，上滑取消")
                    .font(BrandFont.body(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                
                // 录音时长
                Text("录音中 \(String(format: "%.1f", voiceManager.recordingDuration))s")
                    .font(BrandFont.body(size: 12, weight: .regular))
                    .foregroundColor(.white.opacity(0.6))
            } else {
                Text("长按0.5秒开始录音")
                    .font(BrandFont.body(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                
                Text("单击关闭")
                    .font(BrandFont.body(size: 12, weight: .regular))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
    }
    
    // MARK: - 动画控制
    private func showOverlay() {
        withAnimation(.easeOut(duration: 0.3)) {
            overlayOpacity = 1.0
            recordingViewScale = 1.0
        }
    }
    
    private func hideOverlay() {
        withAnimation(.easeIn(duration: 0.25)) {
            overlayOpacity = 0.0
            recordingViewScale = 0.8
        }
    }
    
    private func dismissRecording() {
        // 如果正在录音，先停止录音
        if voiceManager.isListening {
            voiceManager.stopListening()
        }
        isPresented = false
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color.blue.ignoresSafeArea()
        VoiceRecordingOverlay(
            isPresented: .constant(true),
            voiceManager: AIVoiceManager.shared
        )
    }
}