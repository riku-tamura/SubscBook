import Foundation

/// 解約候補（5.3）
struct CancelSuggestion: Identifiable {
    let subscription: Subscription
    /// 最新の回答月から遡って連続した「使っていない」月数
    let unusedMonths: Int
    /// 1年あたりの支払額
    let annualCost: Int

    var id: UUID { subscription.id }
}
