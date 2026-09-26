import SwiftUI

struct CheckInCompletionView: View {
    let answeredCount: Int
    let suggestions: [CancelSuggestion]
    @Environment(AppRouter.self) private var router
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.green)
                    .symbolEffect(.bounce, value: answeredCount)
                    .accessibilityHidden(true)
                    .padding(.top, 40)
                Text(answeredCount > 0 ? "チェックイン完了" : "回答するサブスクはありません")
                    .font(.title2.weight(.bold))
                Text(answeredCount > 0
                     ? "\(answeredCount)件のサブスクを振り返りました。来月も見張りを続けます。"
                     : "先月分のチェックインはすべて回答済みです。")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)

                if !suggestions.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        CardHeader(title: "使っていないサブスクが見つかりました", systemImage: "scissors", tint: .pink)
                        Text("2ヶ月続けて使っていないサブスクが\(suggestions.count)件あります。続けるか見直してみませんか？")
                            .font(.subheadline)
                        Button("レポートで確認する") {
                            router.selectedTab = .report
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.top, 4)
                    }
                    .card()
                }

                Button("閉じる") { dismiss() }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
            }
            .padding()
        }
    }
}
