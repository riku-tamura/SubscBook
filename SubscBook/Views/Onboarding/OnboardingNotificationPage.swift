import SwiftUI

/// オンボーディング 2ページ目：通知の許可（理由を説明してから許可ダイアログを出す）
struct OnboardingNotificationPage: View {
    let isRequesting: Bool
    let onAllow: () -> Void
    let onSkip: () -> Void

    var body: some View {
        OnboardingPageLayout(
            step: 2,
            systemImage: "bell.badge.fill",
            title: "支払日の前日に\nお知らせします",
            primaryTitle: "通知を許可する",
            primaryAction: onAllow,
            secondaryTitle: "あとで",
            secondaryAction: onSkip,
            isBusy: isRequesting
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Text("通知を許可すると、次のタイミングでお知らせします。")
                    .font(.subheadline)
                Label("支払日の前日 9:00", systemImage: "yensign.circle")
                Label("毎月1日 20:00 の月次チェックイン（登録から1ヶ月後から）", systemImage: "checklist")
                Text("通知はこの端末の中で作成され、外部には送信されません。設定からいつでも変更できます。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .card()
        }
    }
}
