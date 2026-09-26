import Foundation
import Observation

/// ① オンボーディングの状態と操作
@Observable
final class OnboardingViewModel {
    /// オンボーディングを終えたかを保存する UserDefaults のキー
    static let completedKey = "onboarding.completed"

    enum Page: Hashable {
        /// 価値の説明
        case value
        /// 通知の許可
        case notifications
        /// 最初のサブスクの登録
        case firstSubscription
    }

    private(set) var page = Page.value
    private(set) var isRequestingNotifications = false

    func advance(to next: Page) {
        page = next
    }

    /// 通知の許可を求めてから、次のページへ進む（許可されなくても進む）
    func requestNotificationPermission(using notifications: NotificationScheduler) async {
        isRequestingNotifications = true
        await notifications.requestAuthorization()
        isRequestingNotifications = false
        page = .firstSubscription
    }
}
