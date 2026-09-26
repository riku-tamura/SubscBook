# 全体の設計

サブスク帳のコードの組み立て方をまとめます。個々の計算ルールは [business-rules.md](business-rules.md)、ファイルごとの説明は [file-reference.md](file-reference.md) を見てください。

## レイヤー

MVVM をもとに、計算・判定を Services に集めています。

```
Views（SwiftUI）
  │  @Query でデータを読み、ViewModel に渡す。表示と、操作の受け渡しだけ
  ▼
ViewModels（@Observable）
  │  画面の状態（選択中のプラン・処理中フラグ・アラートの文言など）と操作
  │  画面に出す集計値（HomeSummary・ReportSummary など）を組み立てる
  ▼
Services
  │  計算・判定（CostCalculator・CancelSuggestionDetector など）は純粋な関数
  │  外部 API を扱うもの（NotificationScheduler・EntitlementManager・InsightProvider）
  ▼
Models
     SwiftData のモデル（Subscription・CheckIn）、値型（YearMonth・PlannedNotification など）、定数
```

依存の向きは上から下だけです。Models は Services を知りません（例外として `Subscription` の金額・状態変更のアクセサが `CostCalculator` と `PaymentDateCalculator` を呼びます。モデルのそばに置いたほうが使いやすい計算に限っています）。

表示用の文字列への変換（"1,490円"、"10月15日(木)" など）は `Formatting/` に置き、ロジックと分けています。

### ViewModel の決まり

- 画面ごとに `XxxView` と `XxxViewModel` の組を作り、同じ名前のフォルダに置きます
- View は `@State private var viewModel = XxxViewModel()` で持ちます
- `@Query` の結果は View が持ち、ViewModel のメソッドに引数で渡します（ViewModel は SwiftData の監視を持ちません）
- 共有オブジェクト（`EntitlementManager` など）も、必要なメソッドに引数で渡します。テストで差し替えやすくするためです
- 集計値（`HomeSummary`・`ReportSummary`・`CategoryBreakdown`・`SavingsSummary`・`SubscriptionListSections`）は、`init` で計算を済ませる値型です。body の評価のたびに作り直しますが、件数が少ないので問題ありません

## 起動の流れ

1. `SubscBookApp.init`
   - SwiftData の `ModelContainer`（`Subscription`・`CheckIn`）を作る。開けなければ `fatalError`
   - Debug ビルドで `-seedSampleData` があれば、サンプルデータを入れる
   - `EntitlementManager` を作る（`Transaction.updates` の監視と、購読状態の読み込みを始める）
   - `NotificationScheduler` を作る（`ModelContext.didSave` の監視を始める）
   - `InsightProvider` を作る（AI が使えるかを判定し、AI 版かテンプレート版を選ぶ）
2. `AppDelegate`（`@UIApplicationDelegateAdaptor`）が、通知センターの delegate になる
3. `RootView`
   - オンボーディングを終えていなければ `OnboardingView`、終えていれば `MainTabView`
   - すでにサブスクが登録されている場合（`-seedSampleData` など）や `-skipOnboarding` のときは、オンボーディングを飛ばす
4. アプリがアクティブになるたび（起動時とフォアグラウンド復帰時）に `RootView` が行うこと
   - 過ぎた支払日を次の周期へ進めて保存する（`PaymentDateCalculator.refreshPaymentDates`）
   - 通知を登録し直す（`NotificationScheduler.reschedule`）
   - AI が使えるかを判定し直す（`InsightProvider.refreshAvailability`）
   - 購読状態を読み直す（期限切れ・返金は `Transaction.updates` に流れないことがあるため）
5. サブスク帳プラスの状態が変わったら、通知を登録し直す（トライアル終了の通知はプラスのみのため）

## 共有オブジェクト

`SubscBookApp` で1つずつ作り、SwiftUI の Environment で全画面に渡します。

| オブジェクト | 役割 | 作る場所 |
|---|---|---|
| `AppRouter` | タブの選択、登録・編集シート、ペイウォール、チェックインの全画面表示 | `AppDelegate`（通知のタップから使うため） |
| `EntitlementManager` | 課金の商品、購読状態、購入・復元 | `SubscBookApp` |
| `NotificationScheduler` | 通知の許可と登録 | `SubscBookApp` |
| `InsightProvider` | AI の可用性、コメントの生成とキャッシュ | `SubscBookApp` |
| `ModelContainer` | SwiftData のデータベース | `SubscBookApp`（`.modelContainer`） |

