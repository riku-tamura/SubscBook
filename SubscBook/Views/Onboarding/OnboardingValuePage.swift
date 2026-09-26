import SwiftUI

/// オンボーディング 1ページ目：価値の説明
struct OnboardingValuePage: View {
    let onNext: () -> Void

    var body: some View {
        OnboardingPageLayout(
            systemImage: "text.book.closed.fill",
            title: "あなたのサブスク、\n見張ります",
            primaryTitle: "はじめる",
            primaryAction: onNext
        ) {
            VStack(alignment: .leading, spacing: 16) {
                point("calendar.badge.clock", "支払日の前日にお知らせ")
                point("chart.pie.fill", "毎月・毎年の合計がひと目でわかる")
                point("scissors", "使っていないサブスクを見つける")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .card()

            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "lock.shield.fill")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text("データは端末の外に出ません")
                        .font(.headline)
                    Text("登録したサブスクもAIの分析も、すべてこの端末の中だけで完結します。外部のサーバーには送信しません。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .card()
            .accessibilityElement(children: .combine)
        }
    }

    private func point(_ systemImage: String, _ text: String) -> some View {
        Label {
            Text(text)
                .font(.body.weight(.medium))
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(Color.accentColor)
        }
    }
}
