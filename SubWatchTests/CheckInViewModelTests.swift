import Foundation
import Testing
@testable import SubWatch

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

        viewModel.answer(used: false, in: store.context, now: now)
        #expect(first.checkIn(for: YearMonth("2026-08")!)?.used == false)
        #expect(viewModel.current?.name == "B")
        #expect(viewModel.progress == 0.5)

        viewModel.answer(used: true, in: store.context, now: now)
        #expect(second.checkIn(for: YearMonth("2026-08")!)?.used == true)
        #expect(viewModel.isFinished)
        #expect(viewModel.progress == 1)
    }

    @Test("ひとつ戻って回答し直すと上書きする")
    func goBack() throws {
        let store = try TestStore()
        let subscription = store.addSubscription(name: "A")
        let viewModel = CheckInViewModel(subscriptions: [subscription, store.addSubscription(name: "B")], now: now, calendar: .tokyo)

        viewModel.answer(used: false, in: store.context, now: now)
        #expect(viewModel.canGoBack)
        viewModel.goBack()
        #expect(viewModel.current?.name == "A")
        viewModel.answer(used: true, in: store.context, now: now)

        #expect(subscription.checkIns.count == 1)
        #expect(subscription.checkIn(for: YearMonth("2026-08")!)?.used == true)
    }

    @Test("未回答がなければすぐ完了")
    func empty() {
        let viewModel = CheckInViewModel(subscriptions: [], now: now, calendar: .tokyo)
        #expect(viewModel.isFinished)
        #expect(viewModel.progress == 1)
        #expect(!viewModel.canGoBack)
    }

    @Test("通知をタップしたときの遷移")
    func openNotification() {
        let router = AppRouter()
        router.paywall = .settings
        router.openNotification(.checkIn)
        #expect(router.selectedTab == .home)
        #expect(router.isCheckInPresented)
        #expect(router.paywall == nil)

        let other = AppRouter()
        other.openNotification(.payment)
        #expect(other.selectedTab == .list)
        #expect(!other.isCheckInPresented)
    }
}
