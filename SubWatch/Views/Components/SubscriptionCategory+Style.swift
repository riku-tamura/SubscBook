import SwiftUI
import UIKit

extension SubscriptionCategory {
    /// カテゴリの表示色。ライト・ダークそれぞれの背景で色覚多様性に配慮して検証した配色。
    /// 隣り合うカテゴリ（allCases の順）が見分けやすい並びにしてあるので、グラフもこの順で描く。
    /// 9色目以降は見分けにくくなるため、グラフでは必ず凡例（名前と金額）を併記する。
    var color: Color {
        switch self {
        case .video: Color(light: 0x2A78D6, dark: 0x3987E5)
        case .music: Color(light: 0xEB6834, dark: 0xD95926)
        case .reading: Color(light: 0x1BAF7A, dark: 0x199E70)
        case .game: Color(light: 0xEDA100, dark: 0xC98500)
        case .cloud: Color(light: 0xE87BA4, dark: 0xD55181)
        case .work: Color(light: 0x008300, dark: 0x008300)
        case .fitness: Color(light: 0x4A3AA7, dark: 0x9085E9)
        case .learning: Color(light: 0xE34948, dark: 0xE66767)
        case .news: Color(light: 0x0891B2, dark: 0x22A3C4)
        case .other: Color(light: 0x5C5C59, dark: 0x6B6B68)
        }
    }

    /// 頭文字アイコンの文字色。背景色に対して読める方（白または黒）を選んである。
    var iconForeground: Color {
        switch self {
        case .reading, .game, .cloud:
            Color(light: 0x111111, dark: 0x111111)
        case .fitness, .news:
            Color(light: 0xFFFFFF, dark: 0x111111)
        case .video, .music, .work, .learning, .other:
            Color(light: 0xFFFFFF, dark: 0xFFFFFF)
        }
    }

    /// カテゴリを表す SF Symbol
    var symbolName: String {
        switch self {
        case .video: "play.rectangle.fill"
        case .music: "music.note"
        case .reading: "book.fill"
        case .game: "gamecontroller.fill"
        case .cloud: "icloud.fill"
        case .work: "briefcase.fill"
        case .fitness: "figure.run"
        case .learning: "graduationcap.fill"
        case .news: "newspaper.fill"
        case .other: "square.grid.2x2.fill"
        }
    }
}

private extension Color {
    /// ライト・ダークで切り替わる色
    init(light: UInt32, dark: UInt32) {
        self.init(UIColor { traits in
            UIColor(hex: traits.userInterfaceStyle == .dark ? dark : light)
        })
    }
}

private extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}

#Preview("カテゴリ色") {
    List(SubscriptionCategory.allCases) { category in
        Label {
            Text(category.displayName)
        } icon: {
            Text(String(category.displayName.prefix(1)))
                .font(.headline)
                .foregroundStyle(category.iconForeground)
                .frame(width: 32, height: 32)
                .background(category.color, in: .rect(cornerRadius: 8))
        }
    }
}
