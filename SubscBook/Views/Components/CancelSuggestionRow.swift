import SwiftUI

/// 解約候補の1件。ホームとレポートで使う。
struct CancelSuggestionRow: View {
    let suggestion: CancelSuggestion
    let reason: String?

    var body: some View {
        IconLabelStack(alignment: .top) {
            CategoryIcon(name: suggestion.subscription.name, category: suggestion.subscription.category, size: 36)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                AdaptiveHStack {
                    Text(suggestion.subscription.name)
                        .font(.body.weight(.medium))
                } trailing: {
                    Text("1年あたり\(suggestion.annualCost.yenText)")
                        .font(.subheadline.weight(.semibold))
                        .monospacedDigit()
                }
                Text("チェックインで\(suggestion.unusedMonths)ヶ月続けて「使っていない」")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                if let reason {
                    Text(reason)
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text(TemplateInsightService.cancelReasonDefault)
                        .font(.subheadline)
                        .redacted(reason: .placeholder)
                }
            }
        }
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
        .accessibilityHint("編集画面を開きます")
    }
}
