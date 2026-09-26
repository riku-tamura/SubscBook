import SwiftUI

struct HomeUpcomingPaymentsCard: View {
    let subscriptions: [Subscription]
    @Environment(AppRouter.self) private var router

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                CardHeader(title: "次の支払い", systemImage: "calendar")
                Spacer()
                Button("すべて見る") {
                    router.selectedTab = .list
                }
                .font(.subheadline)
            }
            ForEach(subscriptions) { subscription in
                Button {
                    router.edit(subscription)
                } label: {
                    row(subscription)
                }
                .buttonStyle(.plain)
                if subscription.id != subscriptions.last?.id {
                    Divider()
                }
            }
        }
        .card()
    }

    private func row(_ subscription: Subscription) -> some View {
        HStack(spacing: 12) {
            CategoryIcon(name: subscription.name, category: subscription.category, size: 36)
            AdaptiveHStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(subscription.name)
                        .font(.body.weight(.medium))
                    Text("\(subscription.nextPaymentDate.monthDayWeekdayText)・\(subscription.nextPaymentDate.relativeDayText())")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            } trailing: {
                Text(subscription.price.yenText)
                    .font(.callout.monospacedDigit())
            }
        }
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
        .accessibilityHint("編集画面を開きます")
    }
}
