import SwiftUI

/// プライバシーポリシー（アプリ内表示）
struct PrivacyPolicyView: View {
    private let sections: [(title: String, body: String)] = [
        (
            "収集する情報",
            "サブスク見張り番（以下「本アプリ」）は、個人情報や利用状況を収集しません。登録したサブスクの情報やチェックインの回答は、すべてお使いの端末の中だけに保存され、開発者を含む外部に送信されることはありません。"
        ),
        (
            "AIコメント",
            "AIコメントは、Apple Intelligence の端末内モデルで作成します。作成に使う情報が端末の外に送信されることはありません。Apple Intelligence を利用できない端末では、あらかじめ用意した文章を表示します。"
        ),
        (
            "通知",
            "支払日などのお知らせは、端末の中で作成するローカル通知です。通知のために情報を外部へ送信することはありません。"
        ),
        (
            "お支払い",
            "見張り番プラスの購入は、Apple の App Store を通じて処理されます。開発者がクレジットカードなどのお支払い情報を受け取ることはありません。"
        ),
        (
            "広告・解析ツール",
            "本アプリは、広告や利用状況の解析ツールを使用していません。"
        ),
        (
            "データの削除",
            "設定画面の「データの全削除」、または本アプリの削除によって、端末に保存されたデータを消去できます。"
        ),
        (
            "改定",
            "本ポリシーを改定する場合は、アプリのアップデートでお知らせします。"
        ),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("本アプリは「お金のデータを端末の外に出さない」ことを大切にしています。")
                    .font(.subheadline)
                ForEach(sections, id: \.title) { section in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(section.title)
                            .font(.headline)
                            .accessibilityAddTraits(.isHeader)
                        Text(section.body)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                Text("制定日：2026年9月26日")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("プライバシーポリシー")
        .navigationBarTitleDisplayMode(.inline)
    }
}
