import Foundation
import Observation
import SwiftData
import UserNotifications

/// ローカル通知の許可と登録（9章）。外部サーバーは使わない。
@Observable
final class NotificationScheduler {
    nonisolated static let kindKey = "kind"
    nonisolated static let subscriptionIDKey = "subscriptionID"

    private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    @ObservationIgnored private let modelContainer: ModelContainer
    @ObservationIgnored private let entitlements: EntitlementManager
    @ObservationIgnored private var rescheduleTask: Task<Void, Never>?
    /// アプリの起動中ずっと使うので、解除はしない
    @ObservationIgnored private var saveObserver: (any NSObjectProtocol)?

    init(modelContainer: ModelContainer, entitlements: EntitlementManager) {
        self.modelContainer = modelContainer
        self.entitlements = entitlements
        // サブスクの追加・編集・削除・解約はすべて保存を伴うので、保存のたびに登録し直す。
        // 呼び出し側ごとに reschedule() を書かなくても通知が古いまま残らないようにする。
        saveObserver = NotificationCenter.default.addObserver(
            forName: ModelContext.didSave, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.reschedule()
            }
        }
    }


    var isAuthorized: Bool {
        switch authorizationStatus {
        case .authorized, .provisional, .ephemeral: true
        default: false
        }
    }

    /// 通知の許可をリクエストする。許可された場合は通知を登録し直す。
    @discardableResult
    func requestAuthorization() async -> Bool {
        let granted = (try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        await refreshAuthorizationStatus()
        if granted {
            reschedule()
        }
        return granted
    }

    func refreshAuthorizationStatus() async {
        authorizationStatus = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    /// 通知を登録し直す。データの保存時は自動で呼ばれるので、購読状態や通知設定の変化、
    /// フォアグラウンド復帰時に呼ぶ。続けて呼ばれた場合は最後の1回だけ実行する。
    func reschedule() {
        let previous = rescheduleTask
        previous?.cancel()
        rescheduleTask = Task {
            // 実行中の登録が止まるのを待ってから始める（古い予定が後から追加されないように）
            await previous?.value
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            await performReschedule()
        }
    }

    private func performReschedule() async {
        await refreshAuthorizationStatus()
        guard !Task.isCancelled else { return }
        let center = UNUserNotificationCenter.current()
        guard isAuthorized else {
            center.removeAllPendingNotificationRequests()
            return
        }
        // 読み込みに失敗したら、登録済みの通知を消さずに残す（空の予定で上書きすると、すべての通知が消えてしまう）
        guard let subscriptions = try? modelContainer.mainContext.fetch(
            FetchDescriptor(predicate: Subscription.activePredicate)
        ) else { return }
        center.removeAllPendingNotificationRequests()
        let plan = NotificationPlanner.plan(
            subscriptions: subscriptions,
            isPremium: entitlements.isPremium,
            preferences: .load()
        )
        for notification in plan {
            // 新しい予定で登録し直すため中断する
            guard !Task.isCancelled else { return }
            try? await center.add(Self.request(for: notification))
        }
    }

    /// 通知の予定から、UNUserNotificationCenter に登録するリクエストを作る
    nonisolated static func request(for notification: PlannedNotification, calendar: Calendar = .current) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = notification.title
        content.body = notification.body
        content.sound = .default
        content.threadIdentifier = notification.kind.rawValue
        var userInfo: [String: String] = [Self.kindKey: notification.kind.rawValue]
        if let subscriptionID = notification.subscriptionID {
            userInfo[Self.subscriptionIDKey] = subscriptionID.uuidString
        }
        content.userInfo = userInfo

        let trigger: UNCalendarNotificationTrigger
        switch notification.trigger {
        case .once(let date):
            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        case .monthly(let day, let hour):
            trigger = UNCalendarNotificationTrigger(
                dateMatching: DateComponents(day: day, hour: hour, minute: 0),
                repeats: true
            )
        }
        return UNNotificationRequest(identifier: notification.identifier, content: content, trigger: trigger)
    }
}
