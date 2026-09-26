import SwiftUI

/// ① オンボーディング（3ページ）
struct OnboardingView: View {
    static let completedKey = "onboarding.completed"

    @AppStorage(Self.completedKey) private var hasCompletedOnboarding = false
    @State private var page = Page.value

    enum Page: Hashable {
        case value
        case notifications
        case firstSubscription
    }

    var body: some View {
        // スワイプで通知の説明を飛ばしたり、フォームの操作でページがめくれたりしないよう、ボタンでだけ進める
        ZStack {
            switch page {
            case .value:
                OnboardingValuePage { advance(to: .notifications) }
                    .transition(pageTransition)
            case .notifications:
                OnboardingNotificationPage { advance(to: .firstSubscription) }
                    .transition(pageTransition)
            case .firstSubscription:
                OnboardingFirstSubscriptionPage(onFinish: complete)
                    .transition(pageTransition)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }

    private var pageTransition: AnyTransition {
        .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading))
    }

    private func advance(to next: Page) {
        withAnimation { page = next }
    }

    private func complete() {
        // オンボーディング直後にペイウォールは出さない（7章）
        withAnimation { hasCompletedOnboarding = true }
    }
}

// MARK: - 共通レイアウト

#if DEBUG
#Preview {
    OnboardingView()
        .previewEnvironment()
}
#endif
