import Foundation

/// AI の生成結果のキャッシュ（端末内の UserDefaults）
final class InsightCache {
    private static let monthlyKey = "insight.monthlyComment"
    private static let cancelReasonsKey = "insight.cancelReasons"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func monthlyComment(for key: String) -> String? {
        entries(forKey: Self.monthlyKey)[key]
    }

    /// 月次コメントは今月分だけを残す（無料・プラスで事実が違っても作り直さずに済むよう、複数件を持つ）
    func setMonthlyComment(_ text: String, for key: String, month: YearMonth) {
        setEntry(text, for: key, month: month, forKey: Self.monthlyKey)
    }

    func cancelReason(for key: String) -> String? {
        entries(forKey: Self.cancelReasonsKey)[key]
    }

    /// 理由は今月分だけを残す
    func setCancelReason(_ text: String, for key: String, month: YearMonth) {
        setEntry(text, for: key, month: month, forKey: Self.cancelReasonsKey)
    }

    private func entries(forKey storageKey: String) -> [String: String] {
        (defaults.dictionary(forKey: storageKey) as? [String: String]) ?? [:]
    }

    private func setEntry(_ text: String, for key: String, month: YearMonth, forKey storageKey: String) {
        var entries = entries(forKey: storageKey).filter { $0.key.hasPrefix("\(month.key)|") }
        entries[key] = text
        defaults.set(entries, forKey: storageKey)
    }

    func removeAll() {
        defaults.removeObject(forKey: Self.monthlyKey)
        defaults.removeObject(forKey: Self.cancelReasonsKey)
    }
}
