import SwiftUI

/// 解約候補のカード（無料はぼかし＋鍵）
struct HomeCancelSuggestionsCard: View {
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
