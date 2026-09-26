import Foundation
import Testing
@testable import SubscBook

@Suite("AI 出力のチェック")
struct InsightSanitizerTests {
    @Test("前後の空白・括弧を取り除く")
    func trims() {
        #expect(InsightSanitizer.sanitize("  「見直してみませんか？」\n", maxLength: 60) == "見直してみませんか？")
    }

    @Test("数値・金額・英単語を含む出力は使わない", arguments: [
        "月に千円ほど節約できます。1ヶ月使っていません。",
        "年間１２０００円の節約です",
        "円が浮きそうです",
        "少しだけ unused があるみたいです",
        "５割ほど減りました％",
    ])
    func rejectsNumbers(text: String) {
        #expect(InsightSanitizer.sanitize(text, maxLength: 80) == nil)
    }

    @Test("サービス名に含まれる数字・英字は許可する")
    func allowsServiceNames() {
        let text = "Microsoft 365 はしばらく使っていないようです。見直してみませんか？"
        #expect(InsightSanitizer.sanitize(text, maxLength: 80, allowedTerms: ["Microsoft 365", "仕事・ツール"]) == text)
        #expect(InsightSanitizer.sanitize("u-nextを見直しませんか", maxLength: 80, allowedTerms: ["U-NEXT"]) != nil)
    }

    @Test("長すぎる出力・空の出力は使わない")
    func rejectsLength() {
        #expect(InsightSanitizer.sanitize(String(repeating: "あ", count: 80), maxLength: 60) == "\(String(repeating: "あ", count: 80))")
        #expect(InsightSanitizer.sanitize(String(repeating: "あ", count: 81), maxLength: 60) == nil)
        #expect(InsightSanitizer.sanitize("   ", maxLength: 60) == nil)
    }
}
