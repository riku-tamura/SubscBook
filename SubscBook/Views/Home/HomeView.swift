import SwiftData
import SwiftUI

/// ② ホーム
struct HomeView: View {
    @Query private var subscriptions: [Subscription]
    @Environment(AppRouter.self) private var router
    @Environment(EntitlementManager.self) private var entitlements
    @Environment(InsightProvider.self) private var insights
    @State private var comment: String?
    @State private var cancelReasons: [UUID: String] = [:]

    var body: some View {
        let summary = HomeSummary(subscriptions: subscriptions)
        let facts = InsightFactsBuilder.monthly(
            subscriptions: subscriptions,
            isPremium: entitlements.isPremium,
            suggestions: summary.cancelSuggestions
        )
        // 解約候補の理由はサブスク帳プラスのみ AI で作る（無料はぼかし表示なので作らない）
        let reasonFacts = entitlements.isPremium
            ? summary.cancelSuggestions.map { InsightFactsBuilder.cancelReason(for: $0, among: subscriptions) }
            : []
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if summary.activeCount == 0 {
                        emptyCard
                    } else {
                        if summary.needsCheckIn {
                            HomeCheckInBanner(month: summary.checkInMonth, count: summary.pendingCheckIns.count)
                        }
                        TotalsCard(
                            monthlyTotal: summary.monthlyTotal,
                            annualTotal: summary.annualTotal,
                            activeCount: summary.activeCount
                        )
                        InsightCard(comment: comment)
                        if !summary.cancelSuggestions.isEmpty {
                            HomeCancelSuggestionsCard(suggestions: summary.cancelSuggestions, reasons: cancelReasons)
                        }
                        HomeUpcomingPaymentsCard(subscriptions: summary.upcomingPayments)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("ホーム")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("追加", systemImage: "plus") { addSubscription(activeCount: summary.activeCount) }
                }
            }
            .task(id: facts) {
                guard summary.activeCount > 0 else { return }
                let text = await insights.monthlyComment(for: facts)
                // 生成中に事実が変わった場合は、古い結果で上書きしない
                guard !Task.isCancelled else { return }
                comment = text
            }
            .task(id: reasonFacts) {
                for facts in reasonFacts {
                    let text = await insights.cancelReason(for: facts)
                    guard !Task.isCancelled else { return }
                    cancelReasons[facts.subscriptionID] = text
                }
            }
        }
    }

    private var emptyCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "text.book.closed.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color.accentColor)
                .accessibilityHidden(true)
            Text("サブスクを登録して、見張りを始めましょう")
                .font(.headline)
                .multilineTextAlignment(.center)
            Text("支払日の前日にお知らせし、毎月の合計を見える化します。データは端末の外に出ません。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("サブスクを登録") { addSubscription(activeCount: 0) }
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .card()
    }

    private func addSubscription(activeCount: Int) {
        router.requestNewSubscription(activeCount: activeCount, isPremium: entitlements.isPremium)
    }
}
