import SwiftUI

/// 月次のひとことのカード（ホーム・レポート共通）。AI で作れたときだけ「Apple Intelligence で作成」と示す。
struct InsightCard: View {
    var title = "今月のひとこと"
    let comment: String?
    /// Apple Intelligence で作ったコメントか（false は定型のコメント）
    var isGenerated = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            CardHeader(title: title, systemImage: "text.bubble.fill", tint: .orange)
            if let comment {
                Text(comment)
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
                if isGenerated {
                    Label("Apple Intelligence で作成", systemImage: "sparkles")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text(TemplateInsightService.monthlyDefault)
                    .redacted(reason: .placeholder)
                    .accessibilityLabel("コメントを準備しています")
            }
        }
        .card()
        .accessibilityElement(children: .combine)
    }
}
