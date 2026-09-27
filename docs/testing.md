# テスト

## 実行のしかた

Xcode で ⌘U、またはコマンドラインで：

```bash
xcodebuild -project SubscBook.xcodeproj -scheme SubscBook -destination 'platform=iOS Simulator,name=iPhone 17' test
```

テストの一部だけを動かすとき（例：通知の予定）：

```bash
xcodebuild -project SubscBook.xcodeproj -scheme SubscBook -destination 'platform=iOS Simulator,name=iPhone 17' test -only-testing:SubscBookTests/NotificationPlannerTests
```

今は 149件（34スイート）で、数秒で終わります。

## 方針

- フレームワークは Swift Testing（`import Testing`、`@Suite`・`@Test`・`#expect`・`#require`）
- 計算・判定（Services）と、ViewModel・集計値を確かめます。View は確かめず、シミュレータで見て確かめます
- テスト名は日本語で、確かめるルールがわかるように書きます（例：「月末日は元の日を保持する：1/31 → 2/28 → 3/31 → 4/30 → 5/31」）
- テストのフォルダは、アプリ本体と同じ構成にします（`SubscBook/Services/Subscription/CostCalculator.swift` → `SubscBookTests/Services/Subscription/CostCalculatorTests.swift`）
- 日付はすべて東京時間に固定します。現在時刻に頼るテストは書きません
- データベースを使うテストは、テストごとにインメモリのストアを作ります

## ヘルパー

`SubscBookTests/Helpers/`

| ヘルパー | 内容 |
|---|---|
| `Calendar.tokyo` | 東京時間・グレゴリオ暦・日本語のカレンダー |
| `date(年, 月, 日, 時, 分)` | 東京時間で日時を作る（例：`date(2026, 9, 26, 20)`） |
| `TestStore` | インメモリの SwiftData ストア。`addSubscription(name:category:price:cycle:nextPaymentDate:status:canceledAt:createdAt:)` で既定値付きのサブスクを入れる |
| `StubInsightService` | AI のコメント生成の代わり。呼ばれた回数を数え、`isGenerated` を指定できる |

`Calendar.tokyo` と `date(...)` は `nonisolated` です。パラメータ付きテストの引数（MainActor の外で評価される）でも使えるようにするためです。

## 実機での確認（UI テスト）

`SubscBookUITests/DeviceCheckUITests.swift` は、画面を自動で操作しながらスクリーンショットを残すテストです。iPhone をつないで、確認用のスキーム `SubscBookDeviceCheck` で動かします（通常のスキーム `SubscBook` には含めていないので、⌘U では動きません）。

```bash
xcodebuild -project SubscBook.xcodeproj -scheme SubscBookDeviceCheck -destination 'platform=iOS,id=<iPhone の UDID>' -allowProvisioningUpdates -resultBundlePath build/DeviceCheck.xcresult test
```

購入の流れ（`PurchaseUITests`）は、StoreKit Testing（`Products.storekit` を UI テストのバンドルに入れて `SKTestSession` で読む）で動かすので、本物のお金はかからず、App Store Connect の商品も使いません。購入の確認画面は出さない設定にして、購入・期限切れ・復元をテストから操作します。

| テスト | 確かめること |
|---|---|
| `PurchaseUITests.test01_YearlyTrialPurchaseAndExpire` | ペイウォールの価格、年額（1週間無料）の購入、設定の表示（無料トライアル中・無料期間の終了日）、プラスの機能が開き広告の案内が消える、期限切れで無料に戻る |
| `PurchaseUITests.test02_MonthlyPurchaseAndRestore` | 月額の購入、設定の表示（次回の更新日）、購入の復元 |
| `PurchaseUITests.test03_RestoreWithoutPurchase` | 購入がないときの復元（見つからないと伝える） |
| `PurchaseUITests.test04_ManageSubscription` | 購入後、設定の「サブスク帳プラスの契約を管理」から、契約の管理（解約）の画面が開く |

本物の App Store（Sandbox）との接続は、App Store Connect に商品を作り、Sandbox のアカウントでサインインしてから確かめます（[premium.md](premium.md)）。

スクリーンショットは結果から取り出して見ます。

```bash
xcrun xcresulttool export attachments --path build/DeviceCheck.xcresult --output-path build/DeviceCheckShots
```

