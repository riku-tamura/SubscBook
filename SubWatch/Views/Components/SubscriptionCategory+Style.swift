import SwiftUI

extension SubscriptionCategory {
    /// カテゴリの表示色。頭文字アイコンの背景に使うため、白文字が読める濃さにしている。
    var color: Color {
        switch self {
        case .video: Color(hex: 0xD93A40)
        case .music: Color(hex: 0xC83C8E)
        case .reading: Color(hex: 0xA8651F)
        case .game: Color(hex: 0x8E4EC6)
        case .cloud: Color(hex: 0x0B7BD6)
        case .work: Color(hex: 0x3E63DD)
        case .fitness: Color(hex: 0x218358)
        case .learning: Color(hex: 0x0D7D71)
        case .news: Color(hex: 0x5B6B7A)
        case .other: Color(hex: 0x6F7180)
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
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

#Preview("カテゴリ色") {
    List(SubscriptionCategory.allCases) { category in
        Label {
            Text(category.displayName)
        } icon: {
            Image(systemName: category.symbolName)
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(category.color, in: .rect(cornerRadius: 8))
        }
    }
}
