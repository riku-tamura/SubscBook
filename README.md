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
| 対応 OS | iOS 18.0 以降（AIコメントは iOS 26 以降の Apple Intelligence 対応端末） |
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
| テスト | Swift Testing、StoreKitTest（`SKTestSession`） |
| 外部ライブラリ | Google Mobile Ads SDK（Swift Package。依存として Google User Messaging Platform も入る）だけ |

Xcode プロジェクトの主な設定：

- Swift 6（`SWIFT_VERSION = 6.0`）
- 既定のアクター分離は MainActor（`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`）。バックグラウンドで使う型には `nonisolated` を付けます
- `SWIFT_APPROACHABLE_CONCURRENCY = YES`
- `SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY = YES`：使うモジュールはファイルごとに `import` が必要です
- フォルダ同期（`PBXFileSystemSynchronizedRootGroup`）：`SubscBook/` と `SubscBookTests/` にファイルを置くだけでビルド対象になります。pbxproj の編集は不要です
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

- 147件（33スイート）。計算・判定のロジックと ViewModel を中心に確かめます
- 日付はすべて東京時間に固定して確かめます（`Calendar.tokyo` と `date(2026, 9, 26)`）
- StoreKit のテストは `Products.storekit` を読み、テスト後に購入履歴を消します

詳しくは [docs/testing.md](docs/testing.md) を見てください。

## 開発用の起動オプション

Debug ビルドでのみ有効です。Xcode ではスキームの「Run → Arguments」、コマンドラインでは `xcrun simctl launch <端末> com.hachimaki.SubscBook <オプション>` で指定します。

| オプション | 内容 |
|---|---|
| `-seedSampleData` | 既存のデータを消して、サンプルのサブスク8件（契約中6件・解約済み2件）を入れる |
| `-forcePremium` | 購入せずにサブスク帳プラスを有効にする |
| `-samplePlans` | StoreKit の商品が読めないときも、ペイウォールにサンプルのプランを表示する |
| `-skipOnboarding` | オンボーディングを表示しない |
| `-ignoreAdLimits` | 全画面広告の回数のルールを無視して、区切りのたびに出す |

設定画面の最下部（Debug ビルドのみ）に「デバッグ」の項目があり、プラスの切り替えと、登録済みの通知の一覧を確認できます。

## フォルダ構成

```
subsWatch/
├── README.md                  このファイル
├── Products.storekit          StoreKit の商品定義（ローカルでの購入テスト用）
├── Config/                    自動生成の Info.plist に足す項目（AdMob の ID など）
├── SubscBook.xcodeproj        Xcode プロジェクト（共有スキーム SubscBook を含む）
├── docs/                      設計書・資料
├── SubscBook/                 アプリ本体
│   ├── SubscBookApp.swift     アプリの入口（データベース・共有オブジェクトの作成）
│   ├── AppDelegate.swift      通知をタップしたときの画面遷移
│   ├── Models/                データの型（SwiftData のモデル、値型、定数）
│   ├── Services/              計算・判定・外部 API（通知・課金・AI）
│   ├── ViewModels/            画面ごとの状態と操作、画面に出す集計値
│   ├── Views/                 SwiftUI の画面と部品
│   ├── Formatting/            表示用の文字列への変換（"1,490円" など）
│   ├── Debug/                 Debug ビルドだけで使うコード
│   └── Resources/             アプリアイコン・アクセントカラー
└── SubscBookTests/            単体テスト（アプリ本体と同じフォルダ構成）
```

`Models` / `Services` / `ViewModels` / `Views` の中は、機能ごとのフォルダ（`Subscription` / `Insight` / `Notification` / `Premium`）と、画面ごとのフォルダ（`Home` / `CheckIn` など）に分けています。すべてのファイルの説明は [docs/file-reference.md](docs/file-reference.md) にあります。

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

コードのコメントにある「5.3」「8章」「⑥」などは、元の仕様書の章番号と画面番号です。対応表は [docs/business-rules.md](docs/business-rules.md#仕様書の章番号との対応) にあります。

## リリース前にやること

- [ ] Xcode の Signing で開発チーム（Team）を設定する
- [ ] App Store Connect でアプリを作り、サブスクリプショングループ「サブスク帳プラス」に2商品を作る（ID と価格は `Products.storekit` と同じ。手順は [docs/app-store.md](docs/app-store.md)）
- [ ] サポート URL とプライバシーポリシーの URL を用意する（ポリシーはアプリ内の文面をそのまま公開できます）
- [ ] 名前「サブスク帳」が App Store Connect で使えるか、商標（J-PlatPat）とあわせて確認する
- [ ] AdMob でアプリと広告ユニット（バナー・全画面）を作り、Release の `ADMOB_*` を本番の ID に差し替える（[docs/ads.md](docs/ads.md)）
- [ ] 開発者のウェブサイトに `app-ads.txt` を置く（[docs/ads.md](docs/ads.md)）
- [ ] `Config/SubscBook-Info.plist` の SKAdNetwork の一覧を、AdMob のドキュメントの最新のものにする
- [ ] App のプライバシーを、広告で収集されるデータに合わせて登録する（[docs/app-store.md](docs/app-store.md)）
- [ ] 配信地域を日本のみにする（同意確認の画面を実装していないため）
- [ ] Apple Intelligence 対応の実機で AIコメントの表示を確かめる
- [ ] Sandbox アカウントで購入・復元・期限切れを確かめる
