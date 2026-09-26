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
                            CheckInBanner(month: summary.checkInMonth, count: summary.pendingCheckIns.count)
                        }
                        TotalsCard(
                            monthlyTotal: summary.monthlyTotal,
                            annualTotal: summary.annualTotal,
                            activeCount: summary.activeCount
                        )
                        InsightCard(comment: comment)
                        if !summary.cancelSuggestions.isEmpty {
                            CancelSuggestionsCard(suggestions: summary.cancelSuggestions, reasons: cancelReasons)
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

// MARK: - チェックインのお願い

private struct CheckInBanner: View {
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

// MARK: - AI のひとこと

struct InsightCard: View {
    var title = "今月のひとこと"
    let comment: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            CardHeader(title: title, systemImage: "sparkles", tint: .orange)
            if let comment {
                Text(comment)
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text(TemplateInsightService.monthlyDefault)
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
    /// AI が作った理由（サブスク帳プラスのみ）
    let reasons: [UUID: String]
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
                        CancelSuggestionRow(
                            suggestion: suggestion,
                            reason: entitlements.isPremium
                                ? reasons[suggestion.id]
                                : TemplateInsightService.cancelReasonDefault
                        )
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
                AdaptiveHStack {
                    Text(suggestion.subscription.name)
                        .font(.body.weight(.medium))
                } trailing: {
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
                    Text(TemplateInsightService.cancelReasonDefault)
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
            AdaptiveHStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(subscription.name)
                        .font(.body.weight(.medium))
                    Text("\(subscription.nextPaymentDate.monthDayWeekdayText)・\(subscription.nextPaymentDate.relativeDayText())")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            } trailing: {
                Text(subscription.price.yenText)
                    .font(.callout.monospacedDigit())
            }
        }
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
        .accessibilityHint("編集画面を開きます")
    }
}
