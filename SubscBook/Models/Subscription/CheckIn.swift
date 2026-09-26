import Foundation
import SwiftData

/// 月次チェックイン（ある月にそのサブスクを使ったかどうかの回答）
@Model
final class CheckIn {
    var id: UUID
    /// 対象月（"2026-09" 形式）
    var month: String
    var used: Bool
    var answeredAt: Date
    var subscription: Subscription?

    init(id: UUID = UUID(), month: YearMonth, used: Bool, answeredAt: Date = .now) {
        self.id = id
        self.month = month.key
        self.used = used
        self.answeredAt = answeredAt
    }

    var yearMonth: YearMonth? {
        YearMonth(month)
    }
}
