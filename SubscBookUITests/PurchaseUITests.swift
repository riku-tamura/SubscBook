import StoreKitTest
import XCTest

/// サブスク帳プラスの購入の流れを、画面を操作して確かめる UI テスト。
/// StoreKit Testing（Products.storekit）で動かすので、本物のお金はかからない（App Store Connect の商品も使わない）。
/// 購入の確認画面は出さない設定（disableDialogs）にして、購入・期限切れ・復元をテストから操作する。
final class PurchaseUITests: XCTestCase {
    private var session: SKTestSession!

    override func setUpWithError() throws {
        continueAfterFailure = true
        session = try SKTestSession(configurationFileNamed: "Products")
        session.resetToDefaultState()
        session.disableDialogs = true
        session.clearTransactions()
    }

    override func tearDown() {
        // テストの購入を、次のテストやアプリの確認に残さない
        session?.clearTransactions()
    }

    /// 年額（1週間無料）を購入 → プラスの機能が開き、広告の案内が消える → 期限が切れると無料に戻る
    func test01_YearlyTrialPurchaseAndExpire() throws {
        let app = launch()
        openPaywallFromSettings(app)
        snap("P01-1 ペイウォール（StoreKit の価格）")
        XCTAssertTrue(app.staticTexts["2,400円/年"].exists, "年額の価格が出ない")
        XCTAssertTrue(app.staticTexts["月あたり200円"].exists, "月あたりの金額が出ない")

        let trialButton = app.buttons["1週間無料で試す"]
        XCTAssertTrue(trialButton.waitForExistence(timeout: 10), "無料体験のボタンがない")
        trialButton.tap()
        XCTAssertTrue(app.alerts["ありがとうございます"].waitForExistence(timeout: 15), "購入が完了しない")
        snap("P01-2 購入完了")
        app.alerts.buttons["OK"].tap()
        sleep(2)

        tab(app, "設定")
        snap("P01-3 設定（無料体験中）")
        // 設定の行は「見出し、値」をまとめて読み上げるので、含まれているかで確かめる
        XCTAssertTrue(element(app, containing: "年額プラン").waitForExistence(timeout: 5), "プラン名が出ない")
        XCTAssertTrue(element(app, containing: "無料トライアル中").exists, "無料体験中と出ない")
        XCTAssertTrue(element(app, containing: "無料期間の終了日").exists, "無料期間の終了日が出ない")
        app.swipeUp()
        XCTAssertFalse(app.buttons["広告を非表示にする"].exists, "プラスなのに広告の案内が出ている")

        tab(app, "レポート")
        app.swipeUp()
        snap("P01-4 レポート（プラスで開いた）")
        XCTAssertFalse(app.staticTexts["サブスク帳プラスで利用できます"].exists, "プラスなのに鍵が付いている")

        // 期限切れ：アプリが前面に戻ったときに読み直して、無料に戻る
        try session.expireSubscription(productIdentifier: "com.hachimaki.SubscBook.premium.yearly")
        XCUIDevice.shared.press(.home)
        sleep(2)
        app.activate()
        tab(app, "設定")
        app.swipeDown()
        app.swipeDown()
        let upgrade = app.buttons.containing(NSPredicate(format: "label CONTAINS %@", "アップグレード")).firstMatch
        XCTAssertTrue(upgrade.waitForExistence(timeout: 15), "期限が切れても無料に戻らない")
        snap("P01-5 設定（期限切れで無料に戻った）")
    }

