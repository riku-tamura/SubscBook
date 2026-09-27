import Foundation

/// 全画面広告を出してよいかのルール。家計簿のような道具のアプリなので、うっとうしくならないよう回数を絞る。
nonisolated enum InterstitialAdPolicy {
    /// 使い始めてしばらくは出さない（最初の印象を悪くしないため）
    static let gracePeriod: TimeInterval = 3 * 24 * 60 * 60
    /// 前回から空ける時間
    static let minimumInterval: TimeInterval = 2 * 24 * 60 * 60
    /// 直近の期間に出せる回数
    static let maxShowsPerWindow = 4
    static let window: TimeInterval = 30 * 24 * 60 * 60

    /// - Parameters:
    ///   - firstLaunchDate: アプリを初めて起動した日時
    ///   - shownDates: これまでに全画面広告を出した日時
    static func canShow(now: Date, firstLaunchDate: Date, shownDates: [Date]) -> Bool {
        guard now.timeIntervalSince(firstLaunchDate) >= gracePeriod else { return false }
        if let last = shownDates.max(), now.timeIntervalSince(last) < minimumInterval {
            return false
        }
        let recent = shownDates.filter { now.timeIntervalSince($0) < window }
        return recent.count < maxShowsPerWindow
    }

    /// 保存しておく日時（直近の期間より古いものは判定に使わないので捨てる）
    static func datesToKeep(_ shownDates: [Date], now: Date) -> [Date] {
        shownDates.filter { now.timeIntervalSince($0) < window }
    }
}
