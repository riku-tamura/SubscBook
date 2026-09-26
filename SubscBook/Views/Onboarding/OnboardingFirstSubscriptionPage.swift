import SwiftUI

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
