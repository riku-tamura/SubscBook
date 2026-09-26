import SwiftUI

/// AI のひとことコメントのカード（ホーム・レポート共通）
struct InsightCard: View {
    var title = "今月のひとこと"
    let comment: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            CardHeader(title: title, systemImage: "sparkles", tint: .orange)
            if let comment {
                Text(comment)
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
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
