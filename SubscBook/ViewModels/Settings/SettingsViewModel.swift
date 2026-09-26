import Foundation
import Observation
import SwiftData

/// 設定画面の状態と操作
@Observable
final class SettingsViewModel {
    private(set) var isRestoring = false
    /// 購入の復元の結果（アラートで表示する）
    var restoreMessage: String?
    /// データの全削除の結果（アラートで表示する）
    var deletionMessage: String?

    /// "1.0（1）"
    var appVersion: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "-"
        let build = info?["CFBundleVersion"] as? String ?? "-"
        return "\(version)（\(build)）"
    }

    /// 加入中のプラン名
    func planName(of entitlements: EntitlementManager) -> String {
        guard let plan = entitlements.activePlan else { return "サブスク帳プラス" }
        return plan.isYearly ? "年額プラン" : "月額プラン"
    }

    func restorePurchases(using entitlements: EntitlementManager) async {
        isRestoring = true
        defer { isRestoring = false }
        do {
            try await entitlements.restore()
            restoreMessage = entitlements.isPremium
                ? "サブスク帳プラスの購入を復元しました。"
                : "この Apple ID でサブスク帳プラスの購入が見つかりませんでした。"
        } catch {
            restoreMessage = "復元できませんでした。時間をおいて、もう一度お試しください。"
        }
    }

    /// 登録したサブスクとチェックインをすべて削除し、AI のコメントと通知も消す
    func deleteAllData(in context: ModelContext, insights: InsightProvider, notifications: NotificationScheduler) {
        do {
            // @Query の表示が確実に更新されるよう、1件ずつ削除する（チェックインは連鎖して消える）
            for subscription in try context.fetch(FetchDescriptor<Subscription>()) {
                context.delete(subscription)
            }
            for checkIn in try context.fetch(FetchDescriptor<CheckIn>()) {
                context.delete(checkIn)
            }
            try context.save()
            insights.clearCache()
            notifications.reschedule()
            deletionMessage = "すべてのデータを削除しました。"
        } catch {
            deletionMessage = "削除できませんでした。もう一度お試しください。"
        }
    }
}
