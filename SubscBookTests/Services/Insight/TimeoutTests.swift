import Foundation
import Testing
@testable import SubscBook

@Suite("タイムアウト")
struct TimeoutTests {
    @Test("時間内に終われば結果を返す")
    func returnsValue() async throws {
        let value = try await withTimeout(.seconds(1)) { "ok" }
        #expect(value == "ok")
    }

    @Test("時間を超えたら待たずにエラーにする")
    func timesOut() async {
        let start = ContinuousClock.now
        await #expect(throws: TimeoutError.self) {
            try await withTimeout(.milliseconds(100)) {
                // キャンセルに応じない処理でも打ち切れること
                let deadline = ContinuousClock.now + .seconds(3)
                while ContinuousClock.now < deadline {}
                return "late"
            }
        }
        #expect(ContinuousClock.now - start < .seconds(2))
    }
}
