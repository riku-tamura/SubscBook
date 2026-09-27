# 開発の決まり

## ファイルの置き方と命名

### 基本

- **ファイル名＝そのファイルが宣言する主な型の名前**です（1ファイル1つの主な型。そのファイルだけで使う `private` の補助型は同じファイルに置いてよい）
- 既存の型への拡張は `型名+目的.swift` にします（例：`Date+Display.swift`、`SubscriptionCategory+Style.swift`、`View+PremiumLock.swift`）
- 型の最初に、何をするものかを1行の `///` コメントで書きます。仕様書の章番号・画面番号があれば添えます（例：`/// 解約候補（5.3）`）

### 用語と英語名

| 日本語 | コードでの名前 |
|---|---|
| サブスク | `Subscription` |
| 有料プラン（サブスク帳プラス） | `Premium`（購読状態の管理は `EntitlementManager`） |
| AIコメント | `Insight` |
| チェックイン | `CheckIn` |
| 通知 | `Notification` |
| 広告 | `Ad`（フォルダは `Ads`） |
| 登録・編集画面 | `SubscriptionForm` |
| 一覧 | `SubscriptionList` |
| ペイウォール | `Paywall` |
| レポート | `Report` |

### フォルダ

| フォルダ | 置くもの | 中の分け方 |
|---|---|---|
| `Models/` | SwiftData のモデル、値型、列挙型、定数 | 機能ごと：`Subscription` / `Insight` / `Notification` / `Premium` / `Ads`（どれにも当てはまらないものは直下。例：`AppLinks`） |
| `Services/` | 計算・判定、外部 API を扱うクラス | 機能ごと（Models と同じ） |
| `ViewModels/` | 画面の状態と操作、画面に出す集計値 | 画面ごと：`App` / `Home` / `SubscriptionList` / `SubscriptionForm` / `CheckIn` / `Report` / `Paywall` / `Settings` / `Onboarding`、共通は `Components` |
| `Views/` | SwiftUI の画面と部品 | 画面ごと（ViewModels と同じ）、共通は `Components` |
| `Formatting/` | 表示用の文字列への変換 | — |
| `Debug/` | Debug ビルドだけで使うもの（全体を `#if DEBUG` で囲む） | — |
| `Resources/` | アセット | — |
| `Config/`（リポジトリ直下） | 自動生成の Info.plist に足す項目 | `SubscBook/` の中に置くとリソースとしてコピーされてしまうため、外に置く |

### 画面

- 画面は `XxxView` と `XxxViewModel` の組にして、`Views/Xxx/` と `ViewModels/Xxx/` に置きます
- その画面だけで使う部品は、画面名を先頭に付けます（例：`HomeCheckInBanner`、`ReportSavingsCard`、`SettingsPremiumSection`、`SubscriptionFormCancelSheet`）
- 2つ以上の画面で使う部品は `Views/Components/` に置き、画面名を付けません

### テスト

- `SubscBookTests/` はアプリ本体と同じフォルダ構成にし、`<型名>Tests.swift` にします
- 共通のヘルパーは `SubscBookTests/Helpers/` に置きます

## ファイルを追加するとき

- プロジェクトはフォルダ同期（`PBXFileSystemSynchronizedRootGroup`）なので、`SubscBook/` か `SubscBookTests/` の下にファイルを置くだけでビルド対象になります。`project.pbxproj` を編集する必要はありません
- `MEMBER_IMPORT_VISIBILITY` が有効なので、ファイルごとに使うモジュールを `import` します。書き忘れると、ほかのファイルで `import` していても「見つからない」エラーになります
  - SwiftData の `FetchDescriptor` や `.init()` の述語 → `import SwiftData`
  - `Mutex` の `withLock` → `import Synchronization`
  - StoreKit の列挙型のケース → `import StoreKit`
- 既定のアクター分離が MainActor なので、ほかのスレッドから使う型・関数（AI の生成で使う値型、通知センターの delegate のメソッド、テストのパラメータで使うヘルパーなど）には `nonisolated` を付けます

## 計算・判定を書くとき

- 状態を持たない `enum` の `static func` にして、`now: Date = .now`・`calendar: Calendar = .current` を引数で受け取ります
- 日付は `calendar.startOfDay(for:)` で日単位にそろえてから比べます
- 数値は `Int`（円）で計算し、表示の直前に `Formatting/` の関数で文字列にします
- 契約中だけを対象にする計算は、関数の中で `filter(\.isActive)` します（呼び出し側に任せない）

## プレビュー

- `#Preview` では `.previewEnvironment()`（サンプルデータ入りなら `.previewEnvironment(seeded: true)`）を付けます
- `previewEnvironment` とサンプルデータは Debug 専用なので、それを使う `#Preview` は `#if DEBUG` で囲みます。囲まないと Release ビルドだけが失敗します

## 開発用の起動オプション

