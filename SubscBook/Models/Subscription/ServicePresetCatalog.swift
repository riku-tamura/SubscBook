import Foundation

/// 主要サービスの候補の一覧と検索
nonisolated enum ServicePresetCatalog {
    static let all: [ServicePreset] = [
        // 動画
        .init(name: "Netflix", category: .video, reading: "ネットフリックス"),
        .init(name: "Amazonプライム", category: .video, reading: "アマゾンプライム"),
        .init(name: "Disney+", category: .video, reading: "ディズニープラス"),
        .init(name: "U-NEXT", category: .video, reading: "ユーネクスト"),
        .init(name: "Hulu", category: .video, reading: "フールー"),
        .init(name: "DAZN", category: .video, reading: "ダゾーン"),
        .init(name: "ABEMAプレミアム", category: .video, reading: "アベマプレミアム"),
        .init(name: "YouTube Premium", category: .video, reading: "ユーチューブプレミアム"),
        .init(name: "Apple TV+", category: .video, reading: "アップルティーヴィープラス"),
        .init(name: "dアニメストア", category: .video, reading: "ディーアニメストア"),
        .init(name: "Lemino", category: .video, reading: "レミノ"),
        .init(name: "FODプレミアム", category: .video, reading: "エフオーディープレミアム"),
        .init(name: "TELASA", category: .video, reading: "テラサ"),
        .init(name: "DMM TV", category: .video, reading: "ディーエムエムティーヴィー"),
        .init(name: "WOWOWオンデマンド", category: .video, reading: "ワウワウオンデマンド"),
        .init(name: "ニコニコプレミアム", category: .video, reading: "ニコニコプレミアム"),
        // 音楽
        .init(name: "Spotify", category: .music, reading: "スポティファイ"),
        .init(name: "Apple Music", category: .music, reading: "アップルミュージック"),
        .init(name: "Amazon Music Unlimited", category: .music, reading: "アマゾンミュージックアンリミテッド"),
        .init(name: "YouTube Music Premium", category: .music, reading: "ユーチューブミュージックプレミアム"),
        .init(name: "LINE MUSIC", category: .music, reading: "ラインミュージック"),
        .init(name: "AWA", category: .music, reading: "アワ"),
        .init(name: "楽天ミュージック", category: .music, reading: "ラクテンミュージック"),
        // 読書・雑誌
        .init(name: "Kindle Unlimited", category: .reading, reading: "キンドルアンリミテッド"),
        .init(name: "Audible", category: .reading, reading: "オーディブル"),
        .init(name: "楽天マガジン", category: .reading, reading: "ラクテンマガジン"),
        .init(name: "dマガジン", category: .reading, reading: "ディーマガジン"),
        .init(name: "コミックシーモア読み放題", category: .reading, reading: "コミックシーモアヨミホウダイ"),
        .init(name: "ブック放題", category: .reading, reading: "ブックホウダイ"),
        .init(name: "audiobook.jp", category: .reading, reading: "オーディオブック"),
        // ゲーム
        .init(name: "Nintendo Switch Online", category: .game, reading: "ニンテンドースイッチオンライン"),
        .init(name: "PlayStation Plus", category: .game, reading: "プレイステーションプラス"),
        .init(name: "Xbox Game Pass", category: .game, reading: "エックスボックスゲームパス"),
        .init(name: "Apple Arcade", category: .game, reading: "アップルアーケード"),
        // クラウド・ストレージ
        .init(name: "iCloud+", category: .cloud, reading: "アイクラウドプラス"),
        .init(name: "Google One", category: .cloud, reading: "グーグルワン"),
        .init(name: "Dropbox", category: .cloud, reading: "ドロップボックス"),
        // 仕事・ツール
        .init(name: "Microsoft 365", category: .work, reading: "マイクロソフトサンロクゴ"),
        .init(name: "Adobe Creative Cloud", category: .work, reading: "アドビクリエイティブクラウド"),
        .init(name: "ChatGPT Plus", category: .work, reading: "チャットジーピーティープラス"),
        .init(name: "Claude Pro", category: .work, reading: "クロードプロ"),
        .init(name: "Google AI Pro", category: .work, reading: "グーグルエーアイプロ"),
        .init(name: "Notion", category: .work, reading: "ノーション"),
        .init(name: "Canva Pro", category: .work, reading: "キャンバプロ"),
        .init(name: "Evernote", category: .work, reading: "エバーノート"),
        .init(name: "Zoom", category: .work, reading: "ズーム"),
        .init(name: "1Password", category: .work, reading: "ワンパスワード"),
        .init(name: "GitHub Copilot", category: .work, reading: "ギットハブコパイロット"),
        // フィットネス
        .init(name: "Apple Fitness+", category: .fitness, reading: "アップルフィットネスプラス"),
        .init(name: "Fitbit Premium", category: .fitness, reading: "フィットビットプレミアム"),
        .init(name: "あすけん", category: .fitness, reading: "アスケン"),
        .init(name: "Strava", category: .fitness, reading: "ストラバ"),
        .init(name: "LEAN BODY", category: .fitness, reading: "リーンボディ"),
        // 学習
        .init(name: "Duolingo Super", category: .learning, reading: "デュオリンゴスーパー"),
        .init(name: "スタディサプリ", category: .learning, reading: "スタディサプリ"),
        .init(name: "Schoo", category: .learning, reading: "スクー"),
        .init(name: "Coursera Plus", category: .learning, reading: "コーセラプラス"),
        .init(name: "レアジョブ英会話", category: .learning, reading: "レアジョブエイカイワ"),
        .init(name: "ネイティブキャンプ", category: .learning, reading: "ネイティブキャンプ"),
        // ニュース
        .init(name: "日経電子版", category: .news, reading: "ニッケイデンシバン"),
        .init(name: "朝日新聞デジタル", category: .news, reading: "アサヒシンブンデジタル"),
        .init(name: "読売新聞オンライン", category: .news, reading: "ヨミウリシンブンオンライン"),
        .init(name: "毎日新聞デジタル", category: .news, reading: "マイニチシンブンデジタル"),
        .init(name: "NewsPicks", category: .news, reading: "ニューズピックス"),
        // その他
        .init(name: "LINEスタンプ プレミアム", category: .other, reading: "ラインスタンププレミアム"),
        .init(name: "Uber One", category: .other, reading: "ウーバーワン"),
    ]

    /// 入力中のサービス名に合う候補。前方一致を優先し、最大 `limit` 件。入力と完全一致する候補は除く。
    static func suggestions(for query: String, limit: Int = 5) -> [ServicePreset] {
        let normalizedQuery = normalize(query)
        guard !normalizedQuery.isEmpty else { return [] }

        var prefixMatches: [ServicePreset] = []
        var containsMatches: [ServicePreset] = []
        for preset in all {
            let name = normalize(preset.name)
            let reading = normalize(preset.reading)
            if name == normalizedQuery { continue }
            if name.hasPrefix(normalizedQuery) || reading.hasPrefix(normalizedQuery) {
                prefixMatches.append(preset)
            } else if name.contains(normalizedQuery) || reading.contains(normalizedQuery) {
                containsMatches.append(preset)
            }
        }
        return Array((prefixMatches + containsMatches).prefix(limit))
    }

    /// 名前と完全一致するプリセット（表記ゆれは吸収する）
    static func preset(named name: String) -> ServicePreset? {
        let normalizedName = normalize(name)
        guard !normalizedName.isEmpty else { return nil }
        return all.first { normalize($0.name) == normalizedName }
    }

    /// 大文字小文字・全角半角・ひらがなカタカナ・空白の違いを吸収する
    static func normalize(_ text: String) -> String {
        let folded = text.folding(
            options: [.caseInsensitive, .widthInsensitive],
            locale: Locale(identifier: "ja_JP")
        )
        let katakana = folded.applyingTransform(.hiraganaToKatakana, reverse: false) ?? folded
        return katakana.filter { !$0.isWhitespace }
    }
}
