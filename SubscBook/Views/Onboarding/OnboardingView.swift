import SwiftUI

/// ① オンボーディング（3ページ）
struct OnboardingView: View {
    @AppStorage(OnboardingViewModel.completedKey) private var hasCompletedOnboarding = false
    @State private var viewModel = OnboardingViewModel()
    @Environment(NotificationScheduler.self) private var notifications

    var body: some View {
        // スワイプで通知の説明を飛ばしたり、フォームの操作でページがめくれたりしないよう、ボタンでだけ進める
        ZStack {
            switch viewModel.page {
            case .value:
                OnboardingValuePage {
                    viewModel.advance(to: .notifications)
                }
                .transition(pageTransition)
            case .notifications:
                OnboardingNotificationPage(isRequesting: viewModel.isRequestingNotifications) {
                    Task {
                        await viewModel.requestNotificationPermission(using: notifications)
                    }
                } onSkip: {
                    viewModel.advance(to: .firstSubscription)
                }
                .transition(pageTransition)
            case .firstSubscription:
                OnboardingFirstSubscriptionPage(onFinish: complete)
                    .transition(pageTransition)
            }
        }
        .animation(.default, value: viewModel.page)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }

    private var pageTransition: AnyTransition {
        .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading))
    }

    private func complete() {
        // オンボーディング直後にペイウォールは出さない（7章）
        withAnimation { hasCompletedOnboarding = true }
    }
}

#if DEBUG
#Preview {
    OnboardingView()
        .previewEnvironment()
}
#endif
