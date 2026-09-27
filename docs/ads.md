# 広告の設計

無料プランの収益のため、Google AdMob で広告を表示します。サブスク帳プラスでは広告を表示しません（プラスの機能「広告なし」）。

## 方針

| 項目 | 決めたこと |
|---|---|
| 広告サービス | Google AdMob（Swift Package `swift-package-manager-google-mobile-ads` 13.x） |
| 出す場所 | ホーム・一覧・レポートの下のバナー、区切りのよいところでの全画面広告 |
| 出さない場所 | オンボーディング・登録と編集・チェックインの途中・ペイウォール・設定 |
| サブスク帳プラス | 広告を出さない。トラッキングの許可も求めない |
| トラッキング | 許可を求める（許可した人にはパーソナライズ広告） |
| 広告に渡さないもの | 登録したサブスク・チェックインの回答・AIコメント（広告のリクエストにアプリのデータを入れない） |
| 配信地域 | 日本のみ（下の「同意の確認」を参照） |

## 流れ

1. オンボーディングを終え、アプリが前面にあるときに、`RootView` が購読状態を読み直してから `AdManager.prepareIfNeeded(isPremium:)` を呼ぶ
   - オンボーディング中は呼ばない（通知の許可のダイアログと重ならないように）
   - プラスの人には何もしない（プラスの期限が切れたら、そのときに準備する）
   - 単体テストの実行中は動かさない
2. トラッキングの許可がまだなら、ダイアログを出す（前面になった直後は出ないことがあるので0.5秒待つ）
3. `MobileAds.shared.start()` で SDK を始め、`isReady` を true にする（バナーが出せるようになる）
4. 全画面広告を1つ読み込んでおく。表示して閉じたら、次を読み込む

## バナー

`AdBanner`（`Views/Components/AdBanner.swift`）

- ホーム・一覧・レポートの `safeAreaInset(edge: .bottom)` に置く（タブバーの上に出る）
- サイズは幅に合わせたアンカー型アダプティブバナー（`largeAnchoredAdaptiveBanner(width:)`、高さ50〜150pt）
- 広告が届くまでは高さ0で場所を取らない。届かなかったら0に戻す
- SwiftUI にバナーの大きさを決めさせると広告がずれるため、入れ物の `UIView` の中央に広告の大きさで置く

## 全画面広告

`AdManager.showInterstitialIfAllowed(isPremium:)`

出すきっかけ（どちらも、画面が閉じ終わってから）：

| きっかけ | 条件 |
|---|---|
| チェックインを終えて閉じたとき | 今回1件以上答えたとき（途中でやめた・答えるものがなかったときは出さない） |
| サブスクを新しく登録して閉じたとき | オンボーディング中の登録と、編集では出さない |

閉じるアニメーション中は表示が無視されるため、`AppRouter.requestInterstitialAfterDismissal()` で依頼しておき、`MainTabView` の `onDismiss` で出します。ほかに待っている画面（ペイウォールなど）があればそちらを優先し、広告は出しません。

回数のルール（`InterstitialAdPolicy`）：

- 使い始めて3日間は出さない
- 前回から2日たつまで出さない
- 直近30日で4回まで

アプリを初めて起動した日時と、出した日時は UserDefaults（`ads.firstLaunchDate`・`ads.interstitialShownDates`）に保存します。

## 広告ユニット ID

ID は Build Settings で設定し、`Config/SubscBook-Info.plist` から読みます（`AdUnitIDs`）。

| Build Setting | Info.plist のキー | 今の値（Google のテスト用） |
|---|---|---|
| `ADMOB_APP_ID` | `GADApplicationIdentifier` | `ca-app-pub-3940256099942544~1458002511` |
| `ADMOB_BANNER_UNIT_ID` | `SubscBookAdMobBannerUnitID` | `ca-app-pub-3940256099942544/2435281174` |
| `ADMOB_INTERSTITIAL_UNIT_ID` | `SubscBookAdMobInterstitialUnitID` | `ca-app-pub-3940256099942544/4411468910` |

**公開前に、AdMob で作ったアプリ ID と広告ユニット ID に差し替えてください**（Target → Build Settings の Release の値）。Debug はテスト用のままにします（自分で自分の広告をタップすると、AdMob のアカウントが停止されることがあるため）。Release でテスト用の ID のままのときは、起動時にログにエラーを出します。

`Config/SubscBook-Info.plist` は、自動生成の Info.plist に足す項目だけを書いたファイルです。`SubscBook/` の外に置いているのは、フォルダ同期でリソースとしてコピーされないようにするためです。

## トラッキングの許可

- ダイアログの説明文：「あなたの興味に合った広告を表示するために使います。登録したサブスクの情報は広告に使いません。」（`INFOPLIST_KEY_NSUserTrackingUsageDescription`）
- 許可されなくても広告は出ます（パーソナライズしない広告）
- 設定画面の「広告 → トラッキングの許可を変更」から、設定アプリのこのアプリの画面を開けます

## 広告の効果測定（SKAdNetwork）

`Config/SubscBook-Info.plist` の `SKAdNetworkItems` に Google の ID（`cstr6suwn9.skadnetwork`）を入れています。**公開前に、AdMob のドキュメントにある最新の一覧（他社の広告ネットワークの ID を含む）に更新してください。**

## 同意の確認（GDPR など）

ヨーロッパ（EEA・英国・スイス）の利用者にパーソナライズ広告を出すには、Google が認定した同意確認の画面（Google の UMP SDK など）が必要です。今回は実装していないため、**App Store Connect で配信地域を日本のみにしてください。** ほかの国に配信する場合は、UMP SDK（Google Mobile Ads SDK の依存として入っています）で同意確認の画面を実装してから広げます。

## プライバシーの表示

広告を入れたことで、次の表示を変えています（App Store Connect の入力は [app-store.md](app-store.md)）。

- プライバシーポリシー：「広告」の項目（Google が集める情報、アプリのデータは広告に使わないこと、トラッキングの変え方）
- オンボーディング・ホーム：「データは端末の外に出ません」→「登録したデータは端末の外に出ません」
- 設定：無料プランに「広告」のセクション（広告を非表示にする＝ペイウォール、トラッキングの許可を変更）
- ペイウォール：プラスの機能に「広告なし」

## 開発での確認

- Debug ビルドは常にテスト用の広告（「Test mode」と表示される）
- 起動オプション `-ignoreAdLimits`：全画面広告の回数のルールを無視して、毎回出す
- `-forcePremium`：広告が出ないことを確かめる
- トラッキングの許可をやり直すには、アプリを削除して入れ直す

## ファイル

| ファイル | 内容 |
|---|---|
| `Config/SubscBook-Info.plist` | AdMob の ID・SKAdNetwork |
| `SubscBook/Models/Ads/AdUnitIDs.swift` | 広告ユニット ID の読み込み |
| `SubscBook/Models/Ads/InterstitialAdPolicy.swift` | 全画面広告の回数のルール |
| `SubscBook/Services/Ads/AdManager.swift` | トラッキングの許可・SDK の開始・全画面広告 |
| `SubscBook/Views/Components/AdBanner.swift` | バナー |
| `SubscBook/Views/Settings/SettingsAdSection.swift` | 設定の「広告」セクション |
