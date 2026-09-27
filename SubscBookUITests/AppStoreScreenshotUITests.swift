import StoreKitTest
import XCTest

/// App Store に載せるスクリーンショットを撮る UI テスト。6.9インチのシミュレータ（iPhone 17 Pro Max）で動かし、結果（xcresult）から画像を取り出す。
/// ほかの会社の商標を載せないように、サービス名を一般的な名前にしたサンプルデータ（`-storeScreenshotData`）を使う。
/// 撮り方は docs/app-store.md の「スクリーンショット」。
final class AppStoreScreenshotUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = true
    }

    /// サブスク帳プラスの画面（広告なし）：ホーム・一覧・チェックイン・レポート
    func test01_PremiumScreens() {
        let app = launch(["-storeScreenshotData", "-skipOnboarding", "-forcePremium"])
        sleep(4)
        snap("1 ホーム")

        tab(app, "一覧")
        snap("2 一覧")

        tab(app, "レポート")
        snap("4 レポート")
        let savings = app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "解約候補")).firstMatch
        for _ in 0..<3 where !(savings.exists && savings.isHittable) {
            app.swipeUp()
        }
        sleep(1)
        snap("5 レポート（解約候補）")

        tab(app, "ホーム")
        let banner = app.buttons.containing(NSPredicate(format: "label CONTAINS %@", "のチェックイン")).firstMatch
        XCTAssertTrue(banner.waitForExistence(timeout: 5), "チェックインの案内がない")
        banner.tap()
        XCTAssertTrue(app.buttons["使っていない"].waitForExistence(timeout: 5))
        sleep(1)
        snap("3 チェックイン")
    }

    /// ペイウォール（無料の状態から開く）。サブスクリプションの審査用のスクリーンショットにも使う
    func test02_Paywall() throws {
        let session = try SKTestSession(configurationFileNamed: "Products")
        session.resetToDefaultState()
        session.disableDialogs = true
        session.clearTransactions()

        let app = launch(["-storeScreenshotData", "-skipOnboarding"])
        sleep(3)
        tab(app, "設定")
        let upgrade = app.buttons.containing(NSPredicate(format: "label CONTAINS %@", "アップグレード")).firstMatch
        XCTAssertTrue(upgrade.waitForExistence(timeout: 10), "アップグレードのボタンがない")
        upgrade.tap()
        XCTAssertTrue(app.buttons["1週間無料で試す"].waitForExistence(timeout: 10), "ペイウォールの価格が読めない")
        sleep(1)
        snap("6 ペイウォール")
        // 購入のボタンと注意書きまで入れた画像（サブスクリプションの審査用）
        app.swipeUp()
        sleep(1)
        snap("7 ペイウォール（下）")
    }

    // MARK: - 補助

    private func launch(_ arguments: [String]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = arguments
        app.launch()
        return app
    }

    private func tab(_ app: XCUIApplication, _ name: String) {
        let button = app.tabBars.buttons[name]
        if button.waitForExistence(timeout: 5) {
            button.tap()
        }
        sleep(1)
    }

    private func snap(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
