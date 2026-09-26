import Foundation
import SwiftData
import Testing
@testable import SubWatch

@Suite("登録・編集フォーム")
struct SubscriptionFormViewModelTests {
    private let now = date(2026, 9, 26, 10)

    @Test("金額は数字だけを受け付け、全角数字は半角にする", arguments: [
        ("1490", "1490"),
        ("1,490", "1490"),
        ("１４９０", "1490"),
        ("0980", "980"),
        ("000", "0"),
        ("abc", ""),
        ("123456789", "1234567"),
    ])
    func priceText(input: String, expected: String) {
        let viewModel = SubscriptionFormViewModel(mode: .add, now: now, calendar: .tokyo)
        viewModel.updatePriceText(input)
        #expect(viewModel.priceText == expected)
    }

    @Test("名前と1円以上の金額があれば保存できる")
    func canSave() {
        let viewModel = SubscriptionFormViewModel(mode: .add, now: now, calendar: .tokyo)
        #expect(!viewModel.canSave)

        viewModel.name = "  "
        viewModel.updatePriceText("980")
        #expect(!viewModel.canSave)

        viewModel.name = "Spotify"
        #expect(viewModel.canSave)

        viewModel.updatePriceText("0")
        #expect(!viewModel.canSave)
    }

    @Test("プリセットと一致する名前を入れるとカテゴリを自動で設定する")
    func appliesPresetCategory() {
        let viewModel = SubscriptionFormViewModel(mode: .add, now: now, calendar: .tokyo)
        viewModel.name = "spotify"
        #expect(viewModel.category == .music)
    }

    @Test("カテゴリを自分で選んだ後は自動設定しない")
    func respectsUserCategory() {
        let viewModel = SubscriptionFormViewModel(mode: .add, now: now, calendar: .tokyo)
        viewModel.selectCategory(.work)
        viewModel.name = "Spotify"
        #expect(viewModel.category == .work)
    }

    @Test("候補を選ぶと名前とカテゴリが入る")
    func applySuggestion() throws {
        let viewModel = SubscriptionFormViewModel(mode: .add, now: now, calendar: .tokyo)
        let preset = try #require(ServicePresetCatalog.preset(named: "iCloud+"))
        viewModel.applySuggestion(preset)
        #expect(viewModel.name == "iCloud+")
        #expect(viewModel.category == .cloud)
    }

    @Test("新規登録：名前の前後の空白を除き、登録日を記録する")
    func saveNew() throws {
        let store = try TestStore()
        let viewModel = SubscriptionFormViewModel(mode: .add, now: now, calendar: .tokyo)
        viewModel.name = "  Netflix "
        viewModel.updatePriceText("1590")
        viewModel.nextPaymentDate = date(2026, 10, 31)
        viewModel.hasTrial = true
        viewModel.trialEndDate = date(2026, 10, 3, 15)

        let subscription = try viewModel.save(in: store.context, now: now, calendar: .tokyo)

        #expect(subscription.name == "Netflix")
        #expect(subscription.category == .video)
        #expect(subscription.price == 1590)
        #expect(subscription.nextPaymentDate == date(2026, 10, 31))
        #expect(subscription.billingDay == 31)
        #expect(subscription.trialEndDate == date(2026, 10, 3))
        #expect(subscription.createdAt == now)
        #expect(try store.context.fetchCount(FetchDescriptor<Subscription>()) == 1)
    }

    @Test("過去の支払日は今日以降に進めて保存する（基準日は保持）")
    func savePastDate() throws {
        let store = try TestStore()
        let viewModel = SubscriptionFormViewModel(mode: .add, now: now, calendar: .tokyo)
        viewModel.name = "Spotify"
        viewModel.updatePriceText("980")
        viewModel.nextPaymentDate = date(2026, 7, 31)

        let subscription = try viewModel.save(in: store.context, now: now, calendar: .tokyo)

        // 7/31 → 8/31 → 9/30（9/26 以降で最初の支払日）
        #expect(subscription.nextPaymentDate == date(2026, 9, 30))
        #expect(subscription.billingDay == 31)
    }

    @Test("編集：値を更新し、トライアルをオフにすると終了日を消す")
    func saveEdit() throws {
        let store = try TestStore()
        let subscription = store.addSubscription(name: "Hulu", price: 1026, nextPaymentDate: date(2026, 10, 15))
        subscription.setTrialEndDate(date(2026, 10, 1), calendar: .tokyo)

        let viewModel = SubscriptionFormViewModel(mode: .edit(subscription), now: now, calendar: .tokyo)
        #expect(viewModel.hasTrial)
        #expect(viewModel.priceText == "1026")
        viewModel.name = "Hulu 年額"
        viewModel.updatePriceText("10260")
        viewModel.cycle = .yearly
        viewModel.hasTrial = false
        try viewModel.save(in: store.context, now: now, calendar: .tokyo)

        #expect(subscription.name == "Hulu 年額")
        #expect(subscription.price == 10260)
        #expect(subscription.cycle == .yearly)
        #expect(subscription.trialEndDate == nil)
        #expect(subscription.nextPaymentDate == date(2026, 10, 15))
        #expect(try store.context.fetchCount(FetchDescriptor<Subscription>()) == 1)
    }

    @Test("編集で支払日を変えなければ基準日を保持する")
    func editKeepsBillingDay() throws {
        let store = try TestStore()
        // 1/31 払いが 2/28 に進んだ状態
        let subscription = store.addSubscription(nextPaymentDate: date(2027, 1, 31))
        subscription.nextPaymentDate = date(2027, 2, 28)

        let viewModel = SubscriptionFormViewModel(mode: .edit(subscription), now: date(2027, 2, 1), calendar: .tokyo)
        viewModel.updatePriceText("1200")
        try viewModel.save(in: store.context, now: date(2027, 2, 1), calendar: .tokyo)

        #expect(subscription.billingDay == 31)
        #expect(subscription.nextPaymentDate == date(2027, 2, 28))
    }

    @Test("入力が不正なら保存しない")
    func invalidInputThrows() throws {
        let store = try TestStore()
        let viewModel = SubscriptionFormViewModel(mode: .add, now: now, calendar: .tokyo)
        #expect(throws: SubscriptionFormViewModel.FormError.self) {
            try viewModel.save(in: store.context, now: now, calendar: .tokyo)
        }
    }
}
