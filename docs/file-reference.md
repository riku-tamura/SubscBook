# ファイルの説明

リポジトリのすべてのファイルの説明です。ファイルを追加・削除・改名したら、ここも直してください。

## リポジトリ直下

| ファイル | 内容 |
|---|---|
| `README.md` | アプリの概要、はじめかた、ドキュメントの案内 |
| `Products.storekit` | StoreKit の商品定義（グループ「サブスク帳プラス」、年額2,400円・1週間無料、月額300円）。スキームの Run とテストで使う |
| `.gitignore` | `build/`・`DerivedData/`・`xcuserdata/`・`.DS_Store` などを除外 |
| `SubscBook.xcodeproj/project.pbxproj` | Xcode プロジェクト。アプリ（`SubscBook`）とテスト（`SubscBookTests`）の2ターゲット、フォルダ同期、ビルド設定 |
| `SubscBook.xcodeproj/xcshareddata/xcschemes/SubscBook.xcscheme` | 共有スキーム。Run に StoreKit 設定（`Products.storekit`）、Test にテストターゲット |

## docs/

| ファイル | 内容 |
|---|---|
| `architecture.md` | 全体の設計 |
| `screens.md` | 画面ごとの設計 |
| `business-rules.md` | 計算・判定のルール、仕様書の章番号との対応 |
| `data-model.md` | データの設計 |
| `notifications.md` | 通知の設計 |
| `premium.md` | 課金の設計 |
| `ai-insights.md` | AIコメントの設計と検証の結果 |
| `testing.md` | テスト |
| `development.md` | 開発の決まり |
| `file-reference.md` | このファイル |
| `app-store.md` | App Store の掲載情報の下書き |

## SubscBook/（アプリ本体）

### 直下

| ファイル | 主な型 | 内容 |
|---|---|---|
| `SubscBookApp.swift` | `SubscBookApp` | アプリの入口。データベースと共有オブジェクト（`EntitlementManager`・`NotificationScheduler`・`InsightProvider`）を作り、Environment で渡す。Debug ではサンプルデータを入れる |
| `AppDelegate.swift` | `AppDelegate` | 通知センターの delegate。アプリを開いている間もバナーを出し、タップされたら `AppRouter.openNotification` を呼ぶ。`AppRouter` を持つ |

### Models/

| ファイル | 主な型 | 内容 |
|---|---|---|
| `AppLinks.swift` | `AppLinks` | アプリから開く外部リンク（利用規約＝Apple 標準の使用許諾契約） |

#### Models/Subscription/

| ファイル | 主な型 | 内容 |
|---|---|---|
| `Subscription.swift` | `Subscription` | 登録したサブスク（SwiftData）。列挙型のアクセサ、`activePredicate`、金額、解約・契約中に戻す、チェックインの記録 |
| `CheckIn.swift` | `CheckIn` | 月次チェックインの回答（SwiftData）。対象月・使ったか・回答日時 |
| `SubscriptionCategory.swift` | `SubscriptionCategory` | カテゴリ10種と表示名。重複検出の対象か（「その他」は除く） |
| `SubscriptionStatus.swift` | `SubscriptionStatus` | 契約中・解約済み |
| `BillingCycle.swift` | `BillingCycle` | 支払い周期（毎月・毎年）と表示名・単位・月数 |
| `YearMonth.swift` | `YearMonth` | 年月の値型。"2026-09" 形式との変換、前後の月、月初の日付 |
| `CancelSuggestion.swift` | `CancelSuggestion` | 解約候補（サブスク・連続未使用月数・1年あたりの金額） |
| `DuplicateGroup.swift` | `DuplicateGroup` | 同じカテゴリで重複しているサブスクのまとまりと月額の合計 |
| `ServicePreset.swift` | `ServicePreset` | サービス名の候補1件（名前・カテゴリ・読み） |
| `ServicePresetCatalog.swift` | `ServicePresetCatalog` | 主要66サービスの候補と、表記ゆれを吸収する検索 |

#### Models/Insight/

