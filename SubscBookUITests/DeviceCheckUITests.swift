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
        let app = launch(["-emptyData", "-resetOnboarding"])
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
        record(app.debugDescription, name: "01-4 画面の構造（スキップの前）")
        // ページの切り替えの途中だと押せないことがあるので、画面が変わるまで押し直す
        for _ in 0..<3 where skip.exists {
            skip.tap()
            sleep(2)
        }
        if skip.exists {
            record(app.debugDescription, name: "01-4 画面の構造（スキップの後）")
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
        moveAssistiveTouchAwayFromTopRight()
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
        // 1〜2分後の、ちょうどの分に届く
        XCTAssertTrue(notification.waitForExistence(timeout: 100), "通知が届かない")
        snap("07-1 届いた通知")
        notification.tap()

        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 15), "通知からアプリが開かない")
        let question = app.buttons["使っていない"]
        XCTAssertTrue(question.waitForExistence(timeout: 10), "チェックインが開かない")
        snap("07-2 通知から開いた画面")
    }

    /// 登録された通知の時刻を確かめる：支払日の前日・トライアル終了は 9:00、月次チェックインは毎月1日 20:00
    func test11_ScheduledNotificationTimes() {
        let app = launch(["-seedSampleData", "-skipOnboarding", "-forcePremium"])
        sleep(4)
        tab(app, "設定")
        app.swipeUp()
        app.swipeUp()
        let link = app.buttons.containing(NSPredicate(format: "label BEGINSWITH %@", "登録済みの通知")).firstMatch
        XCTAssertTrue(link.waitForExistence(timeout: 5))
        record(link.label, name: "11 登録済みの通知の件数")
        link.tap()
        sleep(2)
        snap("11-1 登録済みの通知")

        // 各行は「タイトル・本文・次に届く日時」の3つの文字
        var rows: Set<String> = []
        for _ in 0..<6 {
            for cell in app.cells.allElementsBoundByIndex where cell.exists {
                let texts = cell.staticTexts.allElementsBoundByIndex.map(\.label)
                if texts.count >= 3 { rows.insert(texts[0] + " → " + texts[2]) }
            }
            app.swipeUp()
        }
        record(rows.sorted().joined(separator: "\n"), name: "11 通知と次に届く日時")

        XCTAssertFalse(rows.isEmpty, "登録された通知が読めない")
        // 日付の書き方は端末の設定で変わる（「10/1」「10月1日」）ので、時刻と日にちで確かめる
        for row in rows {
            if row.contains("支払日です") || row.contains("無料トライアル") {
                XCTAssertTrue(row.hasSuffix(" 9:00"), "9:00 ではない：\(row)")
            } else if row.contains("月次チェックイン") {
                let isFirstDay = row.contains("月1日 20:00") || row.contains("/1 20:00")
                XCTAssertTrue(row.contains("→ 毎月") && isFirstDay, "毎月1日 20:00 ではない：\(row)")
            }
        }
        XCTAssertTrue(rows.contains { $0.contains("月次チェックイン") }, "チェックインの通知がない")
        XCTAssertTrue(rows.contains { $0.contains("支払日です") }, "支払日の通知がない")
        XCTAssertTrue(rows.contains { $0.contains("無料トライアル") }, "トライアル終了の通知がない（プラス）")
    }

    /// 支払日の前日の通知（アプリが作る内容のまま、時刻だけ2分後）が届き、タップすると一覧が開く
    func test12_PaymentNotificationOpensList() {
        let app = launch(["-seedSampleData", "-skipOnboarding", "-scheduleTestNotification"])
        sleep(4)
        XCUIDevice.shared.press(.home)

        let notification = springboard.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS %@", "の支払日です")).firstMatch
        XCTAssertTrue(notification.waitForExistence(timeout: 160), "支払いの通知が届かない")
        snap("12-1 届いた支払いの通知")
        notification.tap()

        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 15), "通知からアプリが開かない")
        let listTab = app.tabBars.buttons["一覧"]
        XCTAssertTrue(listTab.waitForExistence(timeout: 5))
        sleep(1)
        XCTAssertTrue(listTab.isSelected, "一覧が開かない")
        snap("12-2 通知から開いた画面")
    }

    /// 設定で通知をオフにすると、登録済みの通知が消える。オンに戻すと登録し直す（最後に元のオンに戻す）
    func test13_NotificationTogglesOff() {
        let app = launch(["-seedSampleData", "-skipOnboarding", "-forcePremium"])
        sleep(4)
        tab(app, "設定")
        let toggles = ["支払日の前日（9:00）", "無料トライアル終了（3日前・前日）", "月次チェックイン（毎月1日 20:00）"]
        XCTAssertGreaterThan(pendingNotificationCount(app), 0, "オフにする前に通知が登録されていない")

        setToggles(app, toggles, on: false)
        snap("13-1 通知をすべてオフ")
        XCTAssertEqual(pendingNotificationCount(app), 0, "オフにしても通知が残っている")
        snap("13-2 登録済みの通知（オフの後）")

        setToggles(app, toggles, on: true)
        XCTAssertGreaterThan(pendingNotificationCount(app), 0, "オンに戻しても通知が登録されない")
        snap("13-3 登録済みの通知（オンに戻した後）")
    }

    /// 広告 ID（IDFA）を読む。AdMob の「テストデバイス」に登録するため（結果に記録するだけで、失敗にはしない）
    func test14_AdvertisingIdentifier() {
        let app = launch(["-skipOnboarding"])
        sleep(3)
        tab(app, "設定")
        let row = app.descendants(matching: .any)["debug.advertisingIdentifier"]
        for _ in 0..<8 where !row.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(row.waitForExistence(timeout: 5), "広告 ID の行がない")
        record(row.label, name: "14 広告 ID（IDFA）")
        snap("14-1 広告 ID")
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

    /// 設定の通知のスイッチを、指定した状態にする（設定のタブを開いた状態で呼ぶ）
    private func setToggles(_ app: XCUIApplication, _ labels: [String], on: Bool) {
        for label in labels {
            let toggle = app.switches[label]
            // 登録済みの通知を見た後は画面の下にいるので、上へ戻してから探す
            for _ in 0..<4 where !toggle.isHittable {
                app.swipeDown()
            }
            for _ in 0..<4 where !toggle.isHittable {
                app.swipeUp()
            }
            XCTAssertTrue(toggle.waitForExistence(timeout: 5), "スイッチがない：\(label)")
            if (toggle.value as? String == "1") != on {
                // 行の文字ではなく、右端のスイッチを押す
                toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.92, dy: 0.5)).tap()
            }
            XCTAssertEqual(toggle.value as? String, on ? "1" : "0", "スイッチが切り替わらない：\(label)")
        }
        // 登録し直すのを待つ（NotificationScheduler.reschedule は少し待ってから登録する）
        sleep(2)
    }

    /// デバッグの「登録済みの通知」を開いて、行の数を数える（設定のタブを開いた状態で呼び、設定に戻る）
    private func pendingNotificationCount(_ app: XCUIApplication) -> Int {
        let link = app.buttons.containing(NSPredicate(format: "label BEGINSWITH %@", "登録済みの通知")).firstMatch
        for _ in 0..<6 where !link.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(link.waitForExistence(timeout: 5))
        link.tap()
        XCTAssertTrue(app.navigationBars["登録済みの通知"].waitForExistence(timeout: 5))
        sleep(2)
        let count = app.cells.count
        record("\(count)件", name: "登録済みの通知の件数")
        app.navigationBars.buttons.firstMatch.tap()
        sleep(1)
        return count
    }

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

    /// 画面右上に AssistiveTouch の丸があると、右上のボタン（＋・保存）へのタップが丸に取られるので、左端の中ほどへ動かす。
    /// 丸がない端末では、ナビゲーションバーの右上を少しドラッグするだけ（ボタンは押されない）。
    private func moveAssistiveTouchAwayFromTopRight() {
        let origin = springboard.coordinate(withNormalizedOffset: .zero)
        let frame = springboard.frame
        let from = origin.withOffset(CGVector(dx: frame.width - 40, dy: 86))
        let to = origin.withOffset(CGVector(dx: 30, dy: frame.height / 2))
        from.press(forDuration: 0.6, thenDragTo: to)
        sleep(1)
    }

    private func record(_ text: String, name: String) {
        let attachment = XCTAttachment(string: text)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
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
