import SwiftUI

/// 解約候補の一覧（AI の理由付き・サブスク帳プラス）
struct ReportCancelSuggestionsCard: View {
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