| ファイル | 主な型 | 内容 |
|---|---|---|
| `MonthlyInsightFacts.swift` | `MonthlyInsightFacts` | 今月のひとことを決める材料（件数・前月比・解約候補・重複・今月の解約）と、事実にない話題の語 |
| `CancelReasonFacts.swift` | `CancelReasonFacts` | 解約候補の理由の材料と、AI に渡す箇条書き・キャッシュのキー |
| `MonthlyInsight.swift` | `MonthlyInsight` | 今月のひとことの AI の出力形式（`@Generable`、iOS 26+） |
| `CancelReason.swift` | `CancelReason` | 解約候補の理由の AI の出力形式（`@Generable`、iOS 26+） |
| `InsightResult.swift` | `InsightResult` | コメントの結果（文と、AI で作れたか） |
| `SpendingTrend.swift` | `SpendingTrend` | 前月と比べた支払いの増減 |

#### Models/Notification/

| ファイル | 主な型 | 内容 |
|---|---|---|
| `PlannedNotification.swift` | `PlannedNotification` | 登録するローカル通知1件分（種類・文面・日時／毎月の繰り返し） |
| `NotificationPreferences.swift` | `NotificationPreferences` | 通知ごとの ON/OFF と、UserDefaults からの読み込み |

#### Models/Premium/

| ファイル | 主な型 | 内容 |
|---|---|---|
| `PremiumProducts.swift` | `PremiumProducts` | 商品 ID（年額・月額）と表示順 |
| `PremiumFeature.swift` | `PremiumFeature` | サブスク帳プラスの5機能の名前・説明・アイコン |
| `FreePlan.swift` | `FreePlan` | 無料プランの上限（契約中5件）と、追加できるかの判定 |

### Services/

#### Services/Subscription/

| ファイル | 主な型 | 内容 |
|---|---|---|
| `CostCalculator.swift` | `CostCalculator` | 月額換算・1年あたりの支払額・合計（5.1） |
| `PaymentDateCalculator.swift` | `PaymentDateCalculator` | 次回支払日を1周期進める、過ぎた支払日を今日以降へ進める、保存済みデータの一括更新（5.2） |
| `CheckInPolicy.swift` | `CheckInPolicy` | チェックインの対象月・対象サブスク・未回答の抽出（5.6） |
| `CancelSuggestionDetector.swift` | `CancelSuggestionDetector` | 解約候補の判定と、連続未使用月数（5.3） |
| `DuplicateDetector.swift` | `DuplicateDetector` | 重複の検出（5.4） |
| `SavingsCalculator.swift` | `SavingsCalculator` | 解約で浮くお金（1年あたり）と節約累計、満了月数（5.5） |

#### Services/Notification/

| ファイル | 主な型 | 内容 |
|---|---|---|
| `NotificationPlanner.swift` | `NotificationPlanner` | 通知の予定を組み立てる純粋な関数（支払日の前日・トライアル終了・月次チェックイン、上限64件） |
| `NotificationScheduler.swift` | `NotificationScheduler` | 通知の許可と登録。データの保存を監視して登録し直す |

#### Services/Premium/

| ファイル | 主な型 | 内容 |
|---|---|---|
| `EntitlementManager.swift` | `EntitlementManager` | 商品の読み込み、購読状態の判定、購入・復元、取引の監視。Debug の開発用切り替え |

#### Services/Insight/

| ファイル | 主な型 | 内容 |
|---|---|---|
| `InsightService.swift` | `InsightService` | コメント生成の共通の形（AI 版とテンプレート版） |
| `FoundationModelInsightService.swift` | `FoundationModelInsightService` | 端末内モデルでの生成（今月のひとことは定型文の言い換え、理由は事実から）。指示・条件・時間切れ・チェック・失敗時の定型文 |
| `TemplateInsightService.swift` | `TemplateInsightService` | 定型のコメント。今月のひとことの「伝える内容」を選ぶ役も持つ |
| `InsightProvider.swift` | `InsightProvider` | AI の可用性で実装を切り替え、キャッシュと同時要求のまとめを行う |
| `InsightAvailability.swift` | `InsightAvailability` | AI が使えるかの判定と、設定画面の説明 |
| `InsightFactsBuilder.swift` | `InsightFactsBuilder` | サブスクのデータから材料（事実）を組み立てる。前月比の判定 |
| `InsightSanitizer.swift` | `InsightSanitizer` | AI の出力のチェック（長さ・目的と逆の表現・事実にない話題・数字や英字） |
| `InsightCache.swift` | `InsightCache` | AI が作ったコメントのキャッシュ（UserDefaults、今月分だけ） |
| `Timeout.swift` | `withTimeout`・`TimeoutError`・`ResumeGate`・`TimerHolder` | 指定時間で処理を打ち切る関数。先に終わったら見張りのタスクも止める |

