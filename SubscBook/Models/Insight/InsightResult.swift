import Foundation

nonisolated struct InsightResult: Hashable, Sendable {
    let text: String
    /// AI が生成したか（false はテンプレート文。キャッシュしない）
    let isGenerated: Bool
}
