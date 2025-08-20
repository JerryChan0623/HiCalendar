//
//  SettingsView.swift
//  HiCalendar
//
//  Created on 2024. Cute Calendar AI 设置页
//

import SwiftUI
import PhotosUI

struct SettingsView: View {
    @StateObject private var backgroundManager = BackgroundImageManager.shared
    @State private var showingPhotoPicker = false
    @State private var selectedImage: UIImage?
    @State private var showingRemoveAlert = false
    @State private var showingCropView = false
    @State private var croppedImage: UIImage?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: BrandSpacing.xl) {
                    // 背景设置区域
                    backgroundSection
                }
                .padding(BrandSpacing.lg)
            }
            .background(Color.white.ignoresSafeArea())
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                // 设置导航栏返回按钮外观
                let appearance = UINavigationBarAppearance()
                appearance.configureWithTransparentBackground()
                appearance.backgroundColor = UIColor.clear
                appearance.shadowColor = UIColor.clear
                
                // 自定义返回按钮
                appearance.setBackIndicatorImage(
                    UIImage(systemName: "chevron.left")?.withTintColor(UIColor.black, renderingMode: .alwaysOriginal),
                    transitionMaskImage: UIImage(systemName: "chevron.left")?.withTintColor(UIColor.black, renderingMode: .alwaysOriginal)
                )
                
                UINavigationBar.appearance().standardAppearance = appearance
                UINavigationBar.appearance().scrollEdgeAppearance = appearance
                UINavigationBar.appearance().compactAppearance = appearance
            }
        }
        .sheet(isPresented: $showingPhotoPicker) {
            PhotoPickerView(selectedImage: $selectedImage)
        }
        .sheet(isPresented: $showingCropView) {
            if let image = selectedImage {
                ImageCropView(originalImage: image, croppedImage: $croppedImage)
            }
        }
        .onChange(of: selectedImage) { _, image in
            if let _ = image {
                // 选择图片后显示裁切界面
                showingCropView = true
            }
        }
        .onChange(of: croppedImage) { _, image in
            if let image = image {
                backgroundManager.saveBackgroundImage(image)
                // 清理临时状态
                selectedImage = nil
                croppedImage = nil
            }
        }
        .overlay(
            showingRemoveAlert ? 
            NeobrutalismAlert(
                title: "移除背景图片",
                message: "确定要移除当前的背景图片吗？",
                isPresented: $showingRemoveAlert
            ) {
                HStack(spacing: BrandSpacing.lg) {
                    Button("取消") {
                        showingRemoveAlert = false
                    }
                    .buttonStyle(AlertButtonStyle(isDestructive: false))
                    
                    Button("移除") {
                        backgroundManager.removeBackgroundImage()
                        showingRemoveAlert = false
                    }
                    .buttonStyle(AlertButtonStyle(isDestructive: true))
                }
            } : nil
        )
    }
    
    // MARK: - 背景设置区域
    private var backgroundSection: some View {
        CuteCard(backgroundColor: BrandSolid.cardWhite) {
            VStack(alignment: .leading, spacing: BrandSpacing.lg) {
                // 标题
                HStack {
                    Text("日历背景")
                        .font(BrandFont.body(size: 18, weight: .bold))
                        .foregroundColor(BrandColor.neutral900)
                    
                    Spacer()
                    
                    Image(systemName: "photo.on.rectangle")
                        .font(.title2)
                        .foregroundColor(BrandColor.primaryBlue)
                }
                
                // 当前背景预览
                if backgroundManager.hasCustomBackground, let image = backgroundManager.backgroundImage {
                    VStack(spacing: BrandSpacing.md) {
                        Text("当前背景")
                            .font(BrandFont.body(size: 14, weight: .medium))
                            .foregroundColor(BrandColor.neutral700)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 200)
                            .clipped()
                            .cornerRadius(BrandRadius.md)
                            .neobrutalStyle(cornerRadius: BrandRadius.md, borderWidth: BrandBorder.regular)
                        
                        // 移除按钮
                        Button("移除背景图片") {
                            showingRemoveAlert = true
                        }
                        .font(BrandFont.body(size: 14, weight: .medium))
                        .foregroundColor(BrandColor.danger)
                        .padding(.vertical, BrandSpacing.sm)
                        .padding(.horizontal, BrandSpacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: BrandRadius.sm)
                                .stroke(BrandColor.danger, lineWidth: BrandBorder.thin)
                        )
                    }
                } else {
                    VStack(spacing: BrandSpacing.md) {
                        Text("暂无自定义背景")
                            .font(BrandFont.body(size: 14, weight: .medium))
                            .foregroundColor(BrandColor.neutral500)
                        
                        RoundedRectangle(cornerRadius: BrandRadius.md)
                            .fill(BrandColor.neutral200)
                            .frame(height: 200)
                            .overlay(
                                VStack(spacing: BrandSpacing.sm) {
                                    Image(systemName: "photo")
                                        .font(.largeTitle)
                                        .foregroundColor(BrandColor.neutral500)
                                    Text("使用默认背景")
                                        .font(BrandFont.bodySmall)
                                        .foregroundColor(BrandColor.neutral500)
                                }
                            )
                            .neobrutalStyle(cornerRadius: BrandRadius.md, borderWidth: BrandBorder.regular)
                    }
                }
                
                // 上传按钮
                Button(action: {
                    showingPhotoPicker = true
                }) {
                    HStack(spacing: BrandSpacing.md) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                        
                        Text(backgroundManager.hasCustomBackground ? "更换背景图片" : "选择背景图片")
                            .font(BrandFont.body(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, BrandSpacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: BrandRadius.md)
                            .fill(BrandColor.primaryBlue)
                            .neobrutalStyle(cornerRadius: BrandRadius.md, borderWidth: BrandBorder.regular)
                    )
                }
                
                // 说明文字
                Text("选择一张图片作为日历的背景。系统将引导您裁切图片以获得最佳显示效果。建议使用清晰、色彩柔和的图片以确保文字可读性。")
                    .font(BrandFont.bodySmall)
                    .foregroundColor(BrandColor.neutral500)
                    .multilineTextAlignment(.leading)
            }
        }
    }
}

#Preview {
    SettingsView()
}

