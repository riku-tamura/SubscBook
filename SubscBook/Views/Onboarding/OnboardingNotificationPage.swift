import SwiftUI

struct OnboardingNotificationPage: View {
    let onNext: () -> Void
    @Environment(NotificationScheduler.self) private var notifications
    @State private var isRequesting = false

    var body: some View {
        OnboardingPageLayout(
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
