import SwiftUI

/// ⑥ レポートのサブスク帳プラス部分。無料ユーザーにはぼかして表示する。
struct PremiumReportSections: View {
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
            CancelSuggestionsReportCard(suggestions: suggestions, reasons: reasons)
            DuplicatesReportCard(groups: duplicates)
            SavingsReportCard(savings: savings)
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
                PlusBadge()
            }
            Spacer()
        }
        .padding(.top, 8)
    }
}

// MARK: - 解約候補

private struct CancelSuggestionsReportCard: View {
    let suggestions: [CancelSuggestion]
    let reasons: [UUID: String]
    @Environment(EntitlementManager.self) private var entitlements
    @Environment(AppRouter.self) private var router

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CardHeader(title: "解約候補", systemImage: "scissors", tint: .pink)
            Group {
                if suggestions.isEmpty {
                    Text("2ヶ月続けて使っていないサブスクはありません。毎月のチェックインで見張りを続けます。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(suggestions) { suggestion in
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
                }
            }
            .premiumLocked(!entitlements.isPremium, feature: .cancelSuggestions)
        }
        .card()
    }
}

// MARK: - 重複

private struct DuplicatesReportCard: View {
    let groups: [DuplicateGroup]
    @Environment(EntitlementManager.self) private var entitlements

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CardHeader(title: "重複しているサブスク", systemImage: "square.on.square", tint: .purple)
            Group {
                if groups.isEmpty {
                    Text("同じジャンルで重なっているサブスクはありません。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(groups) { group in
                            groupRow(group)
                        }
                        Text("同じジャンルのサービスは、ひとつにまとめられないか見直してみませんか？")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .premiumLocked(!entitlements.isPremium, feature: .duplicateDetection)
        }
        .card()
    }

    private func groupRow(_ group: DuplicateGroup) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label {
                    Text("\(group.category.displayName)（\(group.subscriptions.count)件）")
                        .font(.subheadline.weight(.semibold))
                } icon: {
                    Image(systemName: group.category.symbolName)
                        .foregroundStyle(group.category.color)
                }
                Spacer()
                Text("月\(group.monthlyTotal.yenText)")
                    .font(.subheadline.monospacedDigit())
            }
            ForEach(group.subscriptions) { subscription in
                HStack(spacing: 8) {
                    CategoryIcon(name: subscription.name, category: subscription.category, size: 24)
                    Text(subscription.name)
                        .font(.subheadline)
                    Spacer()
                    Text(subscription.priceText)
                        .font(.footnote.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - 節約

private struct SavingsReportCard: View {
    let savings: SavingsSummary
    @Environment(EntitlementManager.self) private var entitlements
    @State private var shareImage: Image?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CardHeader(title: "年間節約レポート", systemImage: "chart.line.uptrend.xyaxis", tint: .green)
            Group {
                if savings.hasSavings {
                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("年間の節約額")
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
                        Text("\(savings.canceledCount)件のサブスクを解約し、これまでに\(savings.realizedSavings.yenText)を節約しました。")
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
        .task(id: entitlements.isPremium ? savings : nil) {
            guard entitlements.isPremium, savings.hasSavings else {
                shareImage = nil
                return
            }
            shareImage = SavingsShareCard.render(savings: savings)
        }
    }
}
