import Foundation

/// 登録するローカル通知1件分
nonisolated struct PlannedNotification: Equatable, Sendable {
    enum Kind: String, Sendable {
        /// 支払日の前日
        case payment
        /// 無料トライアル終了の3日前・前日
        case trial
        /// 毎月1日の月次チェックイン
        case checkIn
    }

    enum Trigger: Equatable, Sendable {
        /// 指定日時に1回
        case once(Date)
        /// 毎月、指定日・時刻に繰り返す
        case monthly(day: Int, hour: Int)
    }

    let identifier: String
    let kind: Kind
    let title: String
    let body: String
    let trigger: Trigger
    var subscriptionID: UUID?
}
