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
    /// キャッシュを消した回数。生成中にデータの全削除があった場合に、終わった生成の結果を保存しないために使う。
    @ObservationIgnored private var cacheGeneration = 0

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

    /// データの全削除時に、生成済みのコメントも消す。生成中のものは、終わっても保存しない。
    func clearCache() {
        cacheGeneration += 1
        inFlight.removeAll()
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
        let generation = cacheGeneration
        let result = await generate(key: key) { [service] in
            await service.monthlyComment(for: facts)
        }
        if result.isGenerated && generation == cacheGeneration {
            cache.setMonthlyComment(result.text, for: key, month: month)
        }
        return result
    }

    func cancelReason(for facts: CancelReasonFacts, now: Date = .now, calendar: Calendar = .current) async -> String {
        let month = YearMonth(date: now, calendar: calendar)
        // 言い換える元の文が同じなら、今月作ったものを使う
        let key = "\(month.key)|\(facts.subscriptionID.uuidString)|\(TemplateInsightService.cancelReasonText(for: facts))"
        if let cached = cache.cancelReason(for: key) {
            return cached
        }
        let generation = cacheGeneration
        let result = await generate(key: key) { [service] in
            await service.cancelReason(for: facts)
        }
        if result.isGenerated && generation == cacheGeneration {
            cache.setCancelReason(result.text, for: key, month: month)
        }
        return result.text
    }

    /// ホームとレポートが同時に同じコメントを求めても、生成は1回にする
    private func generate(key: String, operation: @escaping () async -> InsightResult) async -> InsightResult {
        if let task = inFlight[key] {
            return await task.value
        }
        let task = Task { await operation() }
        inFlight[key] = task
        let result = await task.value
        // 待っている間にキャッシュが消され、別の生成が始まっていたら、そちらは消さない
        if inFlight[key] == task {
            inFlight[key] = nil
        }
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
