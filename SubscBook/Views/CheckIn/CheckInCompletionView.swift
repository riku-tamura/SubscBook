import SwiftUI

/// チェックインの完了画面。解約候補が出た場合は、レポート（無料はサブスク帳プラスの案内）へ誘導する
struct CheckInCompletionView: View {
    let answeredCount: Int
    /// 開始時点で聞くサブスクがなかった理由
    let emptyReason: CheckInViewModel.EmptyReason?
    let suggestions: [CancelSuggestion]
    @Environment(AppRouter.self) private var router
    @Environment(EntitlementManager.self) private var entitlements
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: symbolName)
                    .font(.system(size: 64))
                    .foregroundStyle(answeredCount > 0 || emptyReason == .allAnswered ? Color.green : Color.accentColor)
                    .symbolEffect(.bounce, value: answeredCount)
                    .accessibilityHidden(true)
                    .padding(.top, 40)
                Text(title)
                    .font(.title2.weight(.bold))
                    .multilineTextAlignment(.center)
                Text(message)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)

                if !suggestions.isEmpty {
                    suggestionCard
                }

                Button("閉じる") { dismiss() }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
            }
            .padding()
        }
    }

    private var suggestionCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            CardHeader(title: "「使っていない」が続いているサブスクがあります", systemImage: "scissors", tint: .pink)
            Text("チェックインで2ヶ月続けて「使っていない」と答えたサブスクが\(suggestions.count)件あります。続けるか見直してみませんか？")
                .font(.subheadline)
            if entitlements.isPremium {
                Button("レポートで確認する") {
                    router.selectedTab = .report
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 4)
            } else {
                // 解約候補の一覧はサブスク帳プラスの機能なので、ぼかした画面ではなく案内を開く
                Button("サブスク帳プラスで確認する") {
                    dismiss()
                    router.showPaywallAfterDismissal(.lockedFeature(.cancelSuggestions))
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 4)
            }
        }
        .card()
    }

    private var symbolName: String {
        switch emptyReason {
        case .notYetEligible, .noSubscriptions: "calendar"
        case .allAnswered, nil: "checkmark.seal.fill"
        }
    }

    private var title: String {
        if answeredCount > 0 { return "チェックイン完了" }
        switch emptyReason {
        case .notYetEligible: return "まだチェックインはありません"
        case .noSubscriptions: return "サブスクが登録されていません"
        case .allAnswered, nil: return "先月分は回答済みです"
        }
    }

    private var message: String {
        if answeredCount > 0 {
            return "\(answeredCount)件のサブスクを振り返りました。来月もチェックインでお知らせします。"
        }
        switch emptyReason {
        case .notYetEligible:
            return "登録から1ヶ月たったサブスクについて、毎月1日に「先月使いましたか？」とお聞きします。"
        case .noSubscriptions:
            return "サブスクを登録すると、毎月のチェックインで使っているかを振り返れます。"
        case .allAnswered, nil:
            return "来月1日に、またチェックインでお知らせします。"
        }
    }
}
