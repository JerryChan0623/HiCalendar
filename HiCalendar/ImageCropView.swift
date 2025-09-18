//
//  ImageCropView.swift
//  HiCalendar
//
//  Created on 2024. Image Crop Interface for Background
//

import SwiftUI

struct ImageCropView: View {
    let originalImage: UIImage
    @Binding var croppedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastScale: CGFloat = 1.0
    @State private var lastOffset: CGSize = .zero
    
    // 裁切框尺寸 - 完全匹配设备屏幕比例
    private var cropSize: CGSize {
        let screenBounds = UIScreen.main.bounds
        let screenWidth = screenBounds.width
        let screenHeight = screenBounds.height
        
        // 计算合适的裁剪框尺寸，保持屏幕比例但适合界面显示
        let cropWidth = screenWidth * 0.8
        let cropHeight = min(screenHeight * 0.6, cropWidth * (screenHeight / screenWidth))
        
        return CGSize(width: cropWidth, height: cropHeight)
    }
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    // 背景
                    Color.black.ignoresSafeArea()
                    
                    // 图片显示区域 - 居中布局
                    ZStack {
                        // 背景遮罩
                        Rectangle()
                            .fill(Color.black.opacity(0.5))
                            .ignoresSafeArea()
                        
                        // 裁切区域（透明）- 居中显示
                        Rectangle()
                            .frame(width: cropSize.width, height: cropSize.height)
                            .blendMode(.destinationOut)
                        
                        // 图片 - 限制在裁切区域内
                        Image(uiImage: originalImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: cropSize.width, height: cropSize.height)
                            .scaleEffect(scale)
                            .offset(offset)
                            .clipped()
                            .gesture(
                                SimultaneousGesture(
                                    // 缩放手势
                                    MagnificationGesture()
                                        .onChanged { value in
                                            scale = lastScale * value
                                        }
                                        .onEnded { _ in
                                            // 限制缩放范围
                                            scale = max(0.5, min(scale, 3.0))
                                            lastScale = scale
                                        },
                                    
                                    // 拖拽手势
                                    DragGesture()
                                        .onChanged { value in
                                            offset = CGSize(
                                                width: lastOffset.width + value.translation.width,
                                                height: lastOffset.height + value.translation.height
                                            )
                                        }
                                        .onEnded { _ in
                                            lastOffset = offset
                                        }
                                )
                            )
                        
                        // 裁切框边框
                        Rectangle()
                            .stroke(Color.white, lineWidth: 2)
                            .frame(width: cropSize.width, height: cropSize.height)
                        
                        // 角标指示器
                        VStack {
                            HStack {
                                cornerIndicator
                                Spacer()
                                cornerIndicator
                            }
                            Spacer()
                            HStack {
                                cornerIndicator
                                Spacer()
                                cornerIndicator
                            }
                        }
                        .frame(width: cropSize.width, height: cropSize.height)
                    }
                    .compositingGroup()
                    
                    // 操作提示
                    VStack {
                        Spacer()
                        Text(L10n.dragPinchAdjust)
                            .font(BrandFont.bodySmall)
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.bottom, 50)
                    }
                }
            }
            .navigationTitle(L10n.cropBackgroundImage)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L10n.cancelCrop) {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L10n.confirmCrop) {
                        cropImage()
                    }
                    .foregroundColor(BrandColor.primaryYellow)
                    .fontWeight(.bold)
                }
            }
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
    
    // 角标指示器
    private var cornerIndicator: some View {
        Rectangle()
            .fill(Color.white)
            .frame(width: 20, height: 3)
            .overlay(
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 3, height: 20)
            )
    }
    
    // 裁切图片 - 简化算法确保一致性
    private func cropImage() {
        // 直接渲染当前视图中看到的内容
        let renderer = UIGraphicsImageRenderer(size: cropSize)
        
        let croppedUIImage = renderer.image { context in
            // 计算图片的实际显示尺寸（使用aspectRatio(.fill)的逻辑）
            let imageSize = originalImage.size
            let imageAspect = imageSize.width / imageSize.height
            let cropAspect = cropSize.width / cropSize.height
            
            let displaySize: CGSize
            if imageAspect > cropAspect {
                // 图片更宽，以高度为准
                displaySize = CGSize(
                    width: cropSize.height * imageAspect * scale,
                    height: cropSize.height * scale
                )
            } else {
                // 图片更高，以宽度为准
                displaySize = CGSize(
                    width: cropSize.width * scale,
                    height: cropSize.width / imageAspect * scale
                )
            }
            
            // 计算图片绘制的中心点
            let drawRect = CGRect(
                x: (cropSize.width - displaySize.width) / 2 + offset.width,
                y: (cropSize.height - displaySize.height) / 2 + offset.height,
                width: displaySize.width,
                height: displaySize.height
            )
            
            // 绘制图片
            originalImage.draw(in: drawRect)
        }
        
        croppedImage = croppedUIImage
        dismiss()
    }
}

#Preview {
    ImageCropView(
        originalImage: UIImage(systemName: "photo")!,
        croppedImage: .constant(nil)
    )
}