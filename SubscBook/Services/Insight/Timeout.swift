import Foundation
import Synchronization

/// `withTimeout` の時間切れ
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
    let timer = TimerHolder()
    return try await withCheckedThrowingContinuation { continuation in
        let work = Task {
            do {
                let value = try await operation()
                if gate.open() { continuation.resume(returning: value) }
            } catch {
                if gate.open() { continuation.resume(throwing: error) }
            }
            // 先に終わったら、時間切れを見張るタスクを止める（5秒間眠ったまま残さない）
            timer.cancel()
        }
        timer.set(Task {
            try? await Task.sleep(for: duration)
            if gate.open() {
                work.cancel()
                continuation.resume(throwing: TimeoutError.timedOut)
            }
        })
    }
}

/// 時間切れを見張るタスクを、処理の側から止めるための入れ物
nonisolated private final class TimerHolder: Sendable {
    private let state = Mutex<(task: Task<Void, Never>?, isCancelled: Bool)>((nil, false))

    func set(_ task: Task<Void, Never>) {
        let cancelled = state.withLock { state in
            state.task = task
            return state.isCancelled
        }
        // 処理がタスクの登録より先に終わっていた場合
        if cancelled { task.cancel() }
    }

    func cancel() {
        let task = state.withLock { state in
            state.isCancelled = true
            return state.task
        }
        task?.cancel()
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
