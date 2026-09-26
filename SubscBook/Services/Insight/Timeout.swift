import Foundation
import Synchronization

enum TimeoutError: Error {
    case timedOut
}

/// `operation` が `duration` 以内に終わらなければ打ち切ってエラーにする。
/// 生成がキャンセルに素早く応じない場合でも、呼び出し側を待たせない。
nonisolated func withTimeout<T: Sendable>(
    _ duration: Duration,
    operation: @escaping @Sendable () async throws -> T
) async throws -> T {
    let gate = ResumeGate()
    return try await withCheckedThrowingContinuation { continuation in
        let work = Task {
            do {
                let value = try await operation()
                if gate.open() { continuation.resume(returning: value) }
            } catch {
                if gate.open() { continuation.resume(throwing: error) }
            }
        }
        Task {
            try? await Task.sleep(for: duration)
            if gate.open() {
                work.cancel()
                continuation.resume(throwing: TimeoutError.timedOut)
            }
        }
    }
}

/// continuation を一度だけ resume するための門
nonisolated private final class ResumeGate: Sendable {
    private let isOpened = Mutex(false)

    /// 最初の呼び出しだけ true を返す
    func open() -> Bool {
        isOpened.withLock { opened in
            if opened { return false }
            opened = true
            return true
        }
    }
}
