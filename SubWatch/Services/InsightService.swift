import Foundation

/// AI のコメント生成（8章）。AI 版とテンプレート版を同じ形で扱う。
nonisolated protocol InsightService: Sendable {
    func monthlyComment(for facts: MonthlyInsightFacts) async -> InsightResult
    func cancelReason(for facts: CancelReasonFacts) async -> InsightResult
}

nonisolated struct InsightResult: Hashable, Sendable {
    let text: String
    /// AI が生成したか（false はテンプレート文。キャッシュしない）
    let isGenerated: Bool
}

/// テンプレート文（8.6）。AI が使えない端末や、生成に失敗したときに使う。
nonisolated struct TemplateInsightService: InsightService {
    static let monthlyDefault = "今月も見張りを続けています。気になるサブスクがないかチェックしてみましょう。"
    static let cancelReasonDefault = "しばらく使っていないようです。続けるか見直してみませんか？"

    func monthlyComment(for facts: MonthlyInsightFacts) async -> InsightResult {
        InsightResult(text: Self.monthlyText(for: facts), isGenerated: false)
    }

    func cancelReason(for facts: CancelReasonFacts) async -> InsightResult {
        InsightResult(text: Self.cancelReasonText(for: facts), isGenerated: false)
    }

    static func monthlyText(for facts: MonthlyInsightFacts) -> String {
        if facts.hasCancelCandidates {
            return "しばらく使っていないサブスクがあるようです。続けるか見直してみませんか？"
        }
        if facts.hasDuplicates {
            return "同じジャンルのサブスクが重なっています。まとめられないか考えてみましょう。"
        }
        if facts.canceledThisMonthCount > 0 {
            return "今月は見直しが進みました。この調子で見張りを続けましょう。"
        }
        switch facts.trend {
        case .increased:
            return "先月より支払いが増えています。新しいサブスクが本当に必要か確かめてみましょう。"
        case .decreased:
            return "先月より支払いが減りました。この調子で見張りを続けましょう。"
        case .unchanged, .unknown:
            return monthlyDefault
        }
    }

    static func cancelReasonText(for facts: CancelReasonFacts) -> String {
        if facts.hasSameCategoryAlternative {
            return "しばらく使っておらず、同じジャンルのサービスも契約中です。まとめられないか見直してみませんか？"
        }
        if facts.cycle == .yearly {
            return "しばらく使っていないようです。次の更新の前に、続けるか考えてみませんか？"
        }
        return cancelReasonDefault
    }
}

/// AI の出力のチェック。数値・金額を含むものや長すぎるものは使わない（2章の原則1）。
nonisolated enum InsightSanitizer {
    /// 文字数の上限に対する許容量（多少の超過は表示できるので、テンプレートに落とさない）
    static let lengthTolerance = 20

    static func sanitize(_ text: String, maxLength: Int, allowedTerms: [String] = []) -> String? {
        var result = text.trimmingCharacters(in: .whitespacesAndNewlines)
        // 前後の括弧・引用符を外す
        let quotePairs: [(Character, Character)] = [("「", "」"), ("『", "』"), ("\"", "\""), ("“", "”")]
        for (open, close) in quotePairs where result.first == open && result.last == close && result.count >= 2 {
            result = String(result.dropFirst().dropLast())
        }
        result = result
            .replacingOccurrences(of: "\n", with: "")
            .trimmingCharacters(in: .whitespaces)

        guard !result.isEmpty, result.count <= maxLength + lengthTolerance else { return nil }

        // サービス名に含まれる数字・英字（例：Microsoft 365）は許可したうえで、
        // 数値・金額や、英単語の混入（日本語で書けていない）がないか確かめる
        var checked = result
        for term in allowedTerms.sorted(by: { $0.count > $1.count }) where !term.isEmpty {
            checked = checked.replacingOccurrences(of: term, with: "", options: [.caseInsensitive, .widthInsensitive])
        }
        let forbidden = CharacterSet.decimalDigits
            .union(CharacterSet(charactersIn: "円¥￥%％"))
            .union(CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"))
        guard checked.rangeOfCharacter(from: forbidden) == nil else { return nil }
        return result
    }
}
