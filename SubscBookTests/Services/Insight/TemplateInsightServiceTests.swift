import Foundation
import Testing
@testable import SubscBook

@Suite("テンプレート文")
struct TemplateInsightServiceTests {
    @Test("テンプレート文は事実に合わせて選ぶ")
    func templates() {
        func facts(trend: SpendingTrend = .unchanged, hidden: Int = 0, duplicates: Int = 0, canceled: Int = 0) -> MonthlyInsightFacts {
            MonthlyInsightFacts(
                activeCount: 3, trend: trend, cancelCandidates: [], hiddenCancelCandidateCount: hidden,
                duplicateCategories: [], hiddenDuplicateCount: duplicates, canceledThisMonthCount: canceled
            )
        }
        #expect(TemplateInsightService.monthlyText(for: facts()) == TemplateInsightService.monthlyDefault)
        #expect(TemplateInsightService.monthlyText(for: facts(hidden: 1)).contains("使っていない"))
        #expect(TemplateInsightService.monthlyText(for: facts(duplicates: 1)).contains("重なって"))
        #expect(TemplateInsightService.monthlyText(for: facts(trend: .decreased)).contains("減りました"))
        // テンプレート文も数値を含まない
        for text in [facts(), facts(hidden: 1), facts(duplicates: 1), facts(canceled: 1), facts(trend: .increased)]
            .map(TemplateInsightService.monthlyText(for:)) {
            #expect(InsightSanitizer.sanitize(text, maxLength: 60) == text)
        }
    }
}
