import SwiftUI

/// 月額合計・年額合計・契約件数のカード（ホーム・レポート共通）
struct TotalsCard: View {
    var title = "毎月の支払い（月額換算）"
    let monthlyTotal: Int
    let annualTotal: Int
    let activeCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CardHeader(title: title, systemImage: "yensign.circle.fill")
            Text(monthlyTotal.yenText)
                .font(.system(.largeTitle, design: .rounded).weight(.bold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .accessibilityLabel("月額換算で\(monthlyTotal.yenText)")
            Divider()
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 24) { stats }
                VStack(alignment: .leading, spacing: 8) { stats }
            }
        }
        .card()
    }

    @ViewBuilder
    private var stats: some View {
        stat(title: "年間", value: annualTotal.yenText)
        stat(title: "契約中", value: "\(activeCount)件")
    }

    private func stat(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.weight(.semibold))
                .monospacedDigit()
        }
        .accessibilityElement(children: .combine)
    }
}
