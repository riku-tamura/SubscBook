import SwiftUI

/// ⑥ レポートのサブスク帳プラス部分。無料ユーザーにはぼかして表示する。
struct ReportPremiumSection: View {
    let summary: ReportSummary
    /// AI が作った解約候補の理由（サブスク帳プラスのみ）
    let cancelReasons: [UUID: String]
    let shareImage: Image?
    @Environment(EntitlementManager.self) private var entitlements

    var body: some View {
        VStack(spacing: 16) {
            SectionTitle(title: "サブスク帳プラス", isLocked: !entitlements.isPremium)
            ReportCancelSuggestionsCard(suggestions: summary.cancelSuggestions, reasons: cancelReasons)
            ReportDuplicatesCard(groups: summary.duplicateGroups)
            ReportSavingsCard(savings: summary.savings, shareImage: shareImage)
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
