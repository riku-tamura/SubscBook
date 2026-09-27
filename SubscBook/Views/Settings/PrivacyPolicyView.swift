import SwiftUI

/// プライバシーポリシー（アプリ内表示）
struct PrivacyPolicyView: View {
    private let sections: [(title: String, body: String)] = [
        (
            "収集する情報",
            "サブスク帳（以下「本アプリ」）の開発者は、個人情報や利用状況を収集しません。登録したサブスクの情報やチェックインの回答は、すべてお使いの端末の中だけに保存され、開発者や広告事業者を含む外部に送信されることはありません。"
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
            "サブスク帳プラスの購入は、Apple の App Store を通じて処理されます。開発者がクレジットカードなどのお支払い情報を受け取ることはありません。"
        ),
        (
            "広告",
            "本アプリは、無料でお使いの方に Google の広告サービス（Google AdMob）で広告を表示します。広告の表示と効果測定のために、Google は端末の広告識別子（トラッキングを許可した場合のみ）、IP アドレス、おおよその位置、広告の表示やタップの記録などを収集することがあります。登録したサブスクの情報やチェックインの回答が広告に使われることはありません。トラッキングの許可は、設定アプリの「プライバシーとセキュリティ」→「トラッキング」からいつでも変更できます。Google による情報の扱いは、Google のプライバシーポリシー（policies.google.com/technologies/ads）をご覧ください。サブスク帳プラスでは広告を表示しません。"
        ),
        (
            "解析ツール",
            "本アプリは、利用状況の解析ツールを使用していません。"
        ),
        (
            "データの削除",
            "設定画面の「データの全削除」、または本アプリの削除によって、端末に保存されたデータを消去できます。"
        ),
        (
            "改定",
            "本ポリシーを改定する場合は、アプリのアップデートでお知らせします。"
        ),
        (
            "お問い合わせ",
            "本アプリや本ポリシーについてのお問い合わせは、App Store の本アプリのページにある「App サポート」からお願いします。"
        ),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("本アプリは「登録したお金のデータを端末の外に出さない」ことを大切にしています。")
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
                Text("制定日：2026年9月26日　改定日：2026年9月27日")
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
