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
                ValuePage { advance(to: .notifications) }
                    .transition(pageTransition)
            case .notifications:
                NotificationPage { advance(to: .firstSubscription) }
                    .transition(pageTransition)
            case .firstSubscription:
                FirstSubscriptionPage(onFinish: complete)
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

// MARK: - 1. 価値の説明

private struct ValuePage: View {
    let onNext: () -> Void

    var body: some View {
        OnboardingPage(
            systemImage: "text.book.closed.fill",
            title: "あなたのサブスク、\n見張ります",
            primaryTitle: "はじめる",
            primaryAction: onNext
        ) {
            VStack(alignment: .leading, spacing: 16) {
                point("calendar.badge.clock", "支払日の前日にお知らせ")
                point("chart.pie.fill", "毎月・毎年の合計がひと目でわかる")
                point("scissors", "使っていないサブスクを見つける")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .card()

            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "lock.shield.fill")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text("データは端末の外に出ません")
                        .font(.headline)
                    Text("登録したサブスクもAIの分析も、すべてこの端末の中だけで完結します。外部のサーバーには送信しません。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .card()
            .accessibilityElement(children: .combine)
        }
    }

    private func point(_ systemImage: String, _ text: String) -> some View {
        Label {
            Text(text)
                .font(.body.weight(.medium))
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(Color.accentColor)
        }
    }
}

// MARK: - 2. 通知の許可

private struct NotificationPage: View {
    let onNext: () -> Void
    @Environment(NotificationScheduler.self) private var notifications
    @State private var isRequesting = false

    var body: some View {
        OnboardingPage(
            systemImage: "bell.badge.fill",
            title: "支払日の前日に\nお知らせします",
            primaryTitle: "通知を許可する",
            primaryAction: requestAuthorization,
            secondaryTitle: "あとで",
            secondaryAction: onNext,
            isBusy: isRequesting
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Text("通知を許可すると、次のタイミングでお知らせします。")
                    .font(.subheadline)
                Label("支払日の前日 9:00", systemImage: "yensign.circle")
                Label("毎月1日の月次チェックイン", systemImage: "checklist")
                Text("通知はこの端末の中で作成され、外部には送信されません。設定からいつでも変更できます。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .card()
        }
    }

    private func requestAuthorization() {
        isRequesting = true
        Task {
            await notifications.requestAuthorization()
            isRequesting = false
            onNext()
        }
    }
}

// MARK: - 3. 最初のサブスクを登録

private struct FirstSubscriptionPage: View {
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

// MARK: - 共通レイアウト

private struct OnboardingPage<Content: View>: View {
    let systemImage: String
    let title: String
    let primaryTitle: String
    let primaryAction: () -> Void
    var secondaryTitle: String?
    var secondaryAction: (() -> Void)?
    var isBusy = false
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                    Image(systemName: systemImage)
                        .font(.system(size: 64))
                        .foregroundStyle(Color.accentColor)
                        .padding(.top, 48)
                        .accessibilityHidden(true)
                    Text(title)
                        .font(.largeTitle.weight(.bold))
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)
                    content
                }
                .padding()
            }
            VStack(spacing: 8) {
                Button(action: primaryAction) {
                    Group {
                        if isBusy {
                            ProgressView().tint(.white)
                        } else {
                            Text(primaryTitle)
                        }
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(isBusy)
                if let secondaryTitle, let secondaryAction {
                    Button(secondaryTitle, action: secondaryAction)
                        .controlSize(.large)
                        .disabled(isBusy)
                }
            }
            .padding()
        }
    }
}

#if DEBUG
#Preview {
    OnboardingView()
        .previewEnvironment()
}
#endif
