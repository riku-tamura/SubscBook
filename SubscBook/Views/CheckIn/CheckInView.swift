import SwiftData
import SwiftUI

/// ⑤ 月次チェックイン
struct CheckInView: View {
    @Query(filter: Subscription.activePredicate) private var activeSubscriptions: [Subscription]
    @State private var viewModel: CheckInViewModel?
    @Environment(\.dismiss) private var dismiss
    @Environment(AppRouter.self) private var router

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    CheckInQuestionView(viewModel: viewModel, activeSubscriptions: activeSubscriptions)
                } else {
                    ProgressView()
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(viewModel?.isFinished == true ? "閉じる" : "あとで") {
                        requestInterstitialIfAnswered()
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = CheckInViewModel(subscriptions: activeSubscriptions)
            }
        }
    }

    /// 今回1件以上答えて終えたときだけ、閉じた後に全画面広告を出す（途中でやめた・答えるものがなかったときは出さない）
    private func requestInterstitialIfAnswered() {
        guard let viewModel, viewModel.isFinished, !viewModel.queue.isEmpty else { return }
        router.requestInterstitialAfterDismissal()
    }
}