### ViewModels/

#### ViewModels/App/

| ファイル | 主な型 | 内容 |
|---|---|---|
| `AppRouter.swift` | `AppRouter` | タブ・登録編集シート・ペイウォール・チェックインの表示状態と遷移の操作 |
| `SubscriptionFormRoute.swift` | `SubscriptionFormRoute` | 登録・編集画面を新規と編集のどちらで開くか |

#### ViewModels/Components/

| ファイル | 主な型 | 内容 |
|---|---|---|
| `InsightViewModel.swift` | `InsightViewModel` | 今月のひとことと解約候補の理由の読み込み（ホーム・レポート共通） |

#### ViewModels/Home/

| ファイル | 主な型 | 内容 |
|---|---|---|
| `HomeViewModel.swift` | `HomeViewModel` | ② ホームの状態と操作 |
| `HomeSummary.swift` | `HomeSummary` | ホームに出す集計値（合計・件数・直近3件・解約候補・未回答のチェックイン） |

#### ViewModels/SubscriptionList/

| ファイル | 主な型 | 内容 |
|---|---|---|
| `SubscriptionListViewModel.swift` | `SubscriptionListViewModel` | ③ 一覧の状態（並び順の保存、解約済みの開閉、無料プランの案内） |
| `SubscriptionListSections.swift` | `SubscriptionListSections` | 契約中・解約済みのセクションと並び替え |
| `SubscriptionSortOrder.swift` | `SubscriptionSortOrder` | 並び順（支払日順・金額順・カテゴリ順） |

#### ViewModels/SubscriptionForm/

| ファイル | 主な型 | 内容 |
|---|---|---|
| `SubscriptionFormViewModel.swift` | `SubscriptionFormViewModel` | ④ 登録・編集の入力、候補、カテゴリの自動設定、保存できない理由、保存 |

#### ViewModels/CheckIn/

| ファイル | 主な型 | 内容 |
|---|---|---|
| `CheckInViewModel.swift` | `CheckInViewModel` | ⑤ チェックインの進行（聞く順番・回答・戻る・聞くものがない理由） |

#### ViewModels/Report/

| ファイル | 主な型 | 内容 |
|---|---|---|
| `ReportViewModel.swift` | `ReportViewModel` | ⑥ レポートの状態と、共有画像の作成 |
| `ReportSummary.swift` | `ReportSummary` | レポートに出す集計値 |
| `CategoryBreakdown.swift` | `CategoryBreakdown` | カテゴリ別の月額と割合（円グラフ） |
| `SavingsSummary.swift` | `SavingsSummary` | 解約で浮くお金・節約累計・解約件数 |

#### ViewModels/Paywall/

| ファイル | 主な型 | 内容 |
|---|---|---|
| `PaywallViewModel.swift` | `PaywallViewModel` | ⑦ ペイウォールの状態（選択中のプラン・購入・復元・メッセージ） |
| `PaywallPlan.swift` | `PaywallPlan` | 表示するプラン（価格・月あたり・無料期間の表記）。Debug のサンプル |
| `PaywallReason.swift` | `PaywallReason` | ペイウォールを開いたきっかけと、見出し・説明 |
| `PaywallMessage.swift` | `PaywallMessage` | 購入・復元の結果のアラート |

#### ViewModels/Settings/

