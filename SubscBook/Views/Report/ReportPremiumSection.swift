import SwiftUI

/// ⑥ レポートのサブスク帳プラス部分。無料ユーザーにはぼかして表示する。
struct ReportPremiumSection: View {
    let subscriptions: [Subscription]
    @Environment(EntitlementManager.self) private var entitlements
    @Environment(InsightProvider.self) private var insights
    @State private var reasons: [UUID: String] = [:]

    var body: some View {
        let active = subscriptions.filter(\.isActive)
        let suggestions = CancelSuggestionDetector.suggestions(for: active)
        let duplicates = DuplicateDetector.duplicateGroups(in: active)
        let savings = SavingsSummary(subscriptions: subscriptions)
        let reasonFacts = entitlements.isPremium
            ? suggestions.map { InsightFactsBuilder.cancelReason(for: $0, among: subscriptions) }
            : []

        VStack(spacing: 16) {
            SectionTitle(title: "サブスク帳プラス", isLocked: !entitlements.isPremium)
            ReportCancelSuggestionsCard(suggestions: suggestions, reasons: reasons)
            ReportDuplicatesCard(groups: duplicates)
            ReportSavingsCard(savings: savings)
        }
        .task(id: reasonFacts) {
            for facts in reasonFacts {
                let text = await insights.cancelReason(for: facts)
                guard !Task.isCancelled else { return }
                reasons[facts.subscriptionID] = text
            }
        }
    }
}

private struct SectionTitle: View {
    let title: String
    let isLocked: Bool

    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)
                .accessibilityAddTraits(.isHeader)
            if isLocked {
                PremiumBadge()
            }
            Spacer()
        }
        .padding(.top, 8)
    }
}
