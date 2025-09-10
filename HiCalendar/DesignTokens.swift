//
//  DesignTokens.swift
//  HiCalendar
//
//  Created on 2024. Material Design 3 Design Tokens
//

import SwiftUI
import UIKit

// MARK: - Brand Colors (Ocean Blue Theme - Based on Logo)
enum BrandColor {
    // Primary colors - 基于 Logo 的海洋蓝色系
    static let primary = Color(uiColor: UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.529, green: 0.729, blue: 0.957, alpha: 1.0)    // #87BAF4 - 亮蓝
            : UIColor(red: 0.259, green: 0.522, blue: 0.784, alpha: 1.0)    // #4285C8 - 主蓝
    })
    
    static let onPrimary = Color(uiColor: UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.098, green: 0.204, blue: 0.341, alpha: 1.0)    // #193457 - 深蓝
            : UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)          // #FFFFFF
    })
    
    static let primaryContainer = Color(uiColor: UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.157, green: 0.318, blue: 0.522, alpha: 1.0)    // #285185 - 中深蓝
            : UIColor(red: 0.878, green: 0.933, blue: 0.988, alpha: 1.0)    // #E0EEFC - 极浅蓝
    })
    
    static let onPrimaryContainer = Color(uiColor: UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.878, green: 0.933, blue: 0.988, alpha: 1.0)    // #E0EEFC - 极浅蓝
            : UIColor(red: 0.071, green: 0.188, blue: 0.337, alpha: 1.0)    // #123056 - 深海蓝
    })
    
    // Secondary colors - 天空蓝补充色
    static let secondary = Color(uiColor: UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.667, green: 0.816, blue: 0.929, alpha: 1.0)    // #AAD0ED - 浅天蓝
            : UIColor(red: 0.353, green: 0.616, blue: 0.796, alpha: 1.0)    // #5A9DCB - 天蓝
    })
    
    static let onSecondary = Color(uiColor: UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.133, green: 0.259, blue: 0.376, alpha: 1.0)    // #224260 - 暗蓝
            : UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)          // #FFFFFF
    })
    
    static let secondaryContainer = Color(uiColor: UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.220, green: 0.388, blue: 0.529, alpha: 1.0)    // #386387 - 中蓝
            : UIColor(red: 0.922, green: 0.957, blue: 0.988, alpha: 1.0)    // #EBF4FC - 雾蓝
    })
    
    static let onSecondaryContainer = Color(uiColor: UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.922, green: 0.957, blue: 0.988, alpha: 1.0)    // #EBF4FC - 雾蓝
            : UIColor(red: 0.094, green: 0.227, blue: 0.361, alpha: 1.0)    // #183A5C - 深天蓝
    })
    
    // Surface colors - 海洋主题表面色
    static let surface = Color(uiColor: UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.086, green: 0.133, blue: 0.188, alpha: 1.0)  // #16222F - 深海色
            : UIColor(red: 0.988, green: 0.992, blue: 1.0, alpha: 1.0)    // #FCFDFF - 云白色
    })
    
    static let surfaceVariant = Color(uiColor: UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.157, green: 0.227, blue: 0.298, alpha: 1.0)  // #283A4C - 深海蓝灰
            : UIColor(red: 0.922, green: 0.949, blue: 0.976, alpha: 1.0)  // #EBF2F9 - 浅蓝灰
    })
    
    static let onSurface = Color(uiColor: UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.902, green: 0.882, blue: 0.898, alpha: 1.0)  // #E6E1E5
            : UIColor(red: 0.110, green: 0.106, blue: 0.122, alpha: 1.0)  // #1C1B1F
    })
    
    // Outline colors
    static let outline = Color(uiColor: UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.576, green: 0.561, blue: 0.600, alpha: 1.0)  // #938F99
            : UIColor(red: 0.475, green: 0.455, blue: 0.494, alpha: 1.0)  // #79747E
    })
    
    static let outlineVariant = Color(uiColor: UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.286, green: 0.271, blue: 0.310, alpha: 1.0)  // #49454F
            : UIColor(red: 0.792, green: 0.769, blue: 0.816, alpha: 1.0)  // #CAC4D0
    })
    
    // Background - 海洋主题背景（优化暗黑模式对比度）
    static let background = Color(uiColor: UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.043, green: 0.086, blue: 0.129, alpha: 1.0)  // #0B1621 - 更深的夜海
            : UIColor(red: 0.973, green: 0.980, blue: 0.992, alpha: 1.0)  // #F8FAFD - 天空白
    })
    
    // Error colors
    static let error = Color(uiColor: UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 1.0, green: 0.706, blue: 0.671, alpha: 1.0)    // #FFB4AB
            : UIColor(red: 0.729, green: 0.102, blue: 0.102, alpha: 1.0)  // #BA1A1A
    })
    
    static let errorContainer = Color(uiColor: UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.576, green: 0.0, blue: 0.039, alpha: 1.0)    // #93000A
            : UIColor(red: 1.0, green: 0.855, blue: 0.839, alpha: 1.0)    // #FFDAD6
    })
    
    // Semantic colors (保留用于向后兼容)
    static let success = Color(red: 0.0, green: 0.7, blue: 0.0)
    static let warning = Color(red: 1.0, green: 0.6, blue: 0.0)
    static let danger = error
    
    // onSurfaceVariant - 用于次要文本和图标
    static let onSurfaceVariant = Color(uiColor: UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.792, green: 0.769, blue: 0.816, alpha: 1.0)  // #CAC4D0
            : UIColor(red: 0.286, green: 0.271, blue: 0.310, alpha: 1.0)  // #49454F
    })
    
    // 向后兼容的中性色
    static let neutral900 = onSurface
    static let neutral700 = onSurface.opacity(0.8)
    static let neutral500 = outline
    static let neutral300 = outlineVariant
    static let neutral200 = surfaceVariant
    static let neutral100 = surface
    
    // 原品牌色保留（可用于特殊场景）- 更新为海洋主题
    static let primaryYellow = Color(red: 1.0, green: 0.882, blue: 0.616)  // 沙滩黄 #FFE19D
    static let primaryBlue = primary                                       // 使用主色调
    static let secondaryGreen = Color(red: 0.4, green: 0.8, blue: 0.4)     // 柔和绿
    static let secondaryRed = errorContainer
}