| ファイル | 主な型 | 内容 |
|---|---|---|
| `SettingsViewModel.swift` | `SettingsViewModel` | 設定の状態（バージョン、プラン名、期限の表記、復元、データの全削除） |

#### ViewModels/Onboarding/

| ファイル | 主な型 | 内容 |
|---|---|---|
| `OnboardingViewModel.swift` | `OnboardingViewModel` | ① オンボーディングのページと通知の許可 |

### Views/

#### Views/App/

| ファイル | 主な型 | 内容 |
|---|---|---|
| `RootView.swift` | `RootView` | オンボーディングとタブの切り替え。起動・復帰時の支払日の更新・通知・AI・購読状態の読み直し |
| `MainTabView.swift` | `MainTabView` | 4つのタブと、アプリ全体で使うシート・全画面表示 |

#### Views/Components/

| ファイル | 主な型 | 内容 |
|---|---|---|
| `TotalsCard.swift` | `TotalsCard` | 月額換算の合計・1年あたり・契約件数のカード |
| `InsightCard.swift` | `InsightCard` | 今月のひとことのカード（「Apple Intelligence で作成」の表示付き） |
| `CancelSuggestionRow.swift` | `CancelSuggestionRow` | 解約候補の1行 |
| `CardHeader.swift` | `CardHeader` | カードの見出し |
| `CategoryIcon.swift` | `CategoryIcon` | 頭文字とカテゴリの色のアイコン |
| `PremiumBadge.swift` | `PremiumBadge` | 「プラス」のバッジ |
| `AdaptiveHStack.swift` | `AdaptiveHStack` | 大きな文字では縦に積む横並び |
| `View+Card.swift` | `View.card()` | カードの見た目 |
| `View+PremiumLock.swift` | `View.premiumLocked(_:feature:)` | 無料ユーザーへのぼかしと鍵、タップでペイウォール |
| `SubscriptionCategory+Style.swift` | `SubscriptionCategory` の拡張 | カテゴリの色（ライト・ダーク）・文字色・アイコン |

#### Views/Onboarding/

| ファイル | 主な型 | 内容 |
|---|---|---|
| `OnboardingView.swift` | `OnboardingView` | ① 3ページの切り替えと、終了の記録 |
| `OnboardingPageLayout.swift` | `OnboardingPageLayout` | 各ページ共通のレイアウト（ページの印・アイコン・見出し・ボタン） |
| `OnboardingStepIndicator.swift` | `OnboardingStepIndicator` | 何ページ目かの印（●○○） |
| `OnboardingValuePage.swift` | `OnboardingValuePage` | 1ページ目：価値の説明 |
| `OnboardingNotificationPage.swift` | `OnboardingNotificationPage` | 2ページ目：通知の許可 |
| `OnboardingFirstSubscriptionPage.swift` | `OnboardingFirstSubscriptionPage` | 3ページ目：最初のサブスクの登録 |

#### Views/Home/

| ファイル | 主な型 | 内容 |
|---|---|---|
| `HomeView.swift` | `HomeView` | ② ホーム |
| `HomeCheckInBanner.swift` | `HomeCheckInBanner` | 未回答のチェックインのバナー |
| `HomeCancelSuggestionsCard.swift` | `HomeCancelSuggestionsCard` | 解約候補（上位3件・「すべて見る」） |
| `HomeUpcomingPaymentsCard.swift` | `HomeUpcomingPaymentsCard` | 次の支払い（直近3件） |

#### Views/SubscriptionList/

| ファイル | 主な型 | 内容 |
|---|---|---|
| `SubscriptionListView.swift` | `SubscriptionListView` | ③ 一覧（並び替え・解約済みの開閉） |
| `SubscriptionListRow.swift` | `SubscriptionListRow` | 一覧の1行 |

#### Views/SubscriptionForm/

| ファイル | 主な型 | 内容 |
|---|---|---|
| `SubscriptionFormView.swift` | `SubscriptionFormView` | ④ 登録・編集（候補・保存・解約・契約中に戻す・削除） |
| `SubscriptionFormCancelSheet.swift` | `SubscriptionFormCancelSheet` | 解約した日を選ぶシート（登録日〜今日） |

