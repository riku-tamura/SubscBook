import Foundation
import Testing
@testable import SubscBook

@Suite("重複の検出（5.4）")
struct DuplicateDetectorTests {
    @Test("同一カテゴリの有効なサブスクが2件以上あれば重複")
    func detectsDuplicates() throws {
        let store = try TestStore()
        let subscriptions = [
            store.addSubscription(name: "動画A", category: .video, price: 990),
            store.addSubscription(name: "動画B", category: .video, price: 1490),
            store.addSubscription(name: "音楽A", category: .music, price: 980),
        ]

        let groups = DuplicateDetector.duplicateGroups(in: subscriptions)

        #expect(groups.map(\.category) == [.video])
        #expect(groups.first?.subscriptions.map(\.name) == ["動画B", "動画A"])
        #expect(groups.first?.monthlyTotal == 2480)
    }

    @Test("「その他」は重複として扱わない")
    func excludesOther() throws {
        let store = try TestStore()
        let subscriptions = (1...3).map { store.addSubscription(name: "その他\($0)", category: .other) }

        #expect(DuplicateDetector.duplicateGroups(in: subscriptions).isEmpty)
    }

    @Test("解約済みは件数に含めない")
    func excludesCanceled() throws {
        let store = try TestStore()
        let subscriptions = [
            store.addSubscription(category: .video),
            store.addSubscription(category: .video, status: .canceled, canceledAt: .now),
        ]

        #expect(DuplicateDetector.duplicateGroups(in: subscriptions).isEmpty)
    }

    @Test("複数カテゴリはカテゴリの定義順に並べる")
    func orderedByCategory() throws {
        let store = try TestStore()
        let subscriptions = [
            store.addSubscription(category: .cloud),
            store.addSubscription(category: .music),
            store.addSubscription(category: .cloud),
            store.addSubscription(category: .video),
            store.addSubscription(category: .music),
            store.addSubscription(category: .video),
        ]

        #expect(DuplicateDetector.duplicateGroups(in: subscriptions).map(\.category) == [.video, .music, .cloud])
    }
}
