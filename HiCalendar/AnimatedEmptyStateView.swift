//
//  AnimatedEmptyStateView.swift
//  HiCalendar
//
//  Created on 2024. SwiftUI自绘动画空状态组件
//

import SwiftUI

// MARK: - 动画空状态主组件
struct AnimatedEmptyStateView: View {
    enum StateType {
        case emptyCalendar
        case noEvents
        case allCompleted
        case loading
        case noConnection
    }
    
    let type: StateType
    let message: String
    let size: CGFloat
    
    init(type: StateType, message: String, size: CGFloat = 120) {
        self.type = type
        self.message = message
        self.size = size
    }
    
    var body: some View {
        VStack(spacing: BrandSpacing.lg) {
            // 动画图标区域
            animationView
                .frame(width: size, height: size)
            
            // 消息文本
            Text(message)
                .font(BrandFont.body(size: 16, weight: .medium))
                .foregroundColor(BrandColor.outline)
                .multilineTextAlignment(.center)
                .padding(.horizontal, BrandSpacing.lg)
        }
    }
    
    @ViewBuilder
    private var animationView: some View {
        switch type {
        case .emptyCalendar:
            EmptyCalendarAnimation(size: size)
        case .noEvents:
            NoEventsAnimation(size: size)
        case .allCompleted:
            CompletedAnimation(size: size)
        case .loading:
            LoadingAnimation(size: size)
        case .noConnection:
            NoConnectionAnimation(size: size)
        }
    }
}

// MARK: - 空日历动画
struct EmptyCalendarAnimation: View {
    let size: CGFloat
    @State private var isAnimating = false
    @State private var pageFlip = false
    
    var body: some View {
        ZStack {
            // 日历背景
            RoundedRectangle(cornerRadius: size * 0.1)
                .fill(LinearGradient(
                    colors: [Color.white, Color.gray.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.1)
                        .stroke(BrandColor.outline.opacity(0.3), lineWidth: 2)
                )
            
            // 日历页面
            VStack(spacing: size * 0.05) {
                // 顶部装订环
                HStack(spacing: size * 0.1) {
                    ForEach(0..<3, id: \.self) { _ in
                        Circle()
                            .fill(BrandColor.outline.opacity(0.4))
                            .frame(width: size * 0.08, height: size * 0.08)
                    }
                }
                .padding(.top, size * 0.1)
                
                // 日期网格
                VStack(spacing: size * 0.03) {
                    ForEach(0..<4, id: \.self) { row in
                        HStack(spacing: size * 0.03) {
                            ForEach(0..<7, id: \.self) { col in
                                RoundedRectangle(cornerRadius: size * 0.02)
                                    .fill(BrandColor.outline.opacity(0.1))
                                    .frame(width: size * 0.08, height: size * 0.08)
                                    .scaleEffect(isAnimating ? 0.8 : 1.0)
                                    .opacity(isAnimating ? 0.5 : 1.0)
                                    .animation(
                                        .easeInOut(duration: 1.5)
                                            .delay(Double(row * 7 + col) * 0.1)
                                            .repeatForever(autoreverses: true),
                                        value: isAnimating
                                    )
                            }
                        }
                    }
                }
                .padding(.horizontal, size * 0.1)
                
                Spacer()
            }
            
            // 浮动的"+"号
            Image(systemName: "plus.circle.fill")
                .font(.system(size: size * 0.2, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [BrandColor.primaryYellow, BrandColor.primaryBlue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .offset(x: size * 0.3, y: size * 0.2)
                .scaleEffect(pageFlip ? 1.2 : 0.8)
                .rotationEffect(.degrees(pageFlip ? 10 : -10))
                .animation(
                    .easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                    value: pageFlip
                )
        }
        .onAppear {
            isAnimating = true
            pageFlip = true
        }
    }
}

// MARK: - 无事件动画
struct NoEventsAnimation: View {
    let size: CGFloat
    @State private var isAnimating = false
    @State private var cloudOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            // 背景云朵
            ForEach(0..<3, id: \.self) { index in
                Cloud(size: size * 0.15)
                    .fill(BrandColor.outline.opacity(0.1))
                    .offset(
                        x: cloudOffset + CGFloat(index - 1) * size * 0.3,
                        y: CGFloat(index - 1) * size * 0.1
                    )
                    .animation(
                        .easeInOut(duration: 3.0 + Double(index))
                            .repeatForever(autoreverses: true),
                        value: cloudOffset
                    )
            }
            
            // 中央文档图标
            VStack(spacing: size * 0.05) {
                RoundedRectangle(cornerRadius: size * 0.05)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: size * 0.05)
                            .stroke(BrandColor.outline.opacity(0.3), lineWidth: 2)
                    )
                    .overlay(
                        VStack(spacing: size * 0.02) {
                            ForEach(0..<4, id: \.self) { _ in
                                RoundedRectangle(cornerRadius: size * 0.01)
                                    .fill(BrandColor.outline.opacity(0.2))
                                    .frame(height: size * 0.02)
                            }
                        }
                        .padding(size * 0.1)
                    )
                    .frame(width: size * 0.4, height: size * 0.5)
                    .scaleEffect(isAnimating ? 1.05 : 0.95)
                    .animation(
                        .easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                        value: isAnimating
                    )
                
                // 搜索放大镜
                Image(systemName: "magnifyingglass")
                    .font(.system(size: size * 0.15, weight: .medium))
                    .foregroundColor(BrandColor.outline.opacity(0.6))
                    .rotationEffect(.degrees(isAnimating ? 10 : -10))
                    .animation(
                        .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                        value: isAnimating
                    )
            }
        }
        .onAppear {
            isAnimating = true
            cloudOffset = size * 0.1
        }
    }
}

