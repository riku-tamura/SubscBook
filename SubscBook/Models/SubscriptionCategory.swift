import Foundation

/// サブスクのカテゴリ。表示色・アイコンは `SubscriptionCategory+Style.swift` で定義する。
nonisolated enum SubscriptionCategory: String, Codable, CaseIterable, Identifiable, Sendable {
    case video
    case music
    case reading
    case game
    case cloud
    case work
    case fitness
    case learning
    case news
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .video: "動画"
        case .music: "音楽"
        case .reading: "読書・雑誌"
        case .game: "ゲーム"
        case .cloud: "クラウド・ストレージ"
        case .work: "仕事・ツール"
        case .fitness: "フィットネス"
        case .learning: "学習"
        case .news: "ニュース"
        case .other: "その他"
        }
    }

    /// 重複検出（5.4）の対象になるか。「その他」は性質の違うサービスが混ざるため除外する。
    var isDuplicateDetectionTarget: Bool {
        self != .other
    }
}
