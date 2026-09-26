import SwiftData
import SwiftUI

/// ⑤ 月次チェックイン
struct CheckInView: View {
    @Query(filter: Subscription.activePredicate) private var activeSubscriptions: [Subscription]
    @State private var viewModel: CheckInViewModel?
    @Environment(\.dismiss) private var dismiss

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
                    Button(viewModel?.isFinished == true ? "閉じる" : "あとで") { dismiss() }
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = CheckInViewModel(subscriptions: activeSubscriptions)
            }
        }
    }
}
