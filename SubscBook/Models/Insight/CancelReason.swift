#if canImport(FoundationModels)
import FoundationModels

/// AI が書く解約候補の理由の出力形式（8.3）
@available(iOS 26.0, *)
@Generable
struct CancelReason {
    @Guide(description: "解約を検討してよい理由の説明。80文字以内。数値や金額は書かない。断定せず提案の形にする。")
    var reason: String
}
#endif
