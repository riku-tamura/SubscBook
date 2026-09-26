import SwiftUI

/// 解約候補のカード（無料はぼかし＋鍵）
struct HomeCancelSuggestionsCard: View {
    let suggestions: [CancelSuggestion]
    /// AI が作った理由（サブスク帳プラスのみ）
    let reasons: [UUID: String]
    @Environment(AppRouter.self) private var router
    @Environment(EntitlementManager.self) private var entitlements

    /// ホームに出す件数（残りはレポートで見る）
    static let displayLimit = 3

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                CardHeader(title: "解約候補が\(suggestions.count)件あります", systemImage: "scissors", tint: .pink)
                Spacer()
                if suggestions.count > Self.displayLimit {
                    Button("すべて見る") {
                        router.selectedTab = .report
                    }
                    .font(.subheadline)
                }
            }
            VStack(alignment: .leading, spacing: 12) {
                ForEach(suggestions.prefix(Self.displayLimit)) { suggestion in
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