// MARK: - 任务完成动画
struct CompletedAnimation: View {
    let size: CGFloat
    @State private var checkmarkScale: CGFloat = 0
    @State private var particlesVisible = false
    @State private var celebrationScale: CGFloat = 0
    
    var body: some View {
        ZStack {
            // 庆祝粒子
            ForEach(0..<8, id: \.self) { index in
                Circle()
                    .fill(
                        [BrandColor.primaryYellow, BrandColor.primaryBlue, 
                         Color.pink, Color.green].randomElement() ?? BrandColor.primaryYellow
                    )
                    .frame(width: size * 0.05, height: size * 0.05)
                    .offset(
                        x: cos(Double(index) * .pi / 4) * size * 0.4,
                        y: sin(Double(index) * .pi / 4) * size * 0.4
                    )
                    .scaleEffect(particlesVisible ? 1.0 : 0)
                    .opacity(particlesVisible ? 1.0 : 0)
                    .animation(
                        .easeOut(duration: 0.8)
                            .delay(0.3 + Double(index) * 0.1),
                        value: particlesVisible
                    )
            }
            
            // 主要勾选圆圈
            Circle()
                .fill(
                    LinearGradient(
                        colors: [BrandColor.success, BrandColor.success.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size * 0.6, height: size * 0.6)
                .scaleEffect(celebrationScale)
                .animation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.1), value: celebrationScale)
            
            // 勾选图标
            Image(systemName: "checkmark")
                .font(.system(size: size * 0.25, weight: .bold))
                .foregroundColor(.white)
                .scaleEffect(checkmarkScale)
                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.2), value: checkmarkScale)
        }
        .onAppear {
            celebrationScale = 1.0
            checkmarkScale = 1.0
            particlesVisible = true
        }
    }
}

// MARK: - 加载动画
struct LoadingAnimation: View {
    let size: CGFloat
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // 外圈
            Circle()
                .stroke(BrandColor.outline.opacity(0.2), lineWidth: size * 0.05)
            