| オプション | 内容 |
|---|---|
| `-seedSampleData` | 既存のデータを消して、サンプルデータ（契約中6件・解約済み2件）を入れる |
| `-forcePremium` | 購入せずにサブスク帳プラスを有効にする |
| `-samplePlans` | StoreKit の商品が読めないときも、ペイウォールにサンプルのプランを出す |
| `-skipOnboarding` | オンボーディングを表示しない |
| `-ignoreAdLimits` | 全画面広告の回数のルールを無視して、区切りのたびに出す |
| `-emptyData` | 既存のデータを消して空にする（オンボーディングから確かめる UI テスト用） |
| `-scheduleTestNotification` | 起動の数秒後に届くチェックインの通知を登録する（終了した状態から通知で開く UI テスト用） |

シミュレータへのインストールと起動をコマンドで行う例：

```bash
xcodebuild -project SubscBook.xcodeproj -scheme SubscBook -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath build/DerivedData build
```

```bash
xcrun simctl install booted build/DerivedData/Build/Products/Debug-iphonesimulator/SubscBook.app
```

```bash
xcrun simctl launch --terminate-running-process booted com.hachimaki.SubscBook -seedSampleData -forcePremium -skipOnboarding
```

`build/` は `.gitignore` に入っています。

サンプルデータ（`SampleData`）の中身：

| サービス | カテゴリ | 金額 | 状態・チェックイン |
|---|---|---|---|
| Netflix | 動画 | 1,590円/月 | 2ヶ月前「使った」 |
| U-NEXT | 動画 | 2,189円/月 | 2ヶ月前・先月とも「使っていない」（解約候補） |
| Disney+ | 動画 | 1,140円/月 | 2ヶ月前「使っていない」 |
| Spotify | 音楽 | 1,080円/月 | 2ヶ月前・先月とも「使った」 |
| iCloud+ | クラウド・ストレージ | 450円/月 | 2ヶ月前・先月とも「使った」 |
| Duolingo Super | 学習 | 12,800円/年 | 5日後にトライアル終了 |
| Kindle Unlimited | 読書・雑誌 | 980円/月 | 95日前に解約 |
| Hulu | 動画 | 1,026円/月 | 40日前に解約 |

登録日はすべて6ヶ月前、動画が3件あるので重複の表示も確かめられます。

## よくある落とし穴

| 症状 | 原因と対処 |
|---|---|
| シミュレータで AIコメントが出ない | シミュレータにはモデルがありません（`ModelManagerError 1026`）。定型のコメントが出れば正常です。AI の出力は実機か Mac の端末内モデルで確かめます |
| シミュレータで起動するとプラスになっている | StoreKit のテストの購入が残っています。Xcode の「Debug → StoreKit → Manage Transactions」で消します（テストは後片付けで消すようになっています） |
| 期限切れにしてもプラスのまま | 期限切れは `Transaction.updates` に流れないことがあります。アプリをフォアグラウンドに戻すと読み直します |
| 閉じた直後にペイウォールが出ない | シートや全画面表示を閉じるアニメーション中は、新しいシートを出せません。`AppRouter.showPaywallAfterDismissal` を使い、閉じ終わったとき（`onDismiss` → `didDismissPresentation`）に出します。時間を決めて待つ方法は使いません |
| Release ビルドだけ失敗する | `#Preview` で Debug 専用のコードを使っています。`#if DEBUG` で囲みます |
| 「型が見つからない」エラー | `MEMBER_IMPORT_VISIBILITY` のため、そのファイルに `import` がありません |
| シミュレータでトラッキングの許可のダイアログが出ない | 一度答えると出ません。アプリを削除して入れ直します。オンボーディング中とプラスの人には出しません |
| 全画面広告が出ない | 使い始めの3日間などの回数のルールがあります。起動オプション `-ignoreAdLimits` で確かめます |
| アプリが終了している状態で、通知から開くと落ちる | 通知の delegate を async 版で書くと、完了の知らせがメインスレッド以外から呼ばれて落ちます。completionHandler 版で、メインスレッドで呼びます（`AppDelegate`）。シミュレータでは `xcrun simctl push` で通知を送って確かめられます |
| 共有で「画像を保存」が出ない | Info.plist に写真への追加の説明（`NSPhotoLibraryAddUsageDescription`）がないと出ません |
| アップロードで ITMS-91053 になる | 理由の申告が必要な API を使ったのに、`PrivacyInfo.xcprivacy` に書いていません（[ads.md](ads.md)） |
| 通知が古いまま | 保存・起動・復帰で自動で登録し直します。保存（`context.save()`）を忘れていないか確かめます。設定画面の「デバッグ → 登録済みの通知」で確認できます |

## コミット

- ブランチ：`main` から作業用のブランチを作ります（MVP は `feature/mvp`）
- コミットメッセージは日本語で、何を変えたかを1行目に書きます
- コミットの前に、テストと Release ビルドが通ることを確かめます

## ドキュメントの更新

仕様・ルール・画面を変えたら、合わせて `docs/` を直してください。特に：

- 計算・判定のルール → [business-rules.md](business-rules.md)
- ファイルの追加・削除・改名 → [file-reference.md](file-reference.md)
- 画面の文言・構成 → [screens.md](screens.md)
- 料金・機能・説明文 → [app-store.md](app-store.md) と、ペイウォール・プライバシーポリシーの文面
- AI のプロンプト・チェック → [ai-insights.md](ai-insights.md)（検証の結果も更新）
