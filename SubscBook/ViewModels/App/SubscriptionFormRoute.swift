import Foundation

enum SubscriptionFormRoute: Identifiable {
    case add
    case edit(Subscription)

    var id: String {
        switch self {
        case .add: "add"
        case .edit(let subscription): subscription.id.uuidString
        }
    }
}