| テスト | 確かめること |
|---|---|
| `test01_Onboarding` | オンボーディング、通知の許可、スキップ、トラッキングの許可 |
| `test02_FreeScreens` | 無料プランの各画面、ペイウォール、AIコメントの説明 |
| `test03_PremiumScreens` | プラスの各画面（ぼかしと広告がない） |
| `test04_CheckInAndInterstitial` | チェックイン（ボタンとスワイプ）、閉じた後の全画面広告 |
| `test05_AddAndCancel` | 登録と解約日の記録 |
| `test06_DarkModeAndLargestText` | ダークモードといちばん大きな文字 |
| `test07_OpenFromNotificationWhenTerminated` | アプリを終了した状態で、通知から開く |
| `test08_SaveShareImage` | 節約レポートの画像を写真に保存 |
| `test09_AccessibilityAudit` | Apple のアクセシビリティ監査（結果を記録。失敗にはしない） |
| `test10_DeleteAllData` | データの全削除 |
| `test11_ScheduledNotificationTimes` | 実機に登録された通知の時刻（支払日の前日・トライアル終了は 9:00、チェックインは毎月1日 20:00） |
| `test12_PaymentNotificationOpensList` | 支払日の前日の通知が実際に届き、タップすると一覧が開く |
| `test13_NotificationTogglesOff` | 設定で通知を3つともオフにすると登録済みの通知が0件になり、オンに戻すと登録し直す（最後はオンに戻す）。通知が許可されている端末で動かす |
| `test14_AdvertisingIdentifier` | 設定のデバッグにある広告 ID（IDFA）を読んで記録する（AdMob のテストデバイスの登録用。トラッキングを許可していないと読めない。失敗にはしない） |

- 実行中は iPhone の画面を点けたままにします（自動ロックで画面が消えると「Timed out while enabling automation mode」で始まらない）
- AssistiveTouch の丸が画面右上のボタンに重なっていると、タップが届きません
- 許可のダイアログは一度答えると出ないので、最初から確かめるときはアプリを削除してから動かします
- 起動オプション `-emptyData`（データを空にする）、`-resetOnboarding`（オンボーディングを最初から）、`-scheduleTestNotification`（アプリが実際に作るチェックイン・支払日の前日の通知を、時刻だけ1〜2分後のちょうどの分にずらして登録する）を使います。決まった時刻（9:00・毎月1日 20:00）まで待たずに、本番と同じ内容・同じ登録方法（`UNCalendarNotificationTrigger`）の通知が届くことを確かめるためです。本番の時刻そのものは `test11` で、登録された内容から確かめます
- AssistiveTouch の丸が右上にあるときは、登録のテストの最初に左端の中ほどへドラッグして動かします
- 端末の「Appからのトラッキング要求を許可」がオフだと、トラッキングの許可のダイアログは出ません（iOS が自動で「許可しない」にする）。テストは失敗にせず記録だけします
- アクセシビリティ監査の「コントラスト」の指摘は、画面下のタブバーに重なっている部分（半透明の上）で出ることがあります。画面に見えている部分は、スクリーンショットで確かめます

### 手で確かめる項目

UI テストでは確かめられない、または確かめ方を変えたもの（2026年9月27日時点）。

| 項目 | 確かめ方・結果 |
|---|---|
| 通信がないときのバナーの場所 | 広告が届かないときは `AdBanner` が高さ0のままになる。存在しない広告ユニット ID でビルドして（`ADMOB_BANNER_UNIT_ID=ca-app-pub-3940256099942544/1111111111` をビルドの設定として渡す）読み込みを失敗させ、タブバーの上に空きができないことを確認済み。通信がないときも同じ失敗の処理（`bannerView(_:didFailToReceiveAdWithError:)`）を通る |
| VoiceOver でチェックインに答える | カードに「使った」「使っていない」の操作（`accessibilityAction`）があり、同じ名前のボタンも画面にある（`test04` がボタンで答える）。実際の読み上げは、VoiceOver をオンにして手で確かめる |

## App Store のスクリーンショット

`AppStoreScreenshotUITests` が、App Store に載せる画像（6.9インチ・1320×2868）を撮ります。サービス名は、ほかの会社の商標を載せないように一般的な名前にしたサンプルデータ（起動オプション `-storeScreenshotData`）を使います。

1. シミュレータ「iPhone 17 Pro Max」を起動し、ライトモードにして、ステータスバーを固定する（時刻 9:41・電池 100%）

```bash
xcrun simctl ui "iPhone 17 Pro Max" appearance light
```

