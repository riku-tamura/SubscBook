import Foundation
import Testing
@testable import SubscBook

@Suite("月次チェックインの進行")
struct CheckInViewModelTests {
    private let now = date(2026, 9, 26)

    @Test("前月分が未回答の対象サブスクを名前順に聞く")
    func queue() throws {
        let store = try TestStore()
        let answered = store.addSubscription(name: "回答済み")
        answered.recordCheckIn(for: YearMonth("2026-08")!, used: true)
        let subscriptions = [
            store.addSubscription(name: "Spotify"),
            answered,
            store.addSubscription(name: "Netflix"),
            store.addSubscription(name: "新規", createdAt: date(2026, 9, 20)),
        ]

        let viewModel = CheckInViewModel(subscriptions: subscriptions, now: now, calendar: .tokyo)

        #expect(viewModel.month.key == "2026-08")
        #expect(viewModel.queue.map(\.name) == ["Netflix", "Spotify"])
        #expect(viewModel.current?.name == "Netflix")
        #expect(viewModel.progressText == "1 / 2")
    }

    @Test("回答すると記録して次へ進み、全件で完了する")
    func answer() throws {
        let store = try TestStore()
        let first = store.addSubscription(name: "A")
        let second = store.addSubscription(name: "B")
        let viewModel = CheckInViewModel(subscriptions: [first, second], now: now, calendar: .tokyo)

        viewModel.answer(used: false, for: first, in: store.context, now: now)
        #expect(first.checkIn(for: YearMonth("2026-08")!)?.used == false)
        #expect(viewModel.current?.name == "B")
        #expect(viewModel.progress == 0.5)

        viewModel.answer(used: true, for: second, in: store.context, now: now)
        #expect(second.checkIn(for: YearMonth("2026-08")!)?.used == true)
        #expect(viewModel.isFinished)
        #expect(viewModel.progress == 1)
    }

    @Test("ひとつ戻って回答し直すと上書きする")
    func goBack() throws {
        let store = try TestStore()
        let subscription = store.addSubscription(name: "A")
        let viewModel = CheckInViewModel(subscriptions: [subscription, store.addSubscription(name: "B")], now: now, calendar: .tokyo)

        viewModel.answer(used: false, for: subscription, in: store.context, now: now)
        #expect(viewModel.canGoBack)
        viewModel.goBack()
        #expect(viewModel.current?.name == "A")
        viewModel.answer(used: true, for: subscription, in: store.context, now: now)

        #expect(subscription.checkIns.count == 1)
        #expect(subscription.checkIn(for: YearMonth("2026-08")!)?.used == true)
    }

    @Test("表示中でないサブスクへの回答は無視する（スワイプ中にボタンを押した場合など）")
    func ignoresStaleAnswer() throws {
        let store = try TestStore()
        let first = store.addSubscription(name: "A")
        let second = store.addSubscription(name: "B")
        let viewModel = CheckInViewModel(subscriptions: [first, second], now: now, calendar: .tokyo)

        viewModel.answer(used: true, for: first, in: store.context, now: now)
        // A への遅れて届いた回答
        viewModel.answer(used: false, for: first, in: store.context, now: now)

        #expect(viewModel.current?.name == "B")
        #expect(second.checkIns.isEmpty)
        #expect(first.checkIn(for: YearMonth("2026-08")!)?.used == true)
    }

    @Test("未回答がなければすぐ完了")
    func empty() {
        let viewModel = CheckInViewModel(subscriptions: [], now: now, calendar: .tokyo)
        #expect(viewModel.isFinished)
        #expect(viewModel.progress == 1)
        #expect(!viewModel.canGoBack)
        #expect(viewModel.emptyReason == .noSubscriptions)
    }

    @Test("聞くサブスクがない理由：登録から1ヶ月たっていない・回答済み")
    func emptyReasons() throws {
        let store = try TestStore()
        let newSubscription = store.addSubscription(name: "新規", createdAt: date(2026, 9, 20))
        #expect(CheckInViewModel(subscriptions: [newSubscription], now: now, calendar: .tokyo).emptyReason == .notYetEligible)

        let answered = store.addSubscription(name: "回答済み")
        answered.recordCheckIn(for: YearMonth("2026-08")!, used: true)
        #expect(CheckInViewModel(subscriptions: [newSubscription, answered], now: now, calendar: .tokyo).emptyReason == .allAnswered)

        let pending = store.addSubscription(name: "未回答")
        #expect(CheckInViewModel(subscriptions: [pending], now: now, calendar: .tokyo).emptyReason == nil)
    }
}
