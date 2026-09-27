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
                    ToolbarItem(placement: .principal) {
                        VStack(spacing: 4) {
                            Text("最初のサブスクを登録")
                                .font(.headline)
                                // 小さい画面では、左右のボタンに挟まれて切れないよう少し縮める
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                            OnboardingStepIndicator(step: 3)
                        }
                    }
                }
        }
    }
}
