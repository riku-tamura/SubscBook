import Foundation

/// 通知ごとの ON/OFF（設定画面で変更する）。UserDefaults に保存する。
nonisolated struct NotificationPreferences: Equatable, Sendable {
    static let paymentReminderKey = "notifications.paymentReminder"
    static let trialReminderKey = "notifications.trialReminder"
    static let checkInReminderKey = "notifications.checkInReminder"

    var paymentReminder = true
    var trialReminder = true
    var checkInReminder = true

    static func load(from defaults: UserDefaults = .standard) -> NotificationPreferences {
        NotificationPreferences(
            paymentReminder: defaults.object(forKey: paymentReminderKey) as? Bool ?? true,
            trialReminder: defaults.object(forKey: trialReminderKey) as? Bool ?? true,
            checkInReminder: defaults.object(forKey: checkInReminderKey) as? Bool ?? true
        )
    }
}
