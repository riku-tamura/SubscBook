import SwiftUI

/// 同じカテゴリで重複しているサブスク（サブスク帳プラス）
struct ReportDuplicatesCard: View {
    let groups: [DuplicateGroup]
    @Environment(EntitlementManager.self) private var entitlements

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CardHeader(title: "重複しているサブスク", systemImage: "square.on.square", tint: .purple)
            Group {
                if groups.isEmpty {
                    Text("同じジャンルで重なっているサブスクはありません。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(groups) { group in
                            groupRow(group)
                        }
                        Text("同じジャンルのサービスは、ひとつにまとめられないか見直してみませんか？")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .premiumLocked(!entitlements.isPremium, feature: .duplicateDetection)
        }
        .card()
    }

    private func groupRow(_ group: DuplicateGroup) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label {
                    Text("\(group.category.displayName)（\(group.subscriptions.count)件）")
                        .font(.subheadline.weight(.semibold))
                } icon: {
                    Image(systemName: group.category.symbolName)
                        .foregroundStyle(group.category.color)
                }
                Spacer()
                Text("月\(group.monthlyTotal.yenText)")
                    .font(.subheadline.monospacedDigit())
            }
            ForEach(group.subscriptions) { subscription in
                HStack(spacing: 8) {
                    CategoryIcon(name: subscription.name, category: subscription.category, size: 24)
                    Text(subscription.name)
                        .font(.subheadline)
                    Spacer()
                    Text(subscription.priceText)
                        .font(.footnote.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }
}
