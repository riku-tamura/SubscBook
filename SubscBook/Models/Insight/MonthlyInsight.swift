#if canImport(FoundationModels)
import FoundationModels

/// AI の月次振り返りの出力形式（8.3）
@available(iOS 26.0, *)
@Generable
struct MonthlyInsight {
    @Guide(description: "ユーザーへのひとことコメント。60文字以内。数値や金額は書かない。前向きで押しつけがましくない口調。")
    var comment: String
}
#endif