// MARK: - Material Design 3 Elevations
enum BrandElevation {
    static let level0 = (shadowRadius: 0.0, shadowOpacity: 0.0)
    static let level1 = (shadowRadius: 3.0, shadowOpacity: 0.04)
    static let level2 = (shadowRadius: 6.0, shadowOpacity: 0.08)
    static let level3 = (shadowRadius: 12.0, shadowOpacity: 0.12)
    static let level4 = (shadowRadius: 16.0, shadowOpacity: 0.16)
    static let level5 = (shadowRadius: 24.0, shadowOpacity: 0.20)
}

// MARK: - Typography (Material Design 3)
enum BrandFont {
    // Display - 用于大标题
    static func display(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
    
    // Headline - 用于页面标题
    static func headline(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
    
    // Title - 用于卡片标题
    static func title(size: CGFloat, weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
    
    // Body - 用于正文
    static func body(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
    
    // Label - 用于标签和按钮
    static func label(size: CGFloat, weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
    
    // 预设尺寸 - Material Design 3 规范
    static let displayLarge = display(size: 57, weight: .regular)
    static let displayMedium = display(size: 45, weight: .regular)
    static let displaySmall = display(size: 36, weight: .regular)
    
    static let headlineLarge = headline(size: 32, weight: .regular)
    static let headlineMedium = headline(size: 28, weight: .regular)
    static let headlineSmall = headline(size: 24, weight: .regular)
    
    static let titleLarge = title(size: 22, weight: .medium)
    static let titleMedium = title(size: 16, weight: .medium)
    static let titleSmall = title(size: 14, weight: .medium)
    
    static let bodyLarge = body(size: 16, weight: .regular)
    static let bodyMedium = body(size: 14, weight: .regular)
    static let bodySmall = body(size: 12, weight: .regular)
    
    static let labelLarge = label(size: 14, weight: .medium)
    static let labelMedium = label(size: 12, weight: .medium)
    static let labelSmall = label(size: 11, weight: .medium)
}

// MARK: - Spacing & Sizing (Material Design 3)
enum BrandSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - Corner Radius (Material Design 3)
enum BrandRadius {
    static let extraSmall: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let extraLarge: CGFloat = 28
    static let card: CGFloat = 16      // MD3 推荐的卡片圆角
    static let pill: CGFloat = 999     // 胶囊形状
}

enum BrandSize {
    static let buttonHeight: CGFloat = 44
    static let inputHeight: CGFloat = 56   // MD3 推荐的输入框高度
    static let iconSm: CGFloat = 18
    static let iconMd: CGFloat = 24
    static let iconLg: CGFloat = 32
    static let fabSize: CGFloat = 56       // FAB 按钮尺寸
}

// MARK: - Borders (简化为 MD3 风格)
enum BrandBorder {
    static let thin: CGFloat = 1
    static let regular: CGFloat = 1        // MD3 使用细边框
    static let thick: CGFloat = 2
    static let outline: Color = BrandColor.outline
}

// MARK: - Shadows (Material Design 3 风格)
enum BrandShadow {
    // MD3 柔和阴影
    static let small = (radius: 3.0, opacity: 0.04, y: 2.0)
    static let medium = (radius: 6.0, opacity: 0.08, y: 4.0)
    static let large = (radius: 12.0, opacity: 0.12, y: 8.0)
    
    // 保留硬阴影以备用（但不推荐使用）
    static let hardSmall = (offset: CGSize(width: 2, height: 2), color: BrandColor.outline.opacity(0.2))
    static let hardMedium = (offset: CGSize(width: 4, height: 4), color: BrandColor.outline.opacity(0.2))
    static let hardLarge = (offset: CGSize(width: 6, height: 6), color: BrandColor.outline.opacity(0.2))
}

// MARK: - Solid Backgrounds (Material Design 3)
enum BrandSolid {
    static let primaryBackground = BrandColor.primaryContainer
    static let secondaryBackground = BrandColor.secondaryContainer
    static let errorBackground = BrandColor.errorContainer
    
    // 卡片背景
    static let cardWhite = BrandColor.surface
    static let cardElevated = BrandColor.surface
    
    // 主背景色
    static let background = BrandColor.background
    
    // 向后兼容
    static let yellowBackground = BrandColor.primaryContainer
    static let blueBackground = BrandColor.primaryContainer
    static let greenBackground = BrandColor.secondaryContainer
    static let redBackground = BrandColor.errorContainer
    static let cardGray = BrandColor.surfaceVariant
}

// MARK: - View Extensions (Material Design 3)
extension View {
    // MD3 Surface 效果
    func md3Surface(elevation: (shadowRadius: Double, shadowOpacity: Double) = BrandElevation.level1,
                    cornerRadius: CGFloat = BrandRadius.md) -> some View {
        self
            .background(BrandColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: Color.black.opacity(elevation.shadowOpacity),
                   radius: elevation.shadowRadius,
                   x: 0,
                   y: elevation.shadowRadius / 2)
    }
    
    // MD3 Card 效果
    func md3Card(elevation: (shadowRadius: Double, shadowOpacity: Double) = BrandElevation.level1) -> some View {
        self
            .padding(BrandSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .md3Surface(elevation: elevation, cornerRadius: BrandRadius.card)
    }
    
    // MD3 Outlined Card
    func md3OutlinedCard() -> some View {
        self
            .padding(BrandSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(BrandColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: BrandRadius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: BrandRadius.card, style: .continuous)
                    .stroke(BrandColor.outline, lineWidth: BrandBorder.regular)
            )
    }
    
    // 保留原有的 neobrutal 方法以保持向后兼容
    func neobrutalOutline(cornerRadius: CGFloat,
                          lineWidth: CGFloat = BrandBorder.regular,
                          color: Color = BrandBorder.outline) -> some View {
        overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(color, lineWidth: lineWidth)
        )
    }
    
    func neobrutalShadow(_ shadow: (offset: CGSize, color: Color) = BrandShadow.hardMedium) -> some View {
        background(
            RoundedRectangle(cornerRadius: 0)
                .fill(shadow.color)
                .offset(shadow.offset)
        )
    }
    
    func neobrutalStyle(cornerRadius: CGFloat,
                        borderWidth: CGFloat = BrandBorder.regular,
                        borderColor: Color = BrandBorder.outline) -> some View {
        self
            .neobrutalOutline(cornerRadius: cornerRadius, lineWidth: borderWidth, color: borderColor)
    }
}