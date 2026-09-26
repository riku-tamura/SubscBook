import Foundation

/// 契約中か解約済みか
nonisolated enum SubscriptionStatus: String, Codable, CaseIterable, Sendable {
    case active
    case canceled
}
