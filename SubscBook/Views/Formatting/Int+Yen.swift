import Foundation

extension Int {
    /// "1,490円"
    nonisolated var yenText: String {
        "\(formatted(.number.locale(.japanese)))円"
    }
}
