import SwiftData
import SwiftUI

/// ② ホーム
struct HomeView: View {
    @Query(filter: Subscription.activePredicate) private var activeSubscriptions: [Subscription]
    @Environment(AppRouter.self) private var router
    @Environment(EntitlementManager.self) private var entitlements

    var body: some View {
        let summary = HomeSummary(subscriptions: activeSubscriptions)
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if activeSubscriptions.isEmpty {
                        emptyCard
                    } else {
                        SummaryCard(summary: summary)
                        InsightCard(comment: InsightTemplates.monthlyDefault)
                        if !summary.cancelSuggestions.isEmpty {
                            CancelSuggestionsCard(suggestions: summary.cancelSuggestions)
                        }
                        UpcomingPaymentsCard(subscriptions: summary.upcomingPayments)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("ホーム")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("追加", systemImage: "plus", action: addSubscription)
                }
            }
        }
    }

    private var emptyCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "eye.circle.fill")
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
            Button("サブスクを登録", action: addSubscription)
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .card()
    }

    private func addSubscription() {
        router.requestNewSubscription(activeCount: activeSubscriptions.count, isPremium: entitlements.isPremium)
    }
}

// MARK: - 合計

private struct SummaryCard: View {
    let summary: HomeSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CardHeader(title: "毎月の支払い（月額換算）", systemImage: "yensign.circle.fill")
            Text(summary.monthlyTotal.yenText)
                .font(.system(.largeTitle, design: .rounded).weight(.bold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .accessibilityLabel("毎月の支払い、月額換算で\(summary.monthlyTotal.yenText)")
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
        stat(title: "年間", value: summary.annualTotal.yenText)
        stat(title: "契約中", value: "\(summary.activeCount)件")
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

// MARK: - AI のひとこと

struct InsightCard: View {
    let comment: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            CardHeader(title: "見張り番のひとこと", systemImage: "sparkles", tint: .orange)
            if let comment {
                Text(comment)
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text(InsightTemplates.monthlyDefault)
                    .redacted(reason: .placeholder)
                    .accessibilityLabel("コメントを準備しています")
            }
        }
        .card()
        .accessibilityElement(children: .combine)
    }
}

// MARK: - 解約候補

private struct CancelSuggestionsCard: View {
    let suggestions: [CancelSuggestion]
    @Environment(AppRouter.self) private var router
    @Environment(EntitlementManager.self) private var entitlements

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CardHeader(title: "解約候補が\(suggestions.count)件あります", systemImage: "scissors", tint: .pink)
            VStack(alignment: .leading, spacing: 12) {
                ForEach(suggestions.prefix(3)) { suggestion in
                    Button {
                        router.edit(suggestion.subscription)
                    } label: {
                        CancelSuggestionRow(suggestion: suggestion, reason: InsightTemplates.cancelReason)
                    }
                    .buttonStyle(.plain)
                }
            }
            .premiumLocked(!entitlements.isPremium, feature: .cancelSuggestions)
        }
        .card()
    }
}

/// 解約候補の1件。ホームとレポートで使う。
struct CancelSuggestionRow: View {
    let suggestion: CancelSuggestion
    let reason: String?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            CategoryIcon(name: suggestion.subscription.name, category: suggestion.subscription.category, size: 36)
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(suggestion.subscription.name)
                        .font(.body.weight(.medium))
                    Spacer()
                    Text("年間\(suggestion.annualCost.yenText)")
                        .font(.subheadline.weight(.semibold))
                        .monospacedDigit()
                }
                Text("\(suggestion.unusedMonths)ヶ月続けて使っていません")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                if let reason {
                    Text(reason)
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text(InsightTemplates.cancelReason)
                        .font(.subheadline)
                        .redacted(reason: .placeholder)
                }
            }
        }
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
        .accessibilityHint("編集画面を開きます")
    }
}

// MARK: - 次の支払い

private struct UpcomingPaymentsCard: View {
    let subscriptions: [Subscription]
    @Environment(AppRouter.self) private var router

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                CardHeader(title: "次の支払い", systemImage: "calendar")
                Spacer()
                Button("すべて見る") {
                    router.selectedTab = .list
                }
                .font(.subheadline)
            }
            ForEach(subscriptions) { subscription in
                Button {
                    router.edit(subscription)
                } label: {
                    row(subscription)
                }
                .buttonStyle(.plain)
                if subscription.id != subscriptions.last?.id {
                    Divider()
                }
            }
        }
        .card()
    }

    private func row(_ subscription: Subscription) -> some View {
        HStack(spacing: 12) {
            CategoryIcon(name: subscription.name, category: subscription.category, size: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(subscription.name)
                    .font(.body.weight(.medium))
                Text("\(subscription.nextPaymentDate.monthDayWeekdayText)・\(subscription.nextPaymentDate.relativeDayText())")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(subscription.price.yenText)
                .font(.callout.monospacedDigit())
        }
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
        .accessibilityHint("編集画面を開きます")
    }
}
