import SwiftUI

/// 前月分のチェックインが未回答のときのバナー
struct HomeCheckInBanner: View {
    let month: YearMonth
    let count: Int
    @Environment(AppRouter.self) private var router
    @ScaledMetric(relativeTo: .title2) private var iconSize: CGFloat = 44

    var body: some View {
        Button {
            router.isCheckInPresented = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "checklist")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: iconSize, height: iconSize)
                    .background(Color.accentColor, in: .circle)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(month.monthText)のチェックイン")
                        .font(.headline)
                    Text("\(count)件のサブスクを使ったか教えてください")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
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
