import Foundation
import Synchronization
import Testing
@testable import SubscBook

/// 呼び出し回数を数えるテスト用の実装
nonisolated final class StubInsightService: InsightService {
    let calls = Mutex(0)
    let isGenerated: Bool
    let delay: Duration

    init(isGenerated: Bool, delay: Duration = .zero) {
        self.isGenerated = isGenerated
        self.delay = delay
    }

    func monthlyComment(for facts: MonthlyInsightFacts) async -> InsightResult {
        calls.withLock { $0 += 1 }
        try? await Task.sleep(for: delay)
        return InsightResult(text: "生成したコメント", isGenerated: isGenerated)
    }

    func cancelReason(for facts: CancelReasonFacts) async -> InsightResult {
        calls.withLock { $0 += 1 }
        return InsightResult(text: "生成した理由", isGenerated: isGenerated)
    }
}
