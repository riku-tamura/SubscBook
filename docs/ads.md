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

1. オンボーディングを終え、アプリが前面にあり、購読状態を一度読み終えている（`EntitlementManager.hasLoadedEntitlements`）ときに、`RootView` が `AdManager.prepareIfNeeded(isPremium:)` を呼ぶ
   - 購読状態を読み終えるまでは呼ばない（プラスかどうかわからないうちに、プラスの人へトラッキングの許可を求めないため）
   - オンボーディング中は呼ばない（通知の許可のダイアログと重ならないように）
   - プラスの人には何もしない（プラスの期限が切れたら、そのときに準備する）
   - 単体テストの実行中は動かさない
2. トラッキングの許可がまだなら、ダイアログを出す（前面になった直後は出ないことがあるので0.5秒待つ）
3. `MobileAds.shared.start()` で SDK を始め、`isReady` を true にする（バナーが出せるようになる）
4. 全画面広告を1つ読み込んでおく。表示して閉じたら、次を読み込む。読み込めなかったときは、次に出すきっかけや前面に戻ったときに読み込み直す

## バナー

`AdBanner`（`Views/Components/AdBanner.swift`）

- ホーム・一覧・レポートの `safeAreaInset(edge: .bottom)` に置く（タブバーの上に出る）
- サイズは幅に合わせたアンカー型アダプティブバナー（`largeAnchoredAdaptiveBanner(width:)`、高さ50〜150pt）
- 広告が届くまでは高さ0で場所を取らない。最初の読み込みに失敗したときだけ0に戻す（自動の入れ替えに失敗しても、表示中の広告は残るので隠さない）
- 上下に10ptの余白を取り、タブバーや画面の内容と接しないようにする。広告がボタンなどに接していると、誤タップを誘う配置として AdMob のポリシー違反になりうるため
- SwiftUI にバナーの大きさを決めさせると広告がずれるため、入れ物の `UIView` の中央に広告の大きさで置く

## 全画面広告

`AdManager.showInterstitialIfAllowed(isPremium:)`

出すきっかけ（どちらも、画面が閉じ終わってから）：

| きっかけ | 条件 |
|---|---|
| チェックインを終えて閉じたとき | 今回1件以上答えたとき（途中でやめた・答えるものがなかったときは出さない） |
| サブスクを新しく登録して閉じたとき | オンボーディング中の登録と、編集では出さない |

表示中の広告は閉じるまで参照を持っておき（離すと閉じたときの通知が届かないことがある）、閉じたら次を読み込みます。

閉じるアニメーション中は表示が無視されるため、`AppRouter.requestInterstitialAfterDismissal()` で依頼しておき、`MainTabView` の `onDismiss` で出します。ほかに待っている画面（ペイウォールなど）があればそちらを優先し、広告は出しません。

回数のルール（`InterstitialAdPolicy`）：

- 使い始めて3日間は出さない
- 前回から2日たつまで出さない
- 直近30日で4回まで

出す前に `canPresent(from:)` で表示できるか確かめ、読み込んでから時間がたって表示できない広告は捨てて読み込み直します。出した日時は、実際に表示されたとき（`adWillPresentFullScreenContent`）だけ記録します（表示に失敗しても回数の枠を使わないように）。

アプリを初めて起動した日時と、出した日時は UserDefaults（`ads.firstLaunchDate`・`ads.interstitialShownDates`）に保存します。

## 公開前に必要なこと

1. ~~AdMob でアプリ（iOS）と広告ユニット（バナー・全画面）を作り、Release の `ADMOB_*` を差し替える~~（済み・2026年9月27日。下の「広告ユニット ID」）
2. App Store に載せる開発者のウェブサイト（マーケティング URL またはサポート URL のドメイン）の直下に `app-ads.txt` を置く。中身は [app-ads.txt](app-ads.txt) の1行をそのまま使う。置かないと広告の配信が制限される
3. ~~`SKAdNetworkItems` を最新の一覧にする~~（済み。Google の一覧が更新されたら差し替える。下の「広告の効果測定」）
4. App Store で公開した後、AdMob の「アプリ」で「ストアを追加」を押し、App Store のアプリと関連付ける。AdMob の審査（通常は数日）が終わるまで、広告の配信は制限される
5. App Store Connect：App のプライバシーの申告と、配信地域を日本のみにする（[app-store.md](app-store.md)）
6. AdMob の「ブロックのコントロール」で、アプリに合わない広告のカテゴリ（ギャンブル・出会いなど）を必要に応じて止める

## 広告ユニット ID

ID は Build Settings で設定し、`Config/SubscBook-Info.plist` から読みます（`AdUnitIDs`）。

| Build Setting | Info.plist のキー | Release（本番・AdMob で作成） | Debug（Google のテスト用） |
|---|---|---|---|
| `ADMOB_APP_ID` | `GADApplicationIdentifier` | `ca-app-pub-8826250114965581~4343691768` | `ca-app-pub-3940256099942544~1458002511` |
| `ADMOB_BANNER_UNIT_ID` | `SubscBookAdMobBannerUnitID` | `ca-app-pub-8826250114965581/1834087655`（サブスク帳 バナー） | `ca-app-pub-3940256099942544/2435281174` |
| `ADMOB_INTERSTITIAL_UNIT_ID` | `SubscBookAdMobInterstitialUnitID` | `ca-app-pub-8826250114965581/1669512685`（サブスク帳 全画面） | `ca-app-pub-3940256099942544/4411468910` |

Debug はテスト用の ID のままにします（自分で自分の本番の広告をタップすると、AdMob のアカウントが停止されることがあるため）。Release でテスト用の ID のままのときは、起動時にログにエラーを出します。本番の ID は秘密の情報ではありません（アプリの中に入り、誰でも見られる）。

TestFlight や App Store 版（Release）を自分で確かめるときは、AdMob の「設定 → テストデバイス」に自分の iPhone を登録して、本番の ID でもテスト広告が出るようにします。

`Config/SubscBook-Info.plist` は、自動生成の Info.plist に足す項目だけを書いたファイルです。`SubscBook/` の外に置いているのは、フォルダ同期でリソースとしてコピーされないようにするためです。

## トラッキングの許可

- ダイアログの説明文：「あなたの興味に合った広告を表示するために使います。登録したサブスクの情報は広告に使いません。」（`INFOPLIST_KEY_NSUserTrackingUsageDescription`）
- 許可されなくても広告は出ます（パーソナライズしない広告）
- 設定画面の「広告 → トラッキングの許可を変更」から、設定アプリのこのアプリの画面を開けます

## 広告の効果測定（SKAdNetwork）

`Config/SubscBook-Info.plist` の `SKAdNetworkItems` に、Google と、Google が選んだ他社の広告購入者の ID（50件）を入れています。出典は [Google のドキュメント](https://developers.google.com/admob/ios/3p-skadnetworks)（2026-02-10 更新版）です。ページが更新されたら差し替えてください。

## プライバシーマニフェスト

`SubscBook/Resources/PrivacyInfo.xcprivacy` で、アプリ自体について次を申告しています。

- トラッキング：しない（広告の SDK のトラッキングと収集するデータは、SDK に含まれるマニフェストで申告される）
- 集めるデータ：なし（登録したデータは端末の外に出ない）
- 理由の申告が必要な API：`UserDefaults`（CA92.1：このアプリだけが読み書きする値）

理由の申告が必要な API（ファイルの日時、起動からの時間、ディスクの空き容量など）を新しく使うときは、ここに追加してください。追加しないと、アップロードの時点で ITMS-91053 になります。

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
