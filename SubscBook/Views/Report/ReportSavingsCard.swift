import SwiftUI

/// 年間節約額・節約累計と、SNS 共有用の画像（サブスク帳プラス）
struct ReportSavingsCard: View {
    let savings: SavingsSummary
    let shareImage: Image?
    @Environment(EntitlementManager.self) private var entitlements

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CardHeader(title: "年間節約レポート", systemImage: "chart.line.uptrend.xyaxis", tint: .green)
            Group {
                if savings.hasSavings {
                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("解約で浮くお金（1年あたり）")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(savings.annualSavings.yenText)
                                .font(.system(.largeTitle, design: .rounded).weight(.bold))
                                .monospacedDigit()
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                                .foregroundStyle(.green)
                        }
                        .accessibilityElement(children: .combine)
                        Text(savings.realizedSavings > 0
                             ? "\(savings.canceledCount)件のサブスクを解約し、これまでに\(savings.realizedSavings.yenText)を節約しました。"
                             : "\(savings.canceledCount)件のサブスクを解約しました。これから毎月、節約した金額が積み上がっていきます。")
                            .font(.subheadline)
                        if let shareImage {
                            ShareLink(
                                item: shareImage,
                                preview: SharePreview("サブスク帳の節約レポート", image: shareImage)
                            ) {
                                Label("画像でシェア", systemImage: "square.and.arrow.up")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                } else {
                    Text("解約したサブスクはまだありません。「解約した」を記録すると、節約額をここにまとめます。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .premiumLocked(!entitlements.isPremium, feature: .savingsReport)
        }
        .card()
    }
}
