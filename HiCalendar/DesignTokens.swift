//
//  DesignTokens.swift
//  HiCalendar
//
//  Created on 2024. Neobrutalism Design Tokens
//

import SwiftUI
import UIKit

// MARK: - Brand Colors (Neobrutalism with Dark Mode Support)
enum BrandColor {
    // 品牌主色 - 大胆鲜艳 (在暗黑模式下保持一致)
    static let primaryYellow = Color(red: 1.0, green: 1.0, blue: 0.0)    // #FFFF00 鲜艳黄
    static let primaryBlue = Color(red: 0.0, green: 0.75, blue: 1.0)     // #00BFFF 电光蓝
    
    // 辅色 - 高饱和度 (在暗黑模式下保持一致)
    static let secondaryGreen = Color(red: 0.224, green: 1.0, blue: 0.078) // #39FF14 霓虹绿
    static let secondaryRed = Color(red: 1.0, green: 0.027, blue: 0.227)   // #FF073A 警示红
    
    // 语义色 - 纯色高对比 (在暗黑模式下保持一致)
    static let success = Color(red: 0.0, green: 1.0, blue: 0.0)          // #00FF00 纯绿
    static let warning = Color(red: 1.0, green: 0.549, blue: 0.0)        // #FF8C00 橙色
    static let danger  = Color(red: 1.0, green: 0.0, blue: 0.0)          // #FF0000 纯红
    
    // 动态中性色 - 支持亮色/暗色模式
    static let neutral900 = Color(uiColor: UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark 
            ? UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)     // 暗色模式: #FFFFFF 纯白
            : UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)     // 亮色模式: #000000 纯黑
    })
    
    static let neutral700 = Color(uiColor: UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark 
            ? UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1.0)     // 暗色模式: #CCCCCC 浅灰
            : UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)     // 亮色模式: #333333 深灰
    })
    
    static let neutral500 = Color(red: 0.5, green: 0.5, blue: 0.5)     // #808080 中灰 (在两种模式下保持一致)
    
    static let neutral300 = Color(uiColor: UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark 
            ? UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)     // 暗色模式: #333333 深灰
            : UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1.0)     // 亮色模式: #CCCCCC 浅灰
    })
    
    static let neutral200 = Color(uiColor: UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark 
            ? UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)     // 暗色模式: #1A1A1A 很深灰
            : UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)     // 亮色模式: #E6E6E6 很浅灰
    })
    
    static let neutral100 = Color(uiColor: UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark 
            ? UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)     // 暗色模式: #000000 纯黑
            : UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)     // 亮色模式: #FFFFFF 纯白
    })
}

// MARK: - Brand Solid Colors (替代渐变，支持暗黑模式)
enum BrandSolid {
    // 主要背景色 - Neobrutalism 不使用渐变，改为纯色
    static let yellowBackground = BrandColor.primaryYellow
    static let blueBackground = BrandColor.primaryBlue
    static let greenBackground = BrandColor.secondaryGreen
    static let redBackground = BrandColor.secondaryRed
    
    // 卡片背景色 - 动态适配暗黑模式
    static let cardWhite = BrandColor.neutral100
    static let cardGray = BrandColor.neutral200
    
    // 主背景色 - 页面级背景
    static let background = Color(uiColor: UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark 
            ? UIColor(red: 0.05, green: 0.05, blue: 0.05, alpha: 1.0)  // 暗色模式: #0D0D0D 深黑背景
            : UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0)  // 亮色模式: #F2F2F2 浅灰背景
    })
}

// MARK: - Typography (Neobrutalism)
enum BrandFont {
    // 标题字体 - 硬朗无衬线
    static func display(size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
    
    // 正文字体 - 硬朗无衬线
    static func body(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
    
    // 预设尺寸 - 增强对比度
    static let displayLarge = display(size: 32, weight: .black)    // 32/40 加粗
    static let displayMedium = display(size: 24, weight: .heavy)   // 24/32 加粗
    static let headlineSmall = display(size: 18, weight: .bold)    // 18/28
    
    static let bodyLarge = body(size: 16, weight: .semibold)       // 16/24 加粗
    static let bodyMedium = body(size: 14, weight: .medium)        // 14/20
    static let bodySmall = body(size: 12, weight: .medium)         // 12/18
}

// MARK: - Spacing & Sizing
enum BrandSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
}

enum BrandRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let card: CGFloat = 20
    static let pill: CGFloat = 999  // 胶囊形状
}

enum BrandSize {
    static let buttonHeight: CGFloat = 44
    static let inputHeight: CGFloat = 48
    static let iconSm: CGFloat = 16
    static let iconMd: CGFloat = 24
    static let iconLg: CGFloat = 32
}

// MARK: - Neobrutalism Border & Shadow Tokens (支持暗黑模式)
enum BrandBorder {
    static let thin: CGFloat = 2
    static let regular: CGFloat = 3
    static let thick: CGFloat = 4
    static let extraThick: CGFloat = 5
    static let outline: Color = BrandColor.neutral900  // 动态边框颜色
}

enum BrandShadow {
    // Neobrutalism 硬阴影效果
    static let hardSmall = (offset: CGSize(width: 2, height: 2), color: BrandColor.neutral900)
    static let hardMedium = (offset: CGSize(width: 4, height: 4), color: BrandColor.neutral900)
    static let hardLarge = (offset: CGSize(width: 6, height: 6), color: BrandColor.neutral900)
}



// MARK: - View Extensions
extension View {
    // Neobrutalism 外描边工具
    func neobrutalOutline(cornerRadius: CGFloat,
                          lineWidth: CGFloat = BrandBorder.regular,
                          color: Color = BrandBorder.outline) -> some View {
        overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(color, lineWidth: lineWidth)
        )
    }
    
    // Neobrutalism 硬阴影效果
    func neobrutalShadow(_ shadow: (offset: CGSize, color: Color) = BrandShadow.hardMedium) -> some View {
        background(
            RoundedRectangle(cornerRadius: 0)
                .fill(shadow.color)
                .offset(shadow.offset)
        )
    }
    
    // 组合效果：仅边框（移除阴影）
    func neobrutalStyle(cornerRadius: CGFloat,
                        borderWidth: CGFloat = BrandBorder.regular,
                        borderColor: Color = BrandBorder.outline) -> some View {
        self
            .neobrutalOutline(cornerRadius: cornerRadius, lineWidth: borderWidth, color: borderColor)
    }
}