```bash
xcrun simctl status_bar "iPhone 17 Pro Max" override --time 9:41 --dataNetwork wifi --wifiMode active --wifiBars 3 --cellularMode active --cellularBars 4 --operatorName "" --batteryState charged --batteryLevel 100
```

2. テストを動かして、画像を取り出す

```bash
xcodebuild -project SubscBook.xcodeproj -scheme SubscBookDeviceCheck -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' -resultBundlePath build/Screenshots.xcresult -only-testing:SubscBookUITests/AppStoreScreenshotUITests test
```

```bash
xcrun xcresulttool export attachments --path build/Screenshots.xcresult --output-path build/Screenshots
```

| 画像 | 内容 |
|---|---|
| 1 ホーム | 毎月の支払い・今月のひとこと・解約候補・次の支払い（プラス） |
| 2 一覧 | 契約中のサブスク |
| 3 チェックイン | 「先月使いましたか？」のカード |
| 4 レポート | 毎月の支払いとカテゴリ別の円グラフ |
| 5 レポート（解約候補） | 解約候補・重複しているサブスク・年間節約レポート |
| 6 ペイウォール | サブスク帳プラスの機能と価格 |
| 7 ペイウォール（下） | 購入のボタンと注意書き（サブスクリプションの審査用のスクリーンショットにも使う） |

## StoreKit のテスト

`StoreKitTests` はリポジトリ直下の `Products.storekit` を `SKTestSession` で読みます。

- ファイルは、テストのバンドルにリソースとしてコピーしたものを読みます（Mac のパスをたどる方法だと、実機でファイルが見つからないため）。実機でも同じテストが通ります
- スイートは `.serialized` で、1件ずつ順に動かします（購入の状態を共有するため）
- 各テストの始めと終わりに購入履歴を消します。消さないと、シミュレータの StoreKit の環境に購入が残り、アプリを起動したときにプラスになってしまいます
- 期限切れのテストは、StoreKit の時間の進み方の都合で反映が遅れることがあるので、状態が変わるまで少し待ちながら確かめます

## スイートの一覧

### Models

| スイート | 確かめること |
|---|---|
| 全画面広告を出すルール（`InterstitialAdPolicyTests`） | 使い始めの3日間、前回から2日、30日で4回まで、古い記録を捨てる |
| 無料プランの制限（`FreePlanTests`） | 無料は有効なサブスク5件まで、プラスは無制限 |
| サービス名の候補（`ServicePresetCatalogTests`） | 大文字小文字・全角半角・ひらがなカタカナの違いを吸収、濁点は区別、前方一致を先に、件数の上限、空文字・完全一致では出さない、名前の重複がない |
| Subscription / CheckIn モデル（`SubscriptionTests`） | 列挙型の変換、解約・契約中に戻す、`activePredicate`、同じ月のチェックインの上書き、削除でチェックインも消える |
| YearMonth（`YearMonthTests`） | 文字列との変換、不正な文字列、年をまたぐ加減算、日付から作る、順序 |

### Services

| スイート | 確かめること |
|---|---|
| 金額計算（`CostCalculatorTests`） | 月額換算（年額は12で割って四捨五入）、負の金額、合計は有効なものだけ、1年あたりの支払額 |
| 次回支払日の更新（`PaymentDateCalculatorTests`） | 月末日の保持、うるう年、年またぎ、過去の支払日を進める、今日はそのまま、基準日の保持、ModelContext からの更新 |
| 月次チェックイン（`CheckInPolicyTests`） | 対象月は前月、登録から1ヶ月（日単位）、解約済みは対象外、未回答の抽出、バナーの判定 |
| 解約候補の判定（`CancelSuggestionDetectorTests`） | 最新の回答月と前月が「使っていない」、連続月数、候補にならない場合、同じ月は最後の回答、解約済みは除く、並び順 |
| 重複の検出（`DuplicateDetectorTests`） | 同じカテゴリ2件以上、「その他」は除く、解約済みは数えない、並び順 |
| 節約額（`SavingsCalculatorTests`） | 1年あたりの合計、満了月数 × 月額換算、複数件の合計、満了月数の数え方 |
| 通知の登録内容（`NotificationSchedulerTests`） | 1回の通知は年月日と時刻（分まで）、月次チェックインは毎月1日 20:00 の繰り返し、種類とサブスクIDを通知に入れる |
| 通知の予定（`NotificationPlannerTests`） | 前日 9:00・月額は3回先まで、月末払い、年額は1回、過ぎた時刻は登録しない、古い支払日から計算、解約済みは除く、トライアルはプラスのみ、チェックインの繰り返しと初回の1回、設定のオフ、上限64件、識別子の重複なし |
| AI に渡す事実（`InsightFactsBuilderTests`） | プラスは名前、無料は件数だけ、理由の事実に数字・かぎ括弧を入れない、事実にない話題の語、前月比 |
| AI コメントのキャッシュ（`InsightProviderTests`） | 同じ月・同じ内容では生成しない、内容が変わったら作り直す、無料・プラスの両方を残す、定型文はキャッシュしない、同時の要求は1回の生成、理由のキャッシュ |
| AI 出力のチェック（`InsightSanitizerTests`） | 全体を囲む括弧だけを外す、数字・金額・英単語、ほかのサービスをすすめる表現、事実にない話題の語、サービス名の英数字は許可、長さ |
| テンプレート文（`TemplateInsightServiceTests`） | 事実に合わせた文の選び方 |
| タイムアウト（`TimeoutTests`） | 時間内なら結果を返す、超えたら待たずにエラー |
| 課金（`StoreKitTests`） | 商品定義、ペイウォールの表記、購入でプラス・期限切れで無料、トライアル中の扱い、ペイウォールでの購入 |

