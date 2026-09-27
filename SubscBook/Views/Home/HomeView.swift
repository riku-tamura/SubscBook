import SwiftData
import SwiftUI

/// ② ホーム
struct HomeView: View {
    @Query private var subscriptions: [Subscription]
    @State private var viewModel = HomeViewModel()
    @Environment(AppRouter.self) private var router
    @Environment(EntitlementManager.self) private var entitlements
    @Environment(InsightProvider.self) private var insights

    var body: some View {
        let summary = viewModel.summary(of: subscriptions)
        let facts = viewModel.insightFacts(of: subscriptions, summary: summary, isPremium: entitlements.isPremium)
        let reasonFacts = viewModel.cancelReasonFacts(of: subscriptions, summary: summary, isPremium: entitlements.isPremium)
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
                        InsightCard(comment: viewModel.insight.comment, isGenerated: viewModel.insight.isCommentGenerated)
                        if !summary.cancelSuggestions.isEmpty {
                            HomeCancelSuggestionsCard(suggestions: summary.cancelSuggestions, reasons: viewModel.insight.cancelReasons)
                        }
                        HomeUpcomingPaymentsCard(subscriptions: summary.upcomingPayments)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .safeAreaInset(edge: .bottom, spacing: 0) { AdBanner() }
            .navigationTitle("ホーム")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("追加", systemImage: "plus") { addSubscription(activeCount: summary.activeCount) }
                }
            }
            .task(id: facts) {
                guard summary.activeCount > 0 else { return }
                await viewModel.insight.loadComment(for: facts, using: insights)
            }
            .task(id: reasonFacts) {
                await viewModel.insight.loadCancelReasons(for: reasonFacts, using: insights)
            }
        }
    }

    private var emptyCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "text.book.closed.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color.accentColor)
                .accessibilityHidden(true)
            Text("サブスクを登録して、1冊にまとめましょう")
                .font(.headline)
                .multilineTextAlignment(.center)
            Text("支払日の前日にお知らせし、毎月の合計を見える化します。登録したデータは端末の外に出ません。")
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
