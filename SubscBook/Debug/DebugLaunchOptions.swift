#if DEBUG
import Foundation

/// 開発用の起動オプション（Scheme の Arguments や simctl launch で指定する）
enum DebugLaunchOptions {
    private static let arguments = ProcessInfo.processInfo.arguments

    /// 既存データを消してサンプルデータを入れる
    static let seedsSampleData = arguments.contains("-seedSampleData") || seedsStoreScreenshotData
    /// サンプルデータを、実在のサービス名の代わりに一般的な名前で入れる（App Store のスクリーンショット用）
    static let seedsStoreScreenshotData = arguments.contains("-storeScreenshotData")
    /// オンボーディングを最初から表示する（UI テスト用）。
    /// `-onboarding.completed NO` のように引数で値を渡すと、アプリが「終えた」と保存しても引数の値が優先されて終われないため、起動時に消す。
    static let resetsOnboarding = arguments.contains("-resetOnboarding")
    /// 既存データを消して空にする（UI テストでオンボーディングから確かめるため）
    static let clearsData = arguments.contains("-emptyData")
    /// アプリが実際に作るチェックイン・支払日の前日の通知を、1〜2分後に届くようにずらして登録する（UI テストで、実機で届くこと・通知から開くことを確かめるため）
    static let schedulesTestNotification = arguments.contains("-scheduleTestNotification")
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
