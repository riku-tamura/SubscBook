import Foundation

/// サブスク帳プラスで使える機能（6章）
nonisolated enum PremiumFeature: String, CaseIterable, Identifiable, Sendable {
    case unlimitedSubscriptions
    case adFree
    case trialReminders
    case cancelSuggestions
    case duplicateDetection
    case savingsReport

    var id: String { rawValue }

    var title: String {
        switch self {
        case .unlimitedSubscriptions: "サブスクを無制限に登録"
        case .adFree: "広告なし"
        case .trialReminders: "無料トライアル終了の事前通知"
        case .cancelSuggestions: "解約候補の提案"
        case .duplicateDetection: "重複サブスクの検出"
        case .savingsReport: "年間節約レポート"
        }
    }

    var detail: String {
        switch self {
        case .unlimitedSubscriptions: "無料プランの5件を超えて登録できます"
        case .adFree: "バナーや全画面の広告を表示しません"
        case .trialReminders: "終了の3日前と前日にお知らせします"
        case .cancelSuggestions: "チェックインで「使っていない」が続くサブスクを、理由付きでお知らせします"
        case .duplicateDetection: "同じジャンルで重なっているサブスクを見つけます"
        case .savingsReport: "解約で浮くお金をまとめて、画像でシェアできます"
        }
    }

    var symbolName: String {
        switch self {
        case .unlimitedSubscriptions: "infinity"
        case .adFree: "rectangle.slash"
        case .trialReminders: "bell.badge"
        case .cancelSuggestions: "scissors"
        case .duplicateDetection: "square.on.square"
        case .savingsReport: "chart.line.uptrend.xyaxis"
        }
    }
}
