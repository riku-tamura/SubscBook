import SwiftData
import SwiftUI

/// ③ サブスク一覧
struct SubscriptionListView: View {
    @Query private var subscriptions: [Subscription]
    @AppStorage("list.sortOrder") private var sortOrder: SubscriptionSortOrder = .paymentDate
    @State private var viewModel = SubscriptionListViewModel()
    @Environment(AppRouter.self) private var router
    @Environment(EntitlementManager.self) private var entitlements

    var body: some View {
        let sections = viewModel.sections(of: subscriptions, sortOrder: sortOrder)
        NavigationStack {
            content(sections)
                .navigationTitle("サブスク一覧")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        sortMenu
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button("追加", systemImage: "plus") {
                            router.requestNewSubscription(
                                activeCount: sections.active.count,
                                isPremium: entitlements.isPremium
                            )
                        }
                    }
                }
        }
    }

    @ViewBuilder
    private func content(_ sections: SubscriptionListSections) -> some View {
        if subscriptions.isEmpty {
            ContentUnavailableView {
                Label("サブスクがありません", systemImage: "tray")
            } description: {
                Text("契約中のサブスクを登録すると、支払日や合計金額を見張ります。")
            } actions: {
                Button("サブスクを登録") {
                    router.requestNewSubscription(activeCount: 0, isPremium: entitlements.isPremium)
                }
                .buttonStyle(.borderedProminent)
            }
        } else {
            List {
                Section {
                    if sections.active.isEmpty {
                        Text("有効なサブスクはありません")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(sections.active) { subscription in
                        row(subscription)
                    }
                } header: {
                    Text("契約中（\(sections.active.count)件）")
                } footer: {
                    if !entitlements.isPremium {
                        Text(viewModel.freePlanMessage(activeCount: sections.active.count))
                    }
                }

                if !sections.canceled.isEmpty {
                    Section {
                        if viewModel.isCanceledExpanded {
                            ForEach(sections.canceled) { subscription in
                                row(subscription)
                            }
                        }
                    } header: {
                        canceledHeader(count: sections.canceled.count)
                    }
                }
            }
        }
    }

    private func row(_ subscription: Subscription) -> some View {
        Button {
            router.edit(subscription)
        } label: {
            SubscriptionListRow(subscription: subscription)
        }
        .tint(.primary)
        .accessibilityHint("編集画面を開きます")
    }

    private var sortMenu: some View {
        Menu {
            Picker("並び替え", selection: $sortOrder) {
                ForEach(SubscriptionSortOrder.allCases) { order in
                    Text(order.title).tag(order)
                }
            }
        } label: {
            Label("並び替え：\(sortOrder.title)", systemImage: "arrow.up.arrow.down")
        }
    }

    private func canceledHeader(count: Int) -> some View {
        Button {
            withAnimation {
                viewModel.toggleCanceledSection()
            }
        } label: {
            HStack {
                Text("解約済み（\(count)件）")
                Spacer()
                Image(systemName: "chevron.right")
                    .rotationEffect(.degrees(viewModel.isCanceledExpanded ? 90 : 0))
                    .accessibilityHidden(true)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityValue(viewModel.isCanceledExpanded ? "展開" : "折りたたみ")
        .accessibilityHint(viewModel.isCanceledExpanded ? "解約済みのサブスクを隠します" : "解約済みのサブスクを表示します")
    }
}
