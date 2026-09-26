# データの設計

## SwiftData のモデル

データベースは `ModelContainer(for: Subscription.self, CheckIn.self)` で、アプリのコンテナ内に保存します（iCloud 同期なし）。

```
Subscription 1 ──── * CheckIn
             （サブスクを削除すると、チェックインも削除される）
```

### Subscription（登録したサブスク）

`SubscBook/Models/Subscription/Subscription.swift`

| プロパティ | 型 | 内容 |
|---|---|---|
| `id` | `UUID` | 識別子。通知の識別子やキャッシュのキーにも使う |
| `name` | `String` | サービス名（前後の空白を除いて保存） |
| `categoryRawValue` | `String` | カテゴリ（`SubscriptionCategory` の rawValue） |
| `price` | `Int` | 1回あたりの支払額（円） |
| `cycleRawValue` | `String` | 支払い周期（`BillingCycle` の rawValue） |
| `nextPaymentDate` | `Date` | 次回支払日（その日の 0:00） |
| `billingDay` | `Int` | 支払日の基準日（1〜31）。月末で日付が縮んでも元の日に戻すため |
| `trialEndDate` | `Date?` | 無料トライアルの終了日（その日の 0:00）。トライアルでなければ nil |
| `statusRawValue` | `String` | 契約中か解約済みか（`SubscriptionStatus` の rawValue） |
| `canceledAt` | `Date?` | 解約日。契約中なら nil |
| `createdAt` | `Date` | 登録日。チェックインの対象判定と前月比に使う |
| `checkIns` | `[CheckIn]` | チェックインの回答（`deleteRule: .cascade`） |

列挙型は `#Predicate` で扱えないため、rawValue の文字列で保存し、`category` / `cycle` / `status` のアクセサで読み書きします。不明な値は `.other` / `.monthly` / `.active` として読みます。

主なメソッド：

| メソッド | 内容 |
|---|---|
| `activePredicate` | 契約中のサブスクだけを取得する述語（`@Query` / `FetchDescriptor` 用） |
| `monthlyEquivalent` / `annualCost` | 月額換算・1年あたりの支払額 |
| `setNextPaymentDate(_:)` | 支払日を変え、基準日も更新する |
| `setTrialEndDate(_:)` | トライアルの終了日を 0:00 にそろえて設定する |
| `cancel(at:)` | 解約済みにして、解約日を記録する |
| `reactivate(now:)` | 契約中に戻し、解約日を消して、過ぎた支払日を進める |
| `checkIn(for:)` | 指定月の回答（同じ月に複数あれば最後のもの） |
| `recordCheckIn(for:used:at:)` | 指定月の回答を記録する（あれば上書き） |

### CheckIn（月次チェックインの回答）

`SubscBook/Models/Subscription/CheckIn.swift`

| プロパティ | 型 | 内容 |
|---|---|---|
| `id` | `UUID` | 識別子 |
| `month` | `String` | 対象月（"2026-09" 形式） |
| `used` | `Bool` | その月に使ったか |
| `answeredAt` | `Date` | 回答した日時。同じ月の回答が複数あるときは新しいものを使う |
| `subscription` | `Subscription?` | 回答したサブスク |

### スキーマを変えるとき

リリース後にモデルのプロパティを変えるときは、SwiftData の移行（`VersionedSchema` と `SchemaMigrationPlan`）を用意してください。今はバージョン1のみで、移行の仕組みはまだありません。プロパティの追加だけなら、既定値を付ければ自動で移行されます。

## 値型・列挙型

| 型 | 値 | 内容 |
|---|---|---|
| `SubscriptionCategory` | video / music / reading / game / cloud / work / fitness / learning / news / other | 表示名は 動画・音楽・読書・雑誌・ゲーム・クラウド・ストレージ・仕事・ツール・フィットネス・学習・ニュース・その他。この定義順が、グラフの色の並びと重複の表示順になる。色とアイコンは `SubscriptionCategory+Style.swift` |
| `BillingCycle` | monthly / yearly | 表示名「毎月」「毎年」、単位「月」「年」、1周期の月数 1・12 |
| `SubscriptionStatus` | active / canceled | 契約中・解約済み |
| `YearMonth` | year・month | 年月。"2026-09" 形式と相互変換。月の範囲外は年をまたいで正規化（13月 → 翌年1月） |
| `ServicePreset` | name・category・reading | サービス名の候補 |
| `CancelSuggestion` | subscription・unusedMonths・annualCost | 解約候補 |
| `DuplicateGroup` | category・subscriptions | 重複しているサブスクのまとまり |
| `PlannedNotification` | identifier・kind・title・body・trigger・subscriptionID | 登録するローカル通知1件分 |
| `NotificationPreferences` | paymentReminder・trialReminder・checkInReminder | 通知ごとの ON/OFF |
| `SpendingTrend` | increased / decreased / unchanged / unknown | 前月と比べた支払いの増減 |
| `MonthlyInsightFacts` | 契約件数・増減・解約候補・重複・今月の解約件数 | 月次のひとことを決める材料 |
| `CancelReasonFacts` | サービス名・カテゴリ・未使用月数・周期・同じカテゴリの別契約の有無 | 解約候補の理由の材料 |
| `InsightResult` | text・isGenerated | AIコメントの結果（AI で作れたか付き） |
| `PremiumFeature` | 5機能 | サブスク帳プラスの機能の名前・説明・アイコン |

## UserDefaults のキー

| キー | 型 | 内容 | 定義している場所 |
|---|---|---|---|
| `onboarding.completed` | Bool | オンボーディングを終えたか | `OnboardingViewModel.completedKey` |
| `list.sortOrder` | String | 一覧の並び順（paymentDate / price / category） | `SubscriptionListViewModel.sortOrderKey` |
| `notifications.paymentReminder` | Bool | 支払日の前日の通知（既定 ON） | `NotificationPreferences` |
| `notifications.trialReminder` | Bool | トライアル終了の通知（既定 ON・プラスのみ） | `NotificationPreferences` |
| `notifications.checkInReminder` | Bool | 月次チェックインの通知（既定 ON） | `NotificationPreferences` |
| `insight.monthlyComment` | [String: String] | AI が作った今月のひとこと（キー：`年月|元の文`） | `InsightCache` |
| `insight.cancelReasons` | [String: String] | AI が作った解約候補の理由（キー：`年月|サブスクID|月数|事実`） | `InsightCache` |
| `debug.forcePremium` | Bool | 開発用：購入せずにプラスを有効にする（Debug のみ） | `EntitlementManager.debugForcePremiumKey` |

AI のキャッシュは、保存するときに今月以外のものを消すので、今月分だけが残ります。

## 「データの全削除」で消えるもの

`SettingsViewModel.deleteAllData`

- 消える：すべてのサブスクとチェックイン、AI のキャッシュ、登録済みの通知（保存のあとに自動で登録し直され、空になる）
- 消えない：サブスク帳プラスの契約（App Store の契約なので、「設定」アプリから解約する）、オンボーディング済みの記録、並び順、通知の ON/OFF

保存に失敗したときは削除を取り消します（残すと、ほかの保存のときに削除されてしまうため）。

`@Query` の表示が確実に更新されるよう、`delete(model:)` でまとめて消さず、1件ずつ削除しています。
