import SwiftUI

/// 前月分のチェックインが未回答のときのバナー
struct HomeCheckInBanner: View {
    let month: YearMonth
    let count: Int
    @Environment(AppRouter.self) private var router
    @ScaledMetric(relativeTo: .title2) private var scaledIconSize: CGFloat = 44
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// 1.5倍まで（大きな文字で、文字の場所がなくならないように）
    private var iconSize: CGFloat { min(scaledIconSize, 66) }

    var body: some View {
        Button {
            router.isCheckInPresented = true
        } label: {
            IconLabelStack {
                Image(systemName: "checklist")
                    // 丸の大きさに合わせる（文字の大きさに任せると、大きな文字で丸からはみ出す）
                    .font(.system(size: iconSize * 0.5))
                    .foregroundStyle(.white)
                    .frame(width: iconSize, height: iconSize)
                    .background(Color.accentColor, in: .circle)
                    .accessibilityHidden(true)
            } label: {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(month.monthText)のチェックイン")
                            .font(.headline)
                        Text("\(count)件のサブスクを使ったか教えてください")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                    // 大きな文字では、文字の幅を優先して矢印を省く
                    if !dynamicTypeSize.isAccessibilitySize {
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.tertiary)
                            .accessibilityHidden(true)
                    }
                }
            }
            .card()
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.accentColor.opacity(0.4), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityHint("月次チェックインを始めます")
    }
}
