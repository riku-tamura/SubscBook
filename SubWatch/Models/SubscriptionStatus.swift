import Foundation

nonisolated enum SubscriptionStatus: String, Codable, CaseIterable, Sendable {
    case active
    case canceled
}
