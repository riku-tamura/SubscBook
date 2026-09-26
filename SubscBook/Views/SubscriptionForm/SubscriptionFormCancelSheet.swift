import SwiftUI

/// 解約した日を選んで、解約済みとして記録する（先月解約したものを後から記録しても、節約累計が正しく出るように）
struct SubscriptionFormCancelSheet: View {
    let subscription: Subscription
    let onConfirm: (Date) -> Void
    @State private var canceledAt = Date.now
    @Environment(\.dismiss) private var dismiss

    /// 選べる範囲は登録日から今日まで（誤って何年も前を選ぶと、節約累計が大きくずれるため）。
    /// 端末の時計を戻した場合でも範囲が逆転しないようにする。
    private var selectableDates: ClosedRange<Date> {
        let now = Date.now
        return min(subscription.createdAt, now)...now
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("解約した日", selection: $canceledAt, in: selectableDates, displayedComponents: .date)
                } header: {
                    Text(subscription.name)
                } footer: {
                    Text("1年あたり\(subscription.annualCost.yenText)の節約として記録します。このアプリは記録のみを行うので、実際の解約手続きは各サービスで行ってください。")
                }
            }
            .navigationTitle("解約済みにする")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("記録する") {
                        onConfirm(canceledAt)
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
