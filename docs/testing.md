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

今は 142件（32スイート）で、数秒で終わります。

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

## StoreKit のテスト

`StoreKitTests` はリポジトリ直下の `Products.storekit` を `SKTestSession` で読みます。

- ファイルは、テストのソースの場所から上のフォルダへたどって探します（フォルダの移動に強くするため。日本語や空白を含むパスでも見つかるよう、デコードしたパスで比べます）
- スイートは `.serialized` で、1件ずつ順に動かします（購入の状態を共有するため）
- 各テストの始めと終わりに購入履歴を消します。消さないと、シミュレータの StoreKit の環境に購入が残り、アプリを起動したときにプラスになってしまいます
- 期限切れのテストは、StoreKit の時間の進み方の都合で反映が遅れることがあるので、状態が変わるまで少し待ちながら確かめます

## スイートの一覧

### Models

| スイート | 確かめること |
|---|---|
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
| 画面遷移（`AppRouterTests`） | 上限でペイウォール、通知のタップでの遷移（チェックイン中の支払い通知で閉じる）、閉じ終わってからペイウォールを出す |
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
