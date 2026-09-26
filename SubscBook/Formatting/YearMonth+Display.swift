import Foundation

extension YearMonth {
    /// "8月"
    nonisolated var monthText: String { "\(month)月" }

    /// "2026年8月"
    nonisolated var fullText: String { "\(year)年\(month)月" }
}
