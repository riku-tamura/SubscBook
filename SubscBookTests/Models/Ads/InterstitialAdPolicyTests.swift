import Foundation
import Testing
@testable import SubscBook

@Suite("全画面広告を出すルール")
struct InterstitialAdPolicyTests {
    private let installed = date(2026, 9, 1, 9)

    @Test("使い始めて3日間は出さない")
    func gracePeriod() {
        #expect(!InterstitialAdPolicy.canShow(now: date(2026, 9, 4, 8), firstLaunchDate: installed, shownDates: []))
        #expect(InterstitialAdPolicy.canShow(now: date(2026, 9, 4, 9), firstLaunchDate: installed, shownDates: []))
    }

    @Test("前回から2日たつまでは出さない")
    func minimumInterval() {
        let shown = [date(2026, 9, 10, 12)]
        #expect(!InterstitialAdPolicy.canShow(now: date(2026, 9, 12, 11), firstLaunchDate: installed, shownDates: shown))
        #expect(InterstitialAdPolicy.canShow(now: date(2026, 9, 12, 12), firstLaunchDate: installed, shownDates: shown))
    }

    @Test("30日間に4回まで")
    func maxPerWindow() {
        let shown = [date(2026, 9, 5), date(2026, 9, 8), date(2026, 9, 11), date(2026, 9, 14)]
        #expect(!InterstitialAdPolicy.canShow(now: date(2026, 9, 20), firstLaunchDate: installed, shownDates: shown))
        // 最初の1回から30日たてば、また出せる
        #expect(InterstitialAdPolicy.canShow(now: date(2026, 10, 5), firstLaunchDate: installed, shownDates: shown))
    }

    @Test("30日より前の記録は捨てる")
    func datesToKeep() {
        let shown = [date(2026, 8, 1), date(2026, 9, 20)]
        #expect(InterstitialAdPolicy.datesToKeep(shown, now: date(2026, 9, 26)) == [date(2026, 9, 20)])
    }
}
