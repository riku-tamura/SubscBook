import SwiftUI

/// サブスク帳プラスの機能であることを示す小さなバッジ
struct PlusBadge: View {
    var body: some View {
        Label("プラス", systemImage: "lock.fill")
            .labelStyle(.titleAndIcon)
            .font(.caption2.weight(.bold))
            .foregroundStyle(Color.accentColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.accentColor.opacity(0.12), in: .capsule)
            .accessibilityLabel("サブスク帳プラス")
    }
}
