import Foundation
import Observation

/// 見張り番プラスの購読状態を一元管理する。StoreKit 連携は Phase 5 で実装する。
@Observable
final class EntitlementManager {
    private(set) var isPremium = false
}