### ViewModels

| スイート | 確かめること |
|---|---|
| 画面遷移（`AppRouterTests`） | 上限でペイウォール、通知のタップでの遷移（チェックイン中の支払い通知で閉じる）、閉じ終わってからペイウォール・全画面広告を出す（待っている画面を優先） |
| 月次チェックインの進行（`CheckInViewModelTests`） | 名前順、回答して進む、戻って上書き、表示中でないサブスクへの回答は無視、聞くものがない理由 |
| AI コメントの読み込み（`InsightViewModelTests`） | 理由の読み込みと、候補から外れたものの削除、理由はプラスのみ |
| ホームの集計（`HomeSummaryTests`） | 合計・件数・直近3件・解約候補・チェックインの要否 |
| ホームの状態（`HomeViewModelTests`） | ひとことと理由の読み込み |
| オンボーディングの状態（`OnboardingViewModelTests`） | ページの進み方 |
| ペイウォールのプラン表示（`PaywallPlanTests`） | 期間と金額の表記 |
| ペイウォールの状態（`PaywallViewModelTests`） | 初期選択は年額、選択が一覧にない場合 |
| カテゴリ別の集計（`CategoryBreakdownTests`） | 定義順・割合の合計は1 |
| レポートの状態（`ReportViewModelTests`） | 集計、共有画像はプラスで解約があるときだけ |
| 節約の集計（`SavingsSummaryTests`） | 1年あたり・累計・件数 |
| 設定の状態（`SettingsViewModelTests`） | 全削除、期限の表記、未加入のときの表記 |
| 登録・編集フォーム（`SubscriptionFormViewModelTests`） | 金額の入力、保存できる条件と理由、カテゴリの初期値と自動設定、候補の選択（自分で選んだカテゴリは変えない）、保存の時点での無料プランの上限、新規・編集の保存、過去の支払日、基準日 |
| 一覧の並び替え（`SubscriptionListSectionsTests`） | 支払日順、解約済みは別セクション |
| 一覧の状態（`SubscriptionListViewModelTests`） | 残り件数の案内、並び順の保存、解約済みの開閉 |

## テストを追加するとき

- 新しいルールや判定を足したら、同じ構成のフォルダにテストを足します（フォルダ同期なので、ファイルを置くだけで対象になります）
- ファイルの先頭に `@testable import SubscBook` と、使うモジュール（`Foundation`・`SwiftData` など）の `import` を書きます
- 日付は `date(...)` と `Calendar.tokyo` を使い、関数に `now:`・`calendar:` で渡します
- 同じ確かめ方で入力だけ違うものは、パラメータ付きテスト（`@Test(arguments:)`）にします

## 画面の確認（手動）

ロジック以外は、シミュレータで確かめます。

- サンプルデータ：起動オプション `-seedSampleData`（契約中6件・解約済み2件、解約候補・重複・トライアルを含む）
- プラスの画面：`-forcePremium`
- ペイウォールの表示：`-samplePlans`（StoreKit の商品が読めない環境でも表示）
- オンボーディングを飛ばす：`-skipOnboarding`
- Release ビルドが通ることも確かめます（`#Preview` の中で Debug 専用のコードを使うと、Release だけ失敗するため）