            // 动画圈
            Circle()
                .trim(from: 0, to: 0.7)
                .stroke(
                    LinearGradient(
                        colors: [BrandColor.primaryBlue, BrandColor.primaryYellow],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: size * 0.05, lineCap: .round)
                )
                .rotationEffect(.degrees(rotation))
                .animation(
                    .linear(duration: 1.5).repeatForever(autoreverses: false),
                    value: rotation
                )
            
            // 中心云图标
            Image(systemName: "icloud.and.arrow.up")
                .font(.system(size: size * 0.3, weight: .medium))
                .foregroundColor(BrandColor.primaryBlue)
                .scaleEffect(scale)
                .animation(
                    .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                    value: scale
                )
        }
        .onAppear {
            rotation = 360
            scale = 1.2
        }
    }
}

// MARK: - 无网络连接动画
struct NoConnectionAnimation: View {
    let size: CGFloat
    @State private var waveOffset: CGFloat = 0
    @State private var deviceShake: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Wi-Fi信号塔
            VStack(spacing: size * 0.02) {
                // 信号波纹
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .stroke(
                            BrandColor.outline.opacity(0.3),
                            lineWidth: size * 0.02
                        )
                        .frame(
                            width: size * (0.2 + CGFloat(index) * 0.15),
                            height: size * (0.2 + CGFloat(index) * 0.15)
                        )
                        .scaleEffect(1.0 + waveOffset * CGFloat(index + 1) * 0.1)
                        .opacity(1.0 - waveOffset * 0.5)
                }
                
                // 设备图标
                RoundedRectangle(cornerRadius: size * 0.05)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: size * 0.05)
                            .stroke(BrandColor.outline.opacity(0.3), lineWidth: 2)
                    )
                    .frame(width: size * 0.3, height: size * 0.2)
                    .offset(x: deviceShake)
                    .animation(
                        .easeInOut(duration: 0.1)
                            .repeatCount(3, autoreverses: true)
                            .delay(2.0)
                            .repeatForever(autoreverses: false),
                        value: deviceShake
                    )
            }
            
            // 错误X标记
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: size * 0.15, weight: .bold))
                .foregroundColor(BrandColor.danger)
                .offset(x: size * 0.25, y: -size * 0.25)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                waveOffset = 1.0
            }
            deviceShake = size * 0.02
        }
    }
}

// MARK: - 辅助形状
struct Cloud: Shape {
    let size: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        path.addEllipse(in: CGRect(x: 0, y: height * 0.4, width: width * 0.5, height: height * 0.6))
        path.addEllipse(in: CGRect(x: width * 0.2, y: height * 0.2, width: width * 0.6, height: height * 0.6))
        path.addEllipse(in: CGRect(x: width * 0.5, y: height * 0.4, width: width * 0.5, height: height * 0.6))
        
        return path
    }
}

// MARK: - 预设空状态组件
struct CuteEmptyCalendarView: View {
    var body: some View {
        AnimatedEmptyStateView(
            type: .emptyCalendar,
            message: "这天空空的，要不要加点料？ 🎯",
            size: 100
        )
    }
}

struct CuteNoEventsView: View {
    var body: some View {
        AnimatedEmptyStateView(
            type: .noEvents,
            message: "暂时没有安排，享受这难得的自由时光吧！ ✨",
            size: 100
        )
    }
}

struct CuteAllCompletedView: View {
    var body: some View {
        AnimatedEmptyStateView(
            type: .allCompleted,
            message: "哇！今天的任务都完成了，你真棒！🎉",
            size: 100
        )
    }
}

// MARK: - Preview
#Preview("空状态动画") {
    ScrollView {
        VStack(spacing: 40) {
            CuteEmptyCalendarView()
            CuteNoEventsView() 
            CuteAllCompletedView()
            
            AnimatedEmptyStateView(
                type: .loading,
                message: "正在同步数据...",
                size: 80
            )
            
            AnimatedEmptyStateView(
                type: .noConnection,
                message: "网络似乎有点问题，请检查网络连接",
                size: 100
            )
        }
        .padding()
    }
    .background(BrandColor.background)
}