#### Views/CheckIn/

| ファイル | 主な型 | 内容 |
|---|---|---|
| `CheckInView.swift` | `CheckInView` | ⑤ チェックインの全画面（開始時の対象を決める） |
| `CheckInQuestionView.swift` | `CheckInQuestionView` | 進み具合と回答中のカード、完了画面への切り替え |
| `CheckInCard.swift` | `CheckInCard` | 「先月使いましたか？」のカード（ボタン・スワイプ・VoiceOver） |
| `CheckInCompletionView.swift` | `CheckInCompletionView` | 完了画面（聞くものがない理由、解約候補への案内） |

#### Views/Report/

| ファイル | 主な型 | 内容 |
|---|---|---|
| `ReportView.swift` | `ReportView` | ⑥ 振り返りレポート |
| `ReportCategoryChartCard.swift` | `ReportCategoryChartCard` | カテゴリ別の円グラフと凡例 |
| `ReportPremiumSection.swift` | `ReportPremiumSection` | レポートのサブスク帳プラスの部分 |
| `ReportCancelSuggestionsCard.swift` | `ReportCancelSuggestionsCard` | 解約候補の一覧（理由付き） |
| `ReportDuplicatesCard.swift` | `ReportDuplicatesCard` | 重複しているサブスク |
| `ReportSavingsCard.swift` | `ReportSavingsCard` | 解約で浮くお金・節約累計・共有ボタン |
| `ReportShareImage.swift` | `ReportShareImage` | SNS 共有用の画像（サービス名は載せない） |

#### Views/Paywall/

| ファイル | 主な型 | 内容 |
|---|---|---|
| `PaywallView.swift` | `PaywallView` | ⑦ ペイウォール |
| `PaywallPlanCard.swift` | `PaywallPlanCard` | プランの選択カード |

#### Views/Settings/

| ファイル | 主な型 | 内容 |
|---|---|---|
| `SettingsView.swift` | `SettingsView` | 設定 |
| `SettingsPremiumSection.swift` | `SettingsPremiumSection` | サブスク帳プラスの状態・契約の管理・復元 |
| `SettingsNotificationSection.swift` | `SettingsNotificationSection` | 通知の許可と ON/OFF |
| `SettingsInsightSection.swift` | `SettingsInsightSection` | AIコメントが使えるかと理由 |
| `SettingsAboutSection.swift` | `SettingsAboutSection` | 利用規約・プライバシーポリシー・バージョン |
| `SettingsDataDeletionSection.swift` | `SettingsDataDeletionSection` | データの全削除 |
| `SettingsDebugSection.swift` | `SettingsDebugSection` | Debug のみ：プラスの切り替え、登録済みの通知 |
| `PrivacyPolicyView.swift` | `PrivacyPolicyView` | プライバシーポリシーの本文（収集する情報・AI・通知・支払い・広告・削除・改定・お問い合わせ） |

### Formatting/

| ファイル | 主な型 | 内容 |
|---|---|---|
| `Int+Yen.swift` | `Int.yenText` | "1,490円" |
| `Date+Display.swift` | `Date` の拡張 | "10月15日(木)"、"2026年10月15日"、"今日"・"明日"・"あと3日" |
| `YearMonth+Display.swift` | `YearMonth` の拡張 | "8月"、"2026年8月" |
| `Subscription+Display.swift` | `Subscription` の拡張 | "1,490円/月" と VoiceOver 用の "1,490円、毎月" |
| `Locale+Japanese.swift` | `Locale.japanese` | 表示に使うロケール（ja_JP） |

### Debug/（Debug ビルドのみ）

| ファイル | 主な型 | 内容 |
|---|---|---|
| `DebugLaunchOptions.swift` | `DebugLaunchOptions` | 起動オプション（`-seedSampleData`・`-forcePremium`・`-samplePlans`・`-skipOnboarding`） |
| `SampleData.swift` | `SampleData` | 画面確認用のサンプルデータ（8件） |
| `View+PreviewEnvironment.swift` | `View.previewEnvironment(seeded:)` | プレビュー用に、インメモリのデータと共有オブジェクトを用意する |

