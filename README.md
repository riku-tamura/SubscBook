# サブスク帳

契約中のサブスクを1冊にまとめて管理する iPhone アプリです。毎月・毎年の支払いがひと目でわかり、支払日の前日にお知らせします。毎月のチェックインで「使っていない」サブスクを振り返り、見直しを後押しします。

- 登録したデータは端末の中だけに保存し、外部のサーバーには送りません（解析ツールもなし）
- 無料プランでは Google AdMob の広告を表示します（サブスク帳プラスは広告なし）
- AIコメントは Apple Intelligence の端末内モデル（FoundationModels）で作り、使えない端末では定型のコメントを表示します
- 表示は日本語のみ、金額は日本円（整数）のみです

| 項目 | 内容 |
|---|---|
| アプリ名 | サブスク帳（有料プラン：サブスク帳プラス） |
| コード名 | `SubscBook` |
| Bundle ID | `com.hachimaki.SubscBook` |
| 対応 OS | iOS 18.0 以降（AIコメントは、Apple Intelligence に対応した iPhone（15 Pro 以降）で iOS 26 以降のとき） |
| 対応端末 | iPhone のみ・縦向きのみ |
| 言語 | Swift 6 / SwiftUI |

## 目次

- [主な機能](#主な機能)
- [技術構成](#技術構成)
- [はじめかた](#はじめかた)
- [テスト](#テスト)
- [開発用の起動オプション](#開発用の起動オプション)
- [フォルダ構成](#フォルダ構成)
- [設計の原則](#設計の原則)
- [ドキュメント一覧](#ドキュメント一覧)
- [確認の状況](#確認の状況)
- [ウェブサイト](#ウェブサイト)
- [リリース前にやること](#リリース前にやること)

## 主な機能

### 無料で使える機能

- サブスクの登録・編集・削除（契約中は5件まで）。主要な66サービスは名前を入れると候補が出て、カテゴリも自動で入ります
- 月額換算の合計・1年あたりの合計・契約件数の表示
- 支払日の前日 9:00 のお知らせ
- 月次チェックイン：毎月1日 20:00 に「先月使いましたか？」を1件ずつ聞く（登録から1ヶ月たったサブスクが対象）
- カテゴリ別の円グラフ、今月のひとこと（AI または定型のコメント）
- 解約の記録（解約した日を選べる）と、契約中に戻す操作
- データの全削除

### サブスク帳プラス（有料）

| 機能 | 内容 |
|---|---|
| 無制限の登録 | 契約中のサブスクを5件を超えて登録できる |
| 広告なし | バナーと全画面の広告を表示しない |
| 無料トライアル終了の通知 | 終了の3日前と前日の 9:00 に通知 |
| 解約候補の提案 | チェックインで2ヶ月続けて「使っていない」と答えたサブスクを、AI の理由付きで表示 |
| 重複サブスクの検出 | 同じカテゴリ（「その他」を除く）で2件以上契約しているものを表示 |
| 年間節約レポート | 解約で浮くお金（1年あたり）と節約累計、SNS 共有用の画像 |

料金は月額300円、年額2,400円（初回のみ1週間無料）。無料ユーザーには、プラスの機能をぼかして鍵を重ねて見せ、タップで案内（ペイウォール）を開きます。

## 技術構成

| 分野 | 使っているもの |
|---|---|
| UI | SwiftUI（`TabView` / `NavigationStack` / Swift Charts の `SectorMark`） |
| データ | SwiftData（`Subscription`・`CheckIn` の2モデル）、設定値は `UserDefaults` |
| 課金 | StoreKit 2（`Product` / `Transaction.currentEntitlements` / `Transaction.updates`） |
| 通知 | UserNotifications のローカル通知のみ（サーバーからのプッシュなし） |
| AI | FoundationModels（iOS 26+。`@Generable` で出力形式を決め、失敗時は定型文） |
| 広告 | Google Mobile Ads SDK（AdMob。バナーと全画面広告）、AppTrackingTransparency |
| 設計 | MVVM（View は表示、ViewModel は状態と操作、計算は Services の純粋な関数） |
| テスト | Swift Testing（単体テスト）、XCUITest（実機の確認用の UI テスト）、StoreKitTest（`SKTestSession`） |
| 外部ライブラリ | Google Mobile Ads SDK（Swift Package。依存として Google User Messaging Platform も入る）だけ |

Xcode プロジェクトの主な設定：

- Swift 6（`SWIFT_VERSION = 6.0`）
- 既定のアクター分離は MainActor（`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`）。バックグラウンドで使う型には `nonisolated` を付けます
- `SWIFT_APPROACHABLE_CONCURRENCY = YES`
- `SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY = YES`：使うモジュールはファイルごとに `import` が必要です
- フォルダ同期（`PBXFileSystemSynchronizedRootGroup`）：`SubscBook/`・`SubscBookTests/`・`SubscBookUITests/` にファイルを置くだけでビルド対象になります。pbxproj の編集は不要です
- Info.plist は自動生成（`GENERATE_INFOPLIST_FILE`）。表示名・カテゴリ（ファイナンス）・暗号化の申告などは Build Settings の `INFOPLIST_KEY_*` で設定しています

## はじめかた

必要なもの：Xcode 26 以降（iOS 26 SDK。FoundationModels を含むため）

1. `SubscBook.xcodeproj` を開く
2. スキーム `SubscBook` を選び、iPhone のシミュレータで実行する

スキームには StoreKit の設定ファイル（`Products.storekit`）が設定してあるので、シミュレータでも App Store Connect なしで購入を試せます。

実機で動かすときは、Target の「Signing & Capabilities」で開発チーム（Team）を設定してください。

AIコメントはシミュレータでは生成されません（モデルがないため `ModelManagerError 1026` になり、定型のコメントを表示します）。AI の出力を確かめるときは、Apple Intelligence に対応した実機か、Mac の端末内モデルを使います（[docs/ai-insights.md](docs/ai-insights.md)）。

## テスト

Xcode で ⌘U、またはコマンドラインで：

```bash
xcodebuild -project SubscBook.xcodeproj -scheme SubscBook -destination 'platform=iOS Simulator,name=iPhone 17' test
```

- 149件（34スイート）。計算・判定のロジックと ViewModel を中心に確かめます
- 日付はすべて東京時間に固定して確かめます（`Calendar.tokyo` と `date(2026, 9, 26)`）
- StoreKit のテストは、テストに入れた `Products.storekit` を読み、テスト後に購入履歴を消します（シミュレータでも実機でも動きます）

### 実機（iPhone）での確認

画面を自動で操作する UI テストを、確認用のスキーム `SubscBookDeviceCheck` で動かします（通常のスキームには含めていないので、⌘U では動きません）。スクリーンショットは結果（xcresult）から取り出して見ます。

```bash
xcodebuild -project SubscBook.xcodeproj -scheme SubscBookDeviceCheck -destination 'platform=iOS,id=<iPhone の UDID>' -allowProvisioningUpdates -resultBundlePath build/DeviceCheck.xcresult test
```

- `DeviceCheckUITests`（14件）：オンボーディング・各画面・チェックイン・全画面広告・登録と解約・ダークモードと大きな文字・通知（登録された時刻、1〜2分後に実際に届く、通知から開く、設定でオフにすると消える）・画像の保存・アクセシビリティ監査・全削除・広告 ID の読み取り
- `PurchaseUITests`（4件）：StoreKit Testing で、年額（1週間無料）・月額の購入、期限切れ、購入の復元、契約の管理の画面（本物のお金はかからない）
- `AppStoreScreenshotUITests`（2件）：App Store に載せるスクリーンショット（6.9インチのシミュレータで撮る。[docs/testing.md](docs/testing.md#app-store-のスクリーンショット)）
- 実行中は iPhone の画面を点けたままにします。詳しくは [docs/testing.md](docs/testing.md) を見てください

## 開発用の起動オプション

Debug ビルドでのみ有効です。Xcode ではスキームの「Run → Arguments」、コマンドラインでは `xcrun simctl launch <端末> com.hachimaki.SubscBook <オプション>` で指定します。

| オプション | 内容 |
|---|---|
| `-seedSampleData` | 既存のデータを消して、サンプルのサブスク8件（契約中6件・解約済み2件）を入れる |
| `-storeScreenshotData` | `-seedSampleData` と同じデータを、サービス名を一般的な名前にして入れる（App Store のスクリーンショット用） |
| `-forcePremium` | 購入せずにサブスク帳プラスを有効にする |
| `-samplePlans` | StoreKit の商品が読めないときも、ペイウォールにサンプルのプランを表示する |
| `-skipOnboarding` | オンボーディングを表示しない |
| `-ignoreAdLimits` | 全画面広告の回数のルールを無視して、区切りのたびに出す |
| `-emptyData` | 既存のデータを消して空にする（UI テスト用） |
| `-resetOnboarding` | オンボーディングを最初から表示する（UI テスト用） |
| `-scheduleTestNotification` | アプリが作るチェックイン・支払日の前日の通知を、時刻だけ1〜2分後にずらして登録する（UI テスト用） |

設定画面の最下部（Debug ビルドのみ）に「デバッグ」の項目があり、プラスの切り替え、登録済みの通知の一覧、広告 ID（AdMob のテストデバイスの登録用）を確認できます。

## フォルダ構成

```
subsWatch/
├── README.md                  このファイル
├── Products.storekit          StoreKit の商品定義（ローカルでの購入テスト用）
├── Config/                    自動生成の Info.plist に足す項目（AdMob の ID など）
├── SubscBook.xcodeproj        Xcode プロジェクト（共有スキーム SubscBook・SubscBookDeviceCheck）
├── docs/                      設計書・資料
├── SubscBook/                 アプリ本体
│   ├── SubscBookApp.swift     アプリの入口（データベース・共有オブジェクトの作成）
│   ├── AppDelegate.swift      通知をタップしたときの画面遷移
│   ├── Models/                データの型（SwiftData のモデル、値型、定数）
│   ├── Services/              計算・判定・外部 API（通知・課金・AI・広告）
│   ├── ViewModels/            画面ごとの状態と操作、画面に出す集計値
│   ├── Views/                 SwiftUI の画面と部品
│   ├── Formatting/            表示用の文字列への変換（"1,490円" など）
│   ├── Debug/                 Debug ビルドだけで使うコード
│   └── Resources/             アプリアイコン・アクセントカラー・プライバシーマニフェスト
├── SubscBookTests/            単体テスト（アプリ本体と同じフォルダ構成）
└── SubscBookUITests/          実機の確認用の UI テスト
```

`Models` / `Services` / `ViewModels` / `Views` の中は、機能ごとのフォルダ（`Subscription` / `Insight` / `Notification` / `Premium` / `Ads`）と、画面ごとのフォルダ（`Home` / `CheckIn` など）に分けています。すべてのファイルの説明は [docs/file-reference.md](docs/file-reference.md) にあります。

## 設計の原則

1. **数値はすべてロジックで計算する。** AI には数値を渡さず、書かせもしません。AI の出力に数字・円・%・英単語が入っていたら使いません
2. **登録したお金のデータを端末の外に出さない。** ネットワークを使うのは App Store（課金）と、無料プランの広告（Google AdMob）だけです。広告のリクエストにアプリのデータは入れません
3. **何を伝えるかはアプリが決める。** AI は、アプリが決めた定型の文の言い換えと、解約候補の理由の文章化だけを受け持ちます
4. **「使っていない」はチェックインの回答だけで判定する。** iPhone のアプリの利用状況（スクリーンタイムなど）は読みません
5. **計算・判定は純粋な関数にする。** `now` と `calendar` を引数で受け取り、テストで日付を固定できるようにしています
6. **無料でも価値がわかるようにする。** プラスの機能は隠さず、ぼかして見せます。オンボーディングの直後にペイウォールは出しません

## ドキュメント一覧

| ファイル | 内容 |
|---|---|
| [docs/architecture.md](docs/architecture.md) | 全体の設計：レイヤー、起動の流れ、共有オブジェクト、画面遷移、並行処理、保存先 |
| [docs/screens.md](docs/screens.md) | 画面ごとの設計：表示する内容、操作、無料とプラスの違い、空の状態 |
| [docs/business-rules.md](docs/business-rules.md) | 計算・判定のルール：金額、支払日、チェックイン、解約候補、重複、節約額、無料プランの上限 |
| [docs/data-model.md](docs/data-model.md) | データの設計：SwiftData のモデル、列挙型、UserDefaults のキー |
| [docs/notifications.md](docs/notifications.md) | 通知の設計：種類、タイミング、上限64件の扱い、登録し直すタイミング |
| [docs/premium.md](docs/premium.md) | 課金の設計：商品、購読状態の判定、ペイウォール、購入・復元 |
| [docs/ads.md](docs/ads.md) | 広告の設計：出す場所と回数、広告ユニット ID、トラッキングの許可、プライバシーの表示 |
| [docs/ai-insights.md](docs/ai-insights.md) | AIコメントの設計：可用性、プロンプト、出力のチェック、キャッシュ、検証の結果 |
| [docs/testing.md](docs/testing.md) | テストの構成、ヘルパー、スイートの一覧、書き方の決まり |
| [docs/development.md](docs/development.md) | 開発の決まり：命名とファイルの置き方、よくある落とし穴、画面の確認方法 |
| [docs/file-reference.md](docs/file-reference.md) | すべてのファイルの説明 |
| [docs/app-store.md](docs/app-store.md) | App Store の掲載情報の下書き（名前・説明文・審査用メモ） |
| [docs/app-ads.txt](docs/app-ads.txt) | 開発者のウェブサイトに置く `app-ads.txt` の中身 |

コードのコメントにある「5.3」「8章」「⑥」などは、元の仕様書の章番号と画面番号です。対応表は [docs/business-rules.md](docs/business-rules.md#仕様書の章番号との対応) にあります。

## 確認の状況

2026年9月27日時点。単体テスト 149件と Release ビルドが通ります。

| 確認 | 状況 |
|---|---|
| シミュレータ（iPhone 17・iPhone SE、iOS 26） | 全画面・ダークモード・いちばん大きな文字・小さい画面・通知・共有・全削除を確認済み |
| 実機（iPhone 15・iOS 18.7.8） | UI テスト 18件がすべて通る。最低対応の iOS 18 で動くこと、通知が決まった時刻どおりに登録され、実際に届いて正しい画面が開くこと、設定でオフにすると消えること、トラッキングの許可、購入の流れと契約の管理の画面（StoreKit Testing）を確認済み |
| 広告が届かないとき | 読み込みに失敗させたビルドで、バナーの場所が空かないことを確認済み（[docs/testing.md](docs/testing.md#手で確かめる項目)） |
| AIコメント | Mac の端末内モデルでプロンプトを検証済み（[docs/ai-insights.md](docs/ai-insights.md)）。Apple Intelligence 対応の iPhone（15 Pro 以降・iOS 26 以降）での表示は未確認 |
| 本物の App Store（Sandbox）での購入 | 未確認（App Store Connect に商品を作った後に確認する） |
| TestFlight | 未確認 |

## ウェブサイト

GitHub の Organization `hachimaki-app` のリポジトリ [hachimaki-app.github.io](https://github.com/hachimaki-app/hachimaki-app.github.io)（GitHub Pages）で公開しています。App Store Connect には次の URL を登録します。

| ページ | URL | App Store Connect の項目 |
|---|---|---|
| トップ | `https://hachimaki-app.github.io/` | マーケティング URL |
| サポート（問い合わせ先・よくある質問） | `https://hachimaki-app.github.io/subscbook/` | サポート URL |
| プライバシーポリシー | `https://hachimaki-app.github.io/subscbook/privacy.html` | プライバシーポリシー URL |
| app-ads.txt | `https://hachimaki-app.github.io/app-ads.txt` | （AdMob が確かめる） |

アプリの文面や機能を変えたときにサイトも直す決まりは [docs/development.md](docs/development.md) にあります。

## リリース前にやること

公開までの残りの作業です。（Claude）は Claude に頼めば対応できる作業、それ以外は開発者が行う作業です。

### 登録と契約

- [ ] Apple Developer Program（有料）に登録する
- [ ] App Store Connect で有料App契約（税務情報・銀行口座）を結ぶ。これが有効になるまで、購入も Sandbox での購入テストもできない
- [ ] App Store Small Business Program に申し込む（Apple の手数料が 30% → 15%）
- [x] Google AdMob のアカウントを作る
- [x] AdMob の「お支払い」で、名前・住所・銀行口座・税務情報を登録する

### ウェブサイト

- [x] ウェブサイトを用意する（上の「ウェブサイト」）
- [x] プライバシーポリシーを公開する（アプリ内の文面と同じ）
- [x] 問い合わせ用のメールアドレスを用意して、サポートページを公開する
- [x] 開発者のウェブサイトの直下に `app-ads.txt` を置く

### 広告（AdMob）

- [x] AdMob でアプリと広告ユニット（バナー・全画面）を作り、Release の `ADMOB_*` を本番の ID に差し替える（[docs/ads.md](docs/ads.md)）
- [x] `Config/SubscBook-Info.plist` の SKAdNetwork の一覧を、AdMob のドキュメントの最新のもの（50件）にする
- [ ] 自分の iPhone を AdMob の「テストデバイス」に登録する（TestFlight の前に。本番の広告は自分でタップしない）。広告 ID は Debug ビルドの「設定 → デバッグ → 広告 ID（IDFA）」に出る（トラッキングの許可が必要）
- [ ] 任意：「ブロックのコントロール」で、アプリに合わない広告のカテゴリを止める

### Xcode と App Store Connect

- [ ] Xcode の Signing で開発チーム（有料の Developer Program のチーム）を設定する
- [ ] 名前「サブスク帳」が App Store Connect で使えるか、商標（J-PlatPat）とあわせて確認する
- [ ] App Store Connect でアプリを作る（Bundle ID `com.hachimaki.SubscBook`、プライマリ言語は日本語）
- [ ] サブスクリプショングループ「サブスク帳プラス」に2商品を作る（ID と価格は `Products.storekit` と同じ。手順は [docs/app-store.md](docs/app-store.md)）
- [ ] App のプライバシーを、広告で収集されるデータに合わせて登録する（[docs/app-store.md](docs/app-store.md)）
- [ ] 配信地域を日本のみにする（同意確認の画面を実装していないため）
- [ ] 年齢制限指定に答える（広告を表示することを踏まえる）
- [ ] 説明文・キーワード・3つの URL（上の「ウェブサイト」）を入力する（文章は [docs/app-store.md](docs/app-store.md)）
- [x] 6.9インチのスクリーンショットを用意する（`AppStoreScreenshotUITests` で撮影。撮り方は [docs/testing.md](docs/testing.md#app-store-のスクリーンショット)）
- [ ] Sandbox テスターを作る（「ユーザとアクセス」→「Sandbox」）

### 実機での確認

- [x] UI テスト（`SubscBookDeviceCheck` スキーム）18件を実機で実行する（上の「確認の状況」）
- [ ] Sandbox アカウントで購入・復元・期限切れを確かめる（`PurchaseUITests` と同じ流れ。Claude）
- [x] 設定で通知をオフにすると届かない、「契約を管理」から解約の画面が開く、広告が届かないときにバナーの場所が空かない
- [ ] VoiceOver をオンにして、チェックインに答えられることを手で確かめる（操作とボタンはあることを確認済み）
- [ ] Apple Intelligence 対応の実機（iPhone 15 Pro 以降・iOS 26 以降）で AIコメントの表示を確かめる
- [ ] TestFlight で Release ビルドを確かめる（本番の広告 ID で、テスト広告が出ること）

### 審査と公開後

- [ ] 初回はアプリのバージョンと2つのサブスクリプションを一緒に審査に出す。審査用のメモは [docs/app-store.md](docs/app-store.md)
- [ ] リジェクトされたら、指摘の文章をもとに修正する（Claude）
- [ ] 公開した後、AdMob でアプリを App Store と関連付ける（AdMob の審査が始まる）。`app-ads.txt` が認識されたかも確かめる
- [ ] AdMob から届く住所確認の PIN を入力する（売上が一定額になると郵送で届く）
