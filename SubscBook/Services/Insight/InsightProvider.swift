import Foundation
import Observation

/// 起動時に AI の可用性を判定して、AI 版・テンプレート版を切り替える（8.1）。
/// 生成結果は月単位でキャッシュする（8.5）。
@Observable
final class InsightProvider {
    private(set) var availability: InsightAvailability

    @ObservationIgnored private var service: any InsightService
    @ObservationIgnored private let cache: InsightCache
    @ObservationIgnored private var inFlight: [String: Task<InsightResult, Never>] = [:]

    init(cache: InsightCache = InsightCache(), availability: InsightAvailability = .current()) {
        self.cache = cache
        self.availability = availability
        service = Self.makeService(for: availability)
    }

    /// テスト・プレビュー用に実装を差し替える
    init(service: any InsightService, cache: InsightCache, availability: InsightAvailability) {
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
        let latest = InsightAvailability.current()
        guard latest != availability else { return }
        availability = latest
        service = Self.makeService(for: latest)
    }

    /// 月次のひとこと。AI で作れたか（isGenerated）も返すので、画面で「Apple Intelligence で作成」と示せる。
    func monthlyComment(for facts: MonthlyInsightFacts, now: Date = .now, calendar: Calendar = .current) async -> InsightResult {
        let month = YearMonth(date: now, calendar: calendar)
        // AI は定型の文を言い換えるだけなので、元の文が同じ（伝える内容が同じ）なら今月作ったものを使う
        let key = "\(month.key)|\(TemplateInsightService.monthlyText(for: facts))"
        // キャッシュには AI で作れたものだけを入れている
        if let cached = cache.monthlyComment(for: key) {
            return InsightResult(text: cached, isGenerated: true)
        }
        return await generate(key: key) { [service, cache] in
            let result = await service.monthlyComment(for: facts)
            if result.isGenerated {
                cache.setMonthlyComment(result.text, for: key, month: month)
            }
            return result
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
            return result
        }.text
    }

    /// ホームとレポートが同時に同じコメントを求めても、生成は1回にする
    private func generate(key: String, operation: @escaping () async -> InsightResult) async -> InsightResult {
        if let task = inFlight[key] {
            return await task.value
        }
        let task = Task { await operation() }
        inFlight[key] = task
        let result = await task.value
        inFlight[key] = nil
        return result
    }

    private static func makeService(for availability: InsightAvailability) -> any InsightService {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *), availability.isAvailable {
            return FoundationModelInsightService()
        }
        #endif
        return TemplateInsightService()
    }
}