### Resources/

| ファイル | 内容 |
|---|---|
| `Assets.xcassets/Contents.json` | アセットカタログ |
| `Assets.xcassets/AppIcon.appiconset/AppIcon.png`・`Contents.json` | アプリアイコン（1枚の画像から全サイズ） |
| `Assets.xcassets/AccentColor.colorset/Contents.json` | アクセントカラー（ボタン・強調の色） |

## SubscBookTests/（単体テスト）

各テストの内容は [testing.md](testing.md#スイートの一覧) を見てください。

### Helpers/

| ファイル | 内容 |
|---|---|
| `Calendar+Tokyo.swift` | 東京時間のカレンダー `Calendar.tokyo` と、日時を作る `date(...)` |
| `TestStore.swift` | インメモリの SwiftData ストアと、サブスクを入れる `addSubscription` |
| `StubInsightService.swift` | 呼ばれた回数を数える、AI のコメント生成の代わり |

### Models/

| ファイル | 対象 |
|---|---|
| `Premium/FreePlanTests.swift` | `FreePlan` |
| `Subscription/ServicePresetCatalogTests.swift` | `ServicePresetCatalog` |
| `Subscription/SubscriptionTests.swift` | `Subscription`・`CheckIn` |
| `Subscription/YearMonthTests.swift` | `YearMonth` |

### Services/

| ファイル | 対象 |
|---|---|
| `Subscription/CostCalculatorTests.swift` | `CostCalculator` |
| `Subscription/PaymentDateCalculatorTests.swift` | `PaymentDateCalculator` |
| `Subscription/CheckInPolicyTests.swift` | `CheckInPolicy` |
| `Subscription/CancelSuggestionDetectorTests.swift` | `CancelSuggestionDetector` |
| `Subscription/DuplicateDetectorTests.swift` | `DuplicateDetector` |
| `Subscription/SavingsCalculatorTests.swift` | `SavingsCalculator` |
| `Notification/NotificationPlannerTests.swift` | `NotificationPlanner` |
| `Premium/StoreKitTests.swift` | `EntitlementManager`・`PaywallPlan`・`PaywallViewModel`（StoreKitTest） |
| `Insight/InsightFactsBuilderTests.swift` | `InsightFactsBuilder`・`MonthlyInsightFacts`・`CancelReasonFacts` |
| `Insight/InsightProviderTests.swift` | `InsightProvider`・`InsightCache` |
| `Insight/InsightSanitizerTests.swift` | `InsightSanitizer` |
| `Insight/TemplateInsightServiceTests.swift` | `TemplateInsightService` |
| `Insight/TimeoutTests.swift` | `withTimeout` |

### ViewModels/

| ファイル | 対象 |
|---|---|
| `App/AppRouterTests.swift` | `AppRouter` |
| `CheckIn/CheckInViewModelTests.swift` | `CheckInViewModel` |
| `Components/InsightViewModelTests.swift` | `InsightViewModel` |
| `Home/HomeSummaryTests.swift` | `HomeSummary` |
| `Home/HomeViewModelTests.swift` | `HomeViewModel` |
| `Onboarding/OnboardingViewModelTests.swift` | `OnboardingViewModel` |
| `Paywall/PaywallPlanTests.swift` | `PaywallPlan` |
| `Paywall/PaywallViewModelTests.swift` | `PaywallViewModel` |
| `Report/CategoryBreakdownTests.swift` | `CategoryBreakdown` |
| `Report/ReportViewModelTests.swift` | `ReportViewModel` |
| `Report/SavingsSummaryTests.swift` | `SavingsSummary` |
| `Settings/SettingsViewModelTests.swift` | `SettingsViewModel` |
| `SubscriptionForm/SubscriptionFormViewModelTests.swift` | `SubscriptionFormViewModel` |
| `SubscriptionList/SubscriptionListSectionsTests.swift` | `SubscriptionListSections` |
| `SubscriptionList/SubscriptionListViewModelTests.swift` | `SubscriptionListViewModel` |
