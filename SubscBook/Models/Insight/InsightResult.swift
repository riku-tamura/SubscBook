import Foundation

/// AI コメントの生成結果
nonisolated struct InsightResult: Hashable, Sendable {
    let text: String
    /// AI が生成したか（false はテンプレート文。キャッシュしない）
    let isGenerated: Bool
}
