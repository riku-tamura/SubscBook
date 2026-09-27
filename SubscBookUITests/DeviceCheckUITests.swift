import XCTest

/// 実機での確認用の UI テスト。画面を操作しながらスクリーンショットを残す（結果の xcresult から取り出して見る）。
/// 実行の順番に意味があるので、名前の先頭に番号を付けている（XCTest は名前の順に動かす）。
/// 開発用の起動オプション（Debug ビルドのみ）で、データやプランの状態を決めてから起動する。
final class DeviceCheckUITests: XCTestCase {
    private let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")

    override func setUp() {
        continueAfterFailure = true
    }

    // MARK: - 手順

    /// オンボーディング → 通知の許可 → スキップ → トラッキングの許可
    func test01_Onboarding() {
        let app = launch(["-emptyData", "-onboarding.completed", "NO"])
        XCTAssertTrue(app.buttons["はじめる"].waitForExistence(timeout: 10))
        snap("01-1 オンボーディング1")
        app.buttons["はじめる"].tap()

        XCTAssertTrue(app.buttons["通知を許可する"].waitForExistence(timeout: 5))
        snap("01-2 オンボーディング2")
        app.buttons["通知を許可する"].tap()
        tapSystemAlert(["許可"], name: "01-3 通知の許可のダイアログ")

        let skip = app.buttons["スキップ"]
        XCTAssertTrue(skip.waitForExistence(timeout: 10))
        sleep(1)
        snap("01-4 オンボーディング3")
        // ページの切り替えの途中だと押せないことがあるので、画面が変わるまで押し直す
        for _ in 0..<3 where skip.exists {
            skip.tap()
            sleep(2)
        }
        XCTAssertFalse(skip.exists, "スキップしても画面が変わらない")

        tapSystemAlert(["許可"], name: "01-5 トラッキングの許可のダイアログ", timeout: 15)
        sleep(6)
        snap("01-6 ホーム（データなし・バナー広告）")
    }

