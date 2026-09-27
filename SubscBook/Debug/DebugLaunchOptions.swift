#if DEBUG
import Foundation

/// 開発用の起動オプション（Scheme の Arguments や simctl launch で指定する）
enum DebugLaunchOptions {
    private static let arguments = ProcessInfo.processInfo.arguments

    /// 既存データを消してサンプルデータを入れる
    static let seedsSampleData = arguments.contains("-seedSampleData")
    /// 購入せずにサブスク帳プラスを有効にする
    static let forcesPremium = arguments.contains("-forcePremium")
    /// StoreKit の商品が読めない環境で、ペイウォールにサンプルのプランを表示する
    static let usesSamplePlans = arguments.contains("-samplePlans")
    /// オンボーディングを表示しない
    static let skipsOnboarding = arguments.contains("-skipOnboarding")
    /// 全画面広告の回数のルール（使い始めの3日間など）を無視して、毎回出す
    static let ignoresAdLimits = arguments.contains("-ignoreAdLimits")
    /// 単体テストのホストとして起動している（トラッキングの許可のダイアログや広告を出さない）
    static let isRunningTests = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
}
#endif
