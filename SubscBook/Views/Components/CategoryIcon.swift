import SwiftUI

/// サービス名の頭文字＋カテゴリ色のアイコン。他社ロゴは使わない。
struct CategoryIcon: View {
    let name: String
    let category: SubscriptionCategory
    @ScaledMetric private var scaledSize: CGFloat
    private let baseSize: CGFloat

    init(name: String, category: SubscriptionCategory, size: CGFloat = 40) {
        self.name = name
        self.category = category
        baseSize = size
        _scaledSize = ScaledMetric(wrappedValue: size, relativeTo: .body)
    }

    /// 文字の大きさに合わせて大きくするが、1.5倍まで（大きな文字で、文字の場所がなくならないように）
    private var size: CGFloat {
        min(scaledSize, baseSize * 1.5)
    }

    private var initial: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).first.map { String($0).uppercased() } ?? "?"
    }

    var body: some View {
        Text(initial)
            .font(.system(size: size * 0.45, weight: .bold, design: .rounded))
            .foregroundStyle(category.iconForeground)
            .frame(width: size, height: size)
            .background(category.color, in: .rect(cornerRadius: size * 0.26))
            .accessibilityHidden(true)
    }
}

#Preview {
    HStack {
        CategoryIcon(name: "Netflix", category: .video)
        CategoryIcon(name: "spotify", category: .music)
        CategoryIcon(name: "楽天マガジン", category: .reading)
        CategoryIcon(name: "", category: .other)
    }
}
