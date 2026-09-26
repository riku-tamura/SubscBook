import Foundation

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
