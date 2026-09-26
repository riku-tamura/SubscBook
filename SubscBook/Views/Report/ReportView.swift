import SwiftData
import SwiftUI

/// ⑥ 振り返りレポート
struct ReportView: View {
    @Query private var subscriptions: [Subscription]
    @Environment(EntitlementManager.self) private var entitlements
    @Environment(InsightProvider.self) private var insights
    @State private var comment: String?

    var body: some View {
        let active = subscriptions.filter(\.isActive)
        let facts = InsightFactsBuilder.monthly(subscriptions: subscriptions, isPremium: entitlements.isPremium)
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
                        Text("\(YearMonth(date: .now).fullText)の振り返り")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        TotalsCard(
                            monthlyTotal: CostCalculator.monthlyTotal(of: active),
                            annualTotal: CostCalculator.annualTotal(of: active),
                            activeCount: active.count
                        )
                        let slices = CategoryBreakdown.slices(of: active)
                        if !slices.isEmpty {
                            ReportCategoryChartCard(slices: slices, monthlyTotal: CostCalculator.monthlyTotal(of: active))
                        }
                        InsightCard(title: "AIの月次振り返り", comment: comment)
                        ReportPremiumSection(subscriptions: subscriptions)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("レポート")
            .task(id: facts) {
                guard !subscriptions.isEmpty else { return }
                let text = await insights.monthlyComment(for: facts)
                guard !Task.isCancelled else { return }
                comment = text
            }
        }
    }
}
