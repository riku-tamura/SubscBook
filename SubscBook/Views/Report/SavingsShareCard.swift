import SwiftUI

/// SNS 共有用の節約レポート画像。サービス名は載せず、金額と件数だけを表示する。
struct SavingsShareCard: View {
    let savings: SavingsSummary

    static let size = CGSize(width: 360, height: 360)

    /// `ImageRenderer` で画像にする（1080×1080 px）
    static func render(savings: SavingsSummary) -> Image? {
        let renderer = ImageRenderer(
            content: SavingsShareCard(savings: savings)
                .environment(\.locale, .japanese)
                .environment(\.colorScheme, .light)
        )
        renderer.scale = 3
        return renderer.uiImage.map { Image(uiImage: $0) }
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("サブスク見張り番")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white.opacity(0.9))

            Spacer(minLength: 0)

            Text("サブスクを見直して")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white.opacity(0.9))
            Text("年間 \(savings.annualSavings.yenText)")
                .font(.system(size: 44, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Text("節約しました")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)

            Spacer(minLength: 0)

            Text("解約したサブスク \(savings.canceledCount)件")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.9))
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(.white.opacity(0.18), in: .capsule)
        }
        .padding(28)
        .frame(width: Self.size.width, height: Self.size.height)
        .background(
            LinearGradient(
                colors: [Color(red: 0.06, green: 0.51, blue: 0.38), Color(red: 0.04, green: 0.33, blue: 0.29)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

#Preview {
    SavingsShareCard(savings: SavingsSummary(annualSavings: 38_496, realizedSavings: 6_420, canceledCount: 3))
}
