import Foundation
import Observation

/// 起動時に AI の可用性を判定して、AI 版・テンプレート版を切り替える（8.1）。
/// 生成結果は月単位でキャッシュする（8.5）。
@Observable
final class InsightProvider {
    private(set) var availability: AIAvailability

    @ObservationIgnored private var service: any InsightService
    @ObservationIgnored private let cache: InsightCache
    @ObservationIgnored private var inFlight: [String: Task<String, Never>] = [:]

    init(cache: InsightCache = InsightCache(), availability: AIAvailability = .current()) {
        self.cache = cache
        self.availability = availability
        service = Self.makeService(for: availability)
    }

    /// テスト・プレビュー用に実装を差し替える
    init(service: any InsightService, cache: InsightCache, availability: AIAvailability) {
        self.cache = cache
        self.availability = availability
        self.service = service
    }

    /// データの全削除時に、生成済みのコメントも消す
    func clearCache() {
        cache.removeAll()
    }

    /// フォアグラウンド復帰時に呼ぶ。モデルの準備完了や設定変更を反映する。
    func refreshAvailability() {
        let latest = AIAvailability.current()
        guard latest != availability else { return }
        availability = latest
        service = Self.makeService(for: latest)
    }

    func monthlyComment(for facts: MonthlyInsightFacts, now: Date = .now, calendar: Calendar = .current) async -> String {
        let month = YearMonth(date: now, calendar: calendar)
        let key = "\(month.key)|\(facts.cacheKey)"
        if let cached = cache.monthlyComment(for: key) {
            return cached
        }
        return await generate(key: key) { [service, cache] in
            let result = await service.monthlyComment(for: facts)
            if result.isGenerated {
                cache.setMonthlyComment(result.text, for: key)
            }
            return result.text
        }
    }

    func cancelReason(for facts: CancelReasonFacts, now: Date = .now, calendar: Calendar = .current) async -> String {
        let month = YearMonth(date: now, calendar: calendar)
        let key = "\(month.key)|\(facts.cacheKey)"
        if let cached = cache.cancelReason(for: key) {
            return cached
        }
        return await generate(key: key) { [service, cache] in
            let result = await service.cancelReason(for: facts)
            if result.isGenerated {
                cache.setCancelReason(result.text, for: key, month: month)
            }
            return result.text
        }
    }

    /// ホームとレポートが同時に同じコメントを求めても、生成は1回にする
    private func generate(key: String, operation: @escaping () async -> String) async -> String {
        if let task = inFlight[key] {
            return await task.value
        }
        let task = Task { await operation() }
        inFlight[key] = task
        let text = await task.value
        inFlight[key] = nil
        return text
    }

    private static func makeService(for availability: AIAvailability) -> any InsightService {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *), availability.isAvailable {
            return FoundationModelInsightService()
        }
        #endif
        return TemplateInsightService()
    }
}

/// AI の生成結果のキャッシュ（端末内の UserDefaults）
final class InsightCache {
    private static let monthlyKey = "insight.monthlyComment"
    private static let cancelReasonsKey = "insight.cancelReasons"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    private struct Entry: Codable {
        let key: String
        let text: String
    }

    func monthlyComment(for key: String) -> String? {
        guard let data = defaults.data(forKey: Self.monthlyKey),
              let entry = try? JSONDecoder().decode(Entry.self, from: data),
              entry.key == key
        else { return nil }
        return entry.text
    }

    /// 月次コメントは最新の1件だけを持つ
    func setMonthlyComment(_ text: String, for key: String) {
        guard let data = try? JSONEncoder().encode(Entry(key: key, text: text)) else { return }
        defaults.set(data, forKey: Self.monthlyKey)
    }

    func cancelReason(for key: String) -> String? {
        (defaults.dictionary(forKey: Self.cancelReasonsKey) as? [String: String])?[key]
    }

    /// 理由は今月分だけを残す
    func setCancelReason(_ text: String, for key: String, month: YearMonth) {
        var reasons = (defaults.dictionary(forKey: Self.cancelReasonsKey) as? [String: String]) ?? [:]
        reasons = reasons.filter { $0.key.hasPrefix("\(month.key)|") }
        reasons[key] = text
        defaults.set(reasons, forKey: Self.cancelReasonsKey)
    }

    func removeAll() {
        defaults.removeObject(forKey: Self.monthlyKey)
        defaults.removeObject(forKey: Self.cancelReasonsKey)
    }
}
