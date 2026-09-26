import SwiftUI

/// オンボーディング 3ページ目：最初のサブスクの登録（スキップ可）
struct OnboardingFirstSubscriptionPage: View {
    let onFinish: () -> Void

    var body: some View {
        NavigationStack {
            SubscriptionFormView(mode: .add, isEmbedded: true, onFinish: onFinish)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("スキップ", action: onFinish)
                    }
                }
        }
    }
}
