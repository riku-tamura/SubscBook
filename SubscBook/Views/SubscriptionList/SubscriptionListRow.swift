import SwiftUI

/// 一覧の1行：頭文字アイコン、名前、金額と周期、次回支払日
struct SubscriptionListRow: View {
    let subscription: Subscription

    var body: some View {
        HStack(spacing: 12) {
            CategoryIcon(name: subscription.name, category: subscription.category)
            AdaptiveHStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(subscription.name)
                        .font(.body.weight(.medium))
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            } trailing: {
                Text(subscription.priceText)
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(subscription.isActive ? .primary : .secondary)
                    .strikethrough(!subscription.isActive)
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private var subtitle: String {
        if subscription.isActive {
            "次回 \(subscription.nextPaymentDate.monthDayWeekdayText)"
        } else if let canceledAt = subscription.canceledAt {
            "\(canceledAt.fullDateText)に解約"
        } else {
            "解約済み"
        }
    }

    private var accessibilityText: String {
        [
            subscription.name,
            subscription.category.displayName,
            subscription.priceAccessibilityText,
            subtitle,
        ].joined(separator: "、")
    }
}
