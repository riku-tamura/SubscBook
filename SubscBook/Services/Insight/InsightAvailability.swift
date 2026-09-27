import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

/// 端末内 AI（Apple Intelligence）が使えるか（8.1）
nonisolated enum InsightAvailability: Equatable, Sendable {
    case available
    /// iOS 26 未満
    case unsupportedOS
    /// Apple Intelligence 非対応の端末
    case deviceNotEligible
    /// Apple Intelligence がオフ
    case appleIntelligenceNotEnabled
    /// モデルのダウンロード中など
    case modelNotReady
    /// 日本語に対応していない
    case unsupportedLanguage
    case unavailable

    var isAvailable: Bool { self == .available }

    /// 設定画面に表示する説明
    var message: String {
        switch self {
        case .available:
            "Apple Intelligence を使って、端末の中だけでコメントを作成しています。"
        case .unsupportedOS:
            "AIコメントは、Apple Intelligence に対応した iPhone（iPhone 15 Pro 以降）で iOS 26 以降のときに利用できます。現在は定型のコメントを表示しています。"
        case .deviceNotEligible:
            "この端末は Apple Intelligence に対応していないため、定型のコメントを表示しています。"
        case .appleIntelligenceNotEnabled:
            "Apple Intelligence がオフになっています。設定アプリの「Apple Intelligence と Siri」でオンにすると、AIコメントが使えます。"
        case .modelNotReady:
            "AIモデルを準備中です。準備ができるまでは定型のコメントを表示します。"
        case .unsupportedLanguage:
            "現在の設定では AIコメントを日本語で作成できないため、定型のコメントを表示しています。"
        case .unavailable:
            "AIコメントを利用できないため、定型のコメントを表示しています。"
        }
    }

    static func current() -> InsightAvailability {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            let model = SystemLanguageModel.default
            switch model.availability {
            case .available:
                return model.supportsLocale(Locale(identifier: "ja_JP")) ? .available : .unsupportedLanguage
            case .unavailable(.deviceNotEligible):
                return .deviceNotEligible
            case .unavailable(.appleIntelligenceNotEnabled):
                return .appleIntelligenceNotEnabled
            case .unavailable(.modelNotReady):
                return .modelNotReady
            case .unavailable:
                return .unavailable
            }
        }
        #endif
        return .unsupportedOS
    }
}