加えて、`\.locale` を日本語（`Locale.japanese`）に固定しています。

プレビューでは `View.previewEnvironment(seeded:)`（`Debug/`）が、インメモリのデータベースと同じ一式を用意します。

## 画面遷移

画面遷移の状態は `AppRouter` にまとめています。

| 状態 | 表示されるもの | 表示方法 |
|---|---|---|
| `selectedTab` | ホーム / 一覧 / レポート / 設定 | `TabView` |
| `subscriptionForm` | 登録（`.add`）・編集（`.edit(subscription)`）画面 | シート |
| `paywall` | ペイウォール（表示のきっかけ `PaywallReason` 付き） | シート |
| `isCheckInPresented` | 月次チェックイン | 全画面（`fullScreenCover`） |

主な操作：

- `requestNewSubscription(activeCount:isPremium:)`：無料プランの上限に達していればペイウォール、そうでなければ登録画面
- `openNotification(_:)`：通知をタップしたとき。チェックインの通知はホームに切り替えてチェックインを開き、支払い・トライアルの通知は一覧を開く。シートを開いていた場合は閉じてから表示する
- `showPaywallAfterDismissal(_:)`：全画面表示やシートを閉じ終わってから（600ミリ秒後）ペイウォールを開く。閉じるアニメーション中は新しいシートを表示できないため

## 並行処理

- 既定のアクター分離が MainActor なので、特に指定のない型はメインスレッドで動きます
- 値型・列挙型のうち、バックグラウンドからも使うもの（`YearMonth`・`MonthlyInsightFacts` など）は `nonisolated` と `Sendable` を付けています
- AI の生成は `FoundationModelInsightService`（`nonisolated`）で行い、`withTimeout` で5秒を超えたら打ち切ります
- 同じコメントを同時に求められた場合（ホームとレポート）は、`InsightProvider` が1つの `Task` を共有して、生成を1回にします
- 通知の登録し直しは、続けて呼ばれたら前の処理を取り消し、300ミリ秒待ってから最後の1回だけ行います

## データの保存先

| データ | 保存先 | 削除されるとき |
|---|---|---|
| サブスク・チェックイン | SwiftData（アプリのコンテナ内） | 「データの全削除」、アプリの削除 |
| オンボーディングを終えたか | UserDefaults `onboarding.completed` | アプリの削除 |
| 一覧の並び順 | UserDefaults `list.sortOrder` | アプリの削除 |
| 通知ごとの ON/OFF | UserDefaults `notifications.*` | アプリの削除 |
| AI が作ったコメント（今月分） | UserDefaults `insight.monthlyComment`・`insight.cancelReasons` | 翌月の保存時、「データの全削除」 |
| 購読状態 | StoreKit（アプリには保存しない） | — |
| 開発用のプラス切り替え | UserDefaults `debug.forcePremium`（Debug のみ） | — |

詳しくは [data-model.md](data-model.md) を見てください。

## 外部との通信

- App Store（StoreKit）：商品情報の取得・購入・復元・購読状態の確認
- 利用規約のリンク（Apple 標準の使用許諾契約）を Safari で開く
- それ以外の通信はありません。通知はローカル通知、AI は端末内モデル、解析・広告の SDK はありません

## エラー処理の方針

- データベースを開けないときだけ `fatalError` にします（アプリとして動けないため）
- 保存に失敗したら、登録・編集画面でアラートを出します
- 購入・復元の失敗は、ペイウォールと設定画面でアラートを出します
- AI の生成の失敗・時間切れ・出力のチェックでの却下は、ユーザーには見せずに定型のコメントを出します。理由は端末内のログ（`Logger`、カテゴリ `Insight`）に種類だけを残します。生成した文にはサービス名が入ることがあるので、本文は記録しません（Debug ビルドのみ記録）
- 通知の登録の失敗は無視します（次に登録し直すときに回復するため）

## アクセシビリティ

- Dynamic Type：アクセシビリティサイズの文字では、横並びを縦並びにします（`AdaptiveHStack`、`ViewThatFits`）
- VoiceOver：カードは要素をまとめて読み上げ、装飾のアイコンは読み上げません。チェックインのカードは「使った」「使っていない」のアクションで答えられます
- 視差効果を減らす設定では、チェックインのカードを傾けません
- カテゴリの色は、ライト・ダークそれぞれで色覚の多様性に配慮して選び、グラフには必ず名前と金額の凡例を付けます