    /// 無料プラン：ホーム・一覧・レポート・設定・ペイウォール
    func test02_FreeScreens() {
        let app = launch(["-seedSampleData", "-skipOnboarding", "-samplePlans"])
        sleep(6)
        snap("02-1 ホーム")
        app.swipeUp()
        snap("02-2 ホーム（下）")

        tab(app, "一覧")
        snap("02-3 一覧")

        tab(app, "レポート")
        snap("02-4 レポート")
        app.swipeUp()
        snap("02-5 レポート（下・ぼかし）")

        tab(app, "設定")
        snap("02-6 設定")
        // iOS 26 未満・非対応の機種では、AIコメントが使える条件（機種と iOS）を説明する
        let aiNote = app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "AIコメントは")).firstMatch
        if aiNote.exists {
            let text = XCTAttachment(string: aiNote.label)
            text.name = "02-6 AIの説明"
            text.lifetime = .keepAlways
            add(text)
        }
        app.swipeUp()
        snap("02-7 設定（下）")

        let hideAds = app.buttons["広告を非表示にする"]
        if hideAds.waitForExistence(timeout: 3) {
            hideAds.tap()
            sleep(2)
            snap("02-8 ペイウォール")
            app.swipeUp()
            snap("02-9 ペイウォール（下）")
        } else {
            XCTFail("設定に「広告を非表示にする」がない")
        }
    }

    /// サブスク帳プラス：解約候補・重複・節約レポートが見え、広告が出ない
    func test03_PremiumScreens() {
        let app = launch(["-seedSampleData", "-skipOnboarding", "-forcePremium"])
        sleep(5)
        snap("03-1 ホーム（プラス）")
        tab(app, "レポート")
        app.swipeUp()
        snap("03-2 レポート（プラス）")
        tab(app, "設定")
        snap("03-3 設定（プラス）")
    }

    /// チェックイン：ボタンとスワイプで答え、閉じると全画面広告が出る
    func test04_CheckInAndInterstitial() {
        let app = launch(["-seedSampleData", "-skipOnboarding", "-ignoreAdLimits"])
        sleep(6)
        let banner = app.buttons.containing(NSPredicate(format: "label CONTAINS %@", "のチェックイン")).firstMatch
        XCTAssertTrue(banner.waitForExistence(timeout: 5))
        banner.tap()

        XCTAssertTrue(app.buttons["使っていない"].waitForExistence(timeout: 5))
        snap("04-1 チェックイン")
        app.buttons["使っていない"].tap()
        sleep(1)
        // カードを左にスワイプ（使っていない）
        let card = app.otherElements.containing(NSPredicate(format: "label CONTAINS %@", "使いましたか")).firstMatch
        if card.exists {
            card.swipeLeft()
        } else {
            app.buttons["使っていない"].tap()
        }
        sleep(1)
        snap("04-2 チェックイン（スワイプ後）")
        if app.buttons["使った"].exists {
            app.buttons["使った"].tap()
        }
        sleep(1)
        snap("04-3 チェックイン完了")

        let close = app.buttons.matching(identifier: "閉じる").element(boundBy: app.buttons.matching(identifier: "閉じる").count - 1)
        close.tap()
        sleep(4)
        snap("04-4 閉じた後（全画面広告）")
    }

    /// 登録と解約（プラスで上限なし）
    func test05_AddAndCancel() {
        let app = launch(["-seedSampleData", "-skipOnboarding", "-forcePremium"])
        sleep(3)
        tab(app, "一覧")
        app.navigationBars.buttons["追加"].firstMatch.tap()

        let name = app.textFields.firstMatch
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        snap("05-1 登録画面")
        name.tap()
        name.typeText("Test")
        let price = app.textFields["金額（円）"]
        if price.exists {
            price.tap()
            price.typeText("1200")
        }
        snap("05-2 登録画面（入力後）")
        app.buttons["保存"].tap()
        sleep(2)
        snap("05-3 一覧（登録後）")

        let unext = app.buttons.containing(NSPredicate(format: "label BEGINSWITH %@", "U-NEXT")).firstMatch
        XCTAssertTrue(unext.waitForExistence(timeout: 5))
        unext.tap()
        let cancel = app.buttons["解約した"]
        XCTAssertTrue(cancel.waitForExistence(timeout: 5))
        cancel.tap()
        XCTAssertTrue(app.buttons["記録する"].waitForExistence(timeout: 5))
        snap("05-4 解約日の選択")
        app.buttons["記録する"].tap()
        sleep(2)
        snap("05-5 一覧（解約後）")
    }

    /// ダークモードといちばん大きな文字
    func test06_DarkModeAndLargestText() {
        XCUIDevice.shared.appearance = .dark
        defer { XCUIDevice.shared.appearance = .light }
        let app = launch([
            "-seedSampleData", "-skipOnboarding", "-forcePremium",
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL",
        ])
        sleep(3)
        snap("06-1 ホーム（ダーク・最大の文字）")
        tab(app, "一覧")
        snap("06-2 一覧（ダーク・最大の文字）")
        tab(app, "レポート")
        snap("06-3 レポート（ダーク・最大の文字）")
        tab(app, "ホーム")
        let banner = app.buttons.containing(NSPredicate(format: "label CONTAINS %@", "のチェックイン")).firstMatch
        if banner.waitForExistence(timeout: 3) {
            banner.tap()
            sleep(2)
            snap("06-4 チェックイン（ダーク・最大の文字）")
        }
    }

    /// アプリを終了した状態で、通知をタップして開く
    func test07_OpenFromNotificationWhenTerminated() {
        let app = launch(["-seedSampleData", "-skipOnboarding", "-scheduleTestNotification"])
        sleep(4)
        app.terminate()

        let notification = springboard.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS %@", "月次チェックインの時間です")).firstMatch
        XCTAssertTrue(notification.waitForExistence(timeout: 20), "通知が届かない")
        snap("07-1 届いた通知")
        notification.tap()

        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 15), "通知からアプリが開かない")
        let question = app.buttons["使っていない"]
        XCTAssertTrue(question.waitForExistence(timeout: 10), "チェックインが開かない")
        snap("07-2 通知から開いた画面")
    }

    /// 節約レポートの画像を写真に保存する
    func test08_SaveShareImage() {
        let app = launch(["-seedSampleData", "-skipOnboarding", "-forcePremium"])
        sleep(3)
        tab(app, "レポート")
        app.swipeUp()
        app.swipeUp()
        let share = app.buttons["画像でシェア"]
        XCTAssertTrue(share.waitForExistence(timeout: 5))
        share.tap()
        sleep(2)
        snap("08-1 共有メニュー")
        let save = app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", "画像を保存")).firstMatch
        if save.waitForExistence(timeout: 5) {
            save.tap()
            tapSystemAlert(["許可", "フルアクセスを許可"], name: "08-2 写真への追加の許可")
            sleep(1)
            snap("08-3 保存後")
        } else {
            XCTFail("共有メニューに「画像を保存」がない")
        }
    }

    /// アクセシビリティの自動チェック（Apple の監査）。問題は失敗にせず、記録して報告する。
    func test09_AccessibilityAudit() throws {
        let app = launch(["-seedSampleData", "-skipOnboarding", "-forcePremium"])
        sleep(3)
        var report: [String] = []
        for screen in ["ホーム", "一覧", "レポート", "設定"] {
            tab(app, screen)
            sleep(1)
            try app.performAccessibilityAudit { issue in
                report.append("[\(screen)] \(issue.auditType): \(issue.compactDescription) — \(issue.element?.label ?? "-")")
                return true
            }
        }
        let attachment = XCTAttachment(string: report.isEmpty ? "問題なし" : report.joined(separator: "\n"))
        attachment.name = "09 アクセシビリティ監査"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// データの全削除
    func test10_DeleteAllData() {
        let app = launch(["-seedSampleData", "-skipOnboarding"])
        sleep(3)
        tab(app, "設定")
        app.swipeUp()
        app.swipeUp()
        let delete = app.buttons["データの全削除"]
        XCTAssertTrue(delete.waitForExistence(timeout: 5))
        delete.tap()
        let confirm = app.buttons["すべて削除"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 5))
        confirm.tap()
        let ok = app.buttons["OK"]
        if ok.waitForExistence(timeout: 5) { ok.tap() }
        tab(app, "ホーム")
        sleep(1)
        snap("10-1 ホーム（全削除後）")
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
        } else {
            app.buttons[name].firstMatch.tap()
        }
        sleep(1)
    }

    /// 画面全体（システムのダイアログを含む）のスクリーンショットを残す
    private func snap(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// システムのダイアログ（通知・トラッキング・写真の許可）のボタンを押す。
    /// すでに許可を答えている端末では出ないので、出なかったことは記録だけして失敗にしない。
    private func tapSystemAlert(_ labels: [String], name: String, timeout: TimeInterval = 10) {
        let alert = springboard.alerts.firstMatch
        guard alert.waitForExistence(timeout: timeout) else {
            let note = XCTAttachment(string: "ダイアログが出なかった（すでに答え済みの可能性）：\(name)")
            note.name = "note \(name)"
            note.lifetime = .keepAlways
            add(note)
            return
        }
        snap(name)
        for label in labels where alert.buttons[label].exists {
            alert.buttons[label].tap()
            return
        }
        XCTFail("ダイアログにボタン \(labels) がない：\(alert.buttons.allElementsBoundByIndex.map(\.label))")
    }
}
