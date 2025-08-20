# Cute Calendar · 开发速查（Neobrutalism 版）

面向开发的精简规范与示例，和 `Docs/cute-ui-demo.html` 保持同名 Token 对齐，便于 SwiftUI/前端复用。

## 1) 设计令牌（Design Tokens）
- **品牌主色**: `--color-primary-pink` #FFB6C1, `--color-primary-blue` #A3D8F4
- **辅色**: `--color-secondary-yellow` #FFF6B7, `--color-secondary-mint` #C1E1C1
- **语义色**: `--color-success` #8BD9A3, `--color-warning` #F9D162, `--color-danger` #FF9AA2
- **灰阶**: `--neutral-900` #1F2937 → `--neutral-100` #F5F7FA
- **边框（Neobrutalism）**:
  - `BrandBorder.thin=1`, `regular=2`, `thick=3`
  - `BrandBorder.outline=neutral900`
- **渐变（可选，仅少量强调）**:
  - `pinkSoft/blueSoft` 作为背景可选，不强制
  - 主按钮优先使用扁平填充（pink/blue），如需强调可择一使用渐变
- **字体**: Display: Baloo 2（或同类圆润），Body: Nunito / 系统 .rounded
- **尺寸**: 间距 4/8/12/16/24/32；圆角：卡片 20，通用 12/16；按钮高度 44；描边 2pt；无阴影

## 2) 语义映射与规范
- **冲突状态**:
  - 无冲突: success 绿
  - 软冲突: warning 黄
  - 硬冲突: danger 红
- **按钮**:
  - 主按钮（粉/蓝）: 胶囊、扁平填充、外描边 2pt、白字、h=44（可选强调：渐变）
  - 次按钮: 白底 + 外描边 2pt（outline=neutral900）、深色字
  - 幽灵按钮: 透明 + 虚线描边（2pt，dash 6/4）
  - 禁用: opacity 0.5
- **卡片**: 白底 + 外描边 2pt + 圆角 20（无阴影）
- **输入框**: 胶囊、白底 + 外描边 2pt，辅助文案 12/18 中性 500（无阴影）

## 3) 页面要点（与 PRD 对齐）
- 登录/注册: 圆润输入、胶囊主按钮、Apple 登录（胶囊）
- 首页（AI 对话）: 白底卡片 + 粗描边；最近事件卡片按冲突状态着色；无阴影
- 日历页: 仅月视图；当天/选中态使用粗描边高亮；事件小圆点用语义色；无阴影
- 事件详情: 白底卡片 + 粗描边；冲突状态条红/黄/绿；操作按钮为胶囊；无阴影
- 设置: 吐槽程度 Slider（可渐变轨道）、推送开关、时区显示

## 4) SwiftUI 令牌（示例）
将下列常量文件加入以便全局调用（文件名建议：`DesignTokens.swift`）。

```swift
import SwiftUI

enum BrandColor {
    static let primaryPink = Color(red: 1.0, green: 0.71, blue: 0.76)   // #FFB6C1
    static let primaryBlue = Color(red: 0.64, green: 0.85, blue: 0.96)  // #A3D8F4

    static let success = Color(red: 0.545, green: 0.851, blue: 0.639)   // #8BD9A3
    static let warning = Color(red: 0.976, green: 0.82, blue: 0.384)    // #F9D162
    static let danger  = Color(red: 1.0, green: 0.604, blue: 0.635)     // #FF9AA2

    static let neutral900 = Color(red: 0.122, green: 0.161, blue: 0.216) // #1F2937
    static let neutral100 = Color(red: 0.961, green: 0.969, blue: 0.98)  // #F5F7FA
}

enum BrandGradient {
    static let pinkSolid = LinearGradient(
        colors: [BrandColor.primaryPink, Color(red: 1.0, green: 0.777, blue: 0.812)],
        startPoint: .top, endPoint: .bottom)
    static let blueSolid = LinearGradient(
        colors: [BrandColor.primaryBlue, Color(red: 0.788, green: 0.914, blue: 1.0)],
        startPoint: .top, endPoint: .bottom)
    static let pinkSoft = LinearGradient(
        colors: [Color(red: 1.0, green: 0.909, blue: 0.933), .white],
        startPoint: .top, endPoint: .bottom)
    static let blueSoft = LinearGradient(
        colors: [Color(red: 0.918, green: 0.965, blue: 1.0), .white],
        startPoint: .top, endPoint: .bottom)
}

struct CapsuleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .frame(height: 44)
            .background(Color(red: 1.0, green: 0.71, blue: 0.76))
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(Color(red: 0.122, green: 0.161, blue: 0.216), lineWidth: 2)
            )
            .scaleEffect(configuration.isPressed ? 0.99 : 1)
    }
}

struct ConflictBadge: View {
    enum Status { case none, soft, hard }
    let status: Status
    var body: some View {
        let (bg, fg, text): (Color, Color, String) = {
            switch status {
            case .none: return (BrandColor.success.opacity(0.2), Color(red: 0.11, green: 0.43, blue: 0.27), "无冲突")
            case .soft: return (BrandColor.warning.opacity(0.2), Color(red: 0.51, green: 0.35, blue: 0.0), "软冲突")
            case .hard: return (BrandColor.danger.opacity(0.22), Color(red: 0.48, green: 0.12, blue: 0.17), "硬冲突")
            }
        }()
        return Text(text)
            .font(.system(size: 14, weight: .bold, design: .rounded))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(bg)
            .foregroundColor(fg)
            .clipShape(Capsule())
    }
}
```

使用示例：
```swift
VStack(spacing: 16) {
    Text("今天你有 2 个会 + 1 个摸鱼时段 🐣")
        .font(.system(size: 32, weight: .bold, design: .rounded))
        .frame(maxWidth: .infinity, alignment: .leading)

    HStack(spacing: 12) {
        Button("主按钮 · 粉") {}.buttonStyle(CapsuleButtonStyle(gradient: BrandGradient.pinkSolid))
        Button("主按钮 · 蓝") {}.buttonStyle(CapsuleButtonStyle(gradient: BrandGradient.blueSolid))
    }

    HStack(spacing: 8) {
        ConflictBadge(status: .none)
        ConflictBadge(status: .soft)
        ConflictBadge(status: .hard)
    }
}
.padding(24)
.background(Color.white)
.overlay(
  RoundedRectangle(cornerRadius: 20, style: .continuous)
    .stroke(Color(red: 0.122, green: 0.161, blue: 0.216), lineWidth: 2)
)
```

## 5) 前端/CSS 对齐
- 参考 `Docs/cute-ui-demo.html`，CSS 变量与 SwiftUI 常量命名保持相同语义（pinkSoft/blueSoft、success/warning/danger 等）。
- 需要 Web 预览时，直接打开该 HTML 即可快速对比样式。

## 6) 资源与路径
- HTML 演示: `Docs/cute-ui-demo.html`
- 本摘要: `Docs/README.md`

> 提示：移动端若未内置 Baloo 2/Nunito，请使用系统圆润字体（.rounded）作为降级方案，后续可按需打包字体资源。