    /// 月額を購入 → 設定から購入を復元できる
    func test02_MonthlyPurchaseAndRestore() {
        let app = launch()
        openPaywallFromSettings(app)
        let monthly = app.buttons.containing(NSPredicate(format: "label CONTAINS %@", "月額プラン")).firstMatch
        XCTAssertTrue(monthly.waitForExistence(timeout: 10), "月額プランがない")
        monthly.tap()
        let buy = app.buttons["300円/月で登録する"]
        XCTAssertTrue(buy.waitForExistence(timeout: 5), "月額の購入ボタンがない")
        snap("P02-1 ペイウォール（月額を選択）")
        buy.tap()
        XCTAssertTrue(app.alerts["ありがとうございます"].waitForExistence(timeout: 15), "購入が完了しない")
        app.alerts.buttons["OK"].tap()
        sleep(2)

        tab(app, "設定")
        XCTAssertTrue(element(app, containing: "月額プラン").waitForExistence(timeout: 5), "プラン名が出ない")
        XCTAssertTrue(element(app, containing: "次回の更新日").exists, "次回の更新日が出ない")
        snap("P02-2 設定（月額プラン）")

        let restore = app.buttons["購入を復元"]
        XCTAssertTrue(restore.waitForExistence(timeout: 5))
        restore.tap()
        let alert = app.alerts["購入の復元"]
        XCTAssertTrue(alert.waitForExistence(timeout: 20), "復元の結果が出ない")
        snap("P02-3 購入の復元")
        XCTAssertTrue(alert.staticTexts["サブスク帳プラスの購入を復元しました。"].exists, "復元できない")
        alert.buttons["OK"].tap()
    }

    /// 購入がないときに復元すると、見つからないと伝える
    func test03_RestoreWithoutPurchase() {
        let app = launch()
        tab(app, "設定")
        let restore = app.buttons["購入を復元"]
        XCTAssertTrue(restore.waitForExistence(timeout: 5))
        restore.tap()
        let alert = app.alerts["購入の復元"]
        XCTAssertTrue(alert.waitForExistence(timeout: 20), "復元の結果が出ない")
        snap("P03-1 購入がないときの復元")
        XCTAssertTrue(
            alert.staticTexts["この Apple ID でサブスク帳プラスの購入が見つかりませんでした。"].exists,
            "購入がないのに見つからないと出ない"
        )
        alert.buttons["OK"].tap()
    }

    /// 購入後、設定の「サブスク帳プラスの契約を管理」から、契約の管理（解約）の画面が開く
    func test04_ManageSubscription() {
        let app = launch()
        openPaywallFromSettings(app)
        let trialButton = app.buttons["1週間無料で試す"]
        XCTAssertTrue(trialButton.waitForExistence(timeout: 10), "無料体験のボタンがない")
        trialButton.tap()
        XCTAssertTrue(app.alerts["ありがとうございます"].waitForExistence(timeout: 15), "購入が完了しない")
        app.alerts.buttons["OK"].tap()
        sleep(2)

        tab(app, "設定")
        let manage = app.buttons["サブスク帳プラスの契約を管理"]
        XCTAssertTrue(manage.waitForExistence(timeout: 5), "契約を管理のボタンがない")
        manage.tap()
        sleep(4)
        snap("P04-1 契約の管理")
        let attachment = XCTAttachment(string: app.debugDescription)
        attachment.name = "P04-1 画面の構造"
        attachment.lifetime = .keepAlways
        add(attachment)
        // 契約の管理の画面が前に出て、設定のボタンが押せなくなる
        XCTAssertFalse(manage.isHittable, "契約の管理の画面が開かない")
    }

    // MARK: - 補助

    private func launch() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-seedSampleData", "-skipOnboarding"]
        app.launch()
        sleep(4)
        return app
    }

    private func openPaywallFromSettings(_ app: XCUIApplication) {
        tab(app, "設定")
        let upgrade = app.buttons.containing(NSPredicate(format: "label CONTAINS %@", "アップグレード")).firstMatch
        XCTAssertTrue(upgrade.waitForExistence(timeout: 10), "アップグレードのボタンがない（プラスのまま？）")
        upgrade.tap()
        sleep(3)
    }

    private func element(_ app: XCUIApplication, containing text: String) -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", text)).firstMatch
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
