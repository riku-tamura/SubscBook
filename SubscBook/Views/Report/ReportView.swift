import SwiftData
import SwiftUI

/// ⑥ 振り返りレポート
struct ReportView: View {
    @Query private var subscriptions: [Subscription]
    @State private var viewModel = ReportViewModel()
    @Environment(EntitlementManager.self) private var entitlements
    @Environment(InsightProvider.self) private var insights

    var body: some View {
        let isPremium = entitlements.isPremium
        let summary = viewModel.summary(of: subscriptions)
        let facts = viewModel.insightFacts(of: subscriptions, summary: summary, isPremium: isPremium)
        let reasonFacts = viewModel.cancelReasonFacts(of: subscriptions, summary: summary, isPremium: isPremium)
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if subscriptions.isEmpty {
                        ContentUnavailableView(
                            "まだデータがありません",
                            systemImage: "chart.pie",
                            description: Text("サブスクを登録すると、月ごとの振り返りが見られます。")
                        )
                    } else {
                        Text("今月のまとめ（\(summary.month.fullText)）")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        TotalsCard(
                            monthlyTotal: summary.monthlyTotal,
                            annualTotal: summary.annualTotal,
                            activeCount: summary.activeCount
                        )
                        if !summary.breakdown.isEmpty {
                            ReportCategoryChartCard(breakdown: summary.breakdown)
                        }
                        InsightCard(
                            title: "今月の振り返り",
                            comment: viewModel.insight.comment,
                            isGenerated: viewModel.insight.isCommentGenerated
                        )
                        ReportPremiumSection(
                            summary: summary,
                            cancelReasons: viewModel.insight.cancelReasons,
                            shareImage: viewModel.shareImage
                        )
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .safeAreaInset(edge: .bottom, spacing: 0) { AdBanner() }
            .navigationTitle("レポート")
            .task(id: facts) {
                guard !subscriptions.isEmpty else { return }
                await viewModel.insight.loadComment(for: facts, using: insights)
            }
            .task(id: reasonFacts) {
                await viewModel.insight.loadCancelReasons(for: reasonFacts, using: insights)
            }
            .task(id: isPremium ? summary.savings : nil) {
                viewModel.updateShareImage(for: summary.savings, isPremium: isPremium)
            }
        }
    }
}
