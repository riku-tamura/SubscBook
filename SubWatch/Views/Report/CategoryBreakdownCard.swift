import Charts
import SwiftUI

/// カテゴリ別の円グラフと、名前・金額・割合の凡例（凡例が表の役割も兼ねる）
struct CategoryBreakdownCard: View {
    let slices: [CategorySlice]
    let monthlyTotal: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            CardHeader(title: "カテゴリ別（月額換算）", systemImage: "chart.pie.fill")

            Chart(slices) { slice in
                SectorMark(
                    angle: .value("月額", slice.monthlyTotal),
                    innerRadius: .ratio(0.62),
                    angularInset: 1.5
                )
                .cornerRadius(4)
                .foregroundStyle(slice.category.color)
                .accessibilityLabel(slice.category.displayName)
                .accessibilityValue("\(slice.monthlyTotal.yenText)、\(percentText(slice.share))")
            }
            .chartLegend(.hidden)
            .chartBackground { proxy in
                GeometryReader { geometry in
                    if let plotFrame = proxy.plotFrame {
                        let frame = geometry[plotFrame]
                        VStack(spacing: 2) {
                            Text("合計")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(monthlyTotal.yenText)
                                .font(.headline)
                                .monospacedDigit()
                        }
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .frame(width: frame.width * 0.5)
                        .position(x: frame.midX, y: frame.midY)
                        .accessibilityHidden(true)
                    }
                }
            }
            .frame(height: 220)

            VStack(spacing: 10) {
                ForEach(slices) { slice in
                    legendRow(slice)
                }
            }
        }
        .card()
    }

    private func legendRow(_ slice: CategorySlice) -> some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 3)
                .fill(slice.category.color)
                .frame(width: 12, height: 12)
                .accessibilityHidden(true)
            Text(slice.category.displayName)
            Text("\(slice.count)件")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Spacer(minLength: 8)
            Text(slice.monthlyTotal.yenText)
                .monospacedDigit()
            Text(percentText(slice.share))
                .font(.footnote.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(minWidth: 40, alignment: .trailing)
        }
        .font(.subheadline)
        .accessibilityElement(children: .combine)
    }

    private func percentText(_ share: Double) -> String {
        share.formatted(.percent.precision(.fractionLength(0)).locale(.japanese))
    }
}
