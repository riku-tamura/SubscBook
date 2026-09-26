#if canImport(FoundationModels)
import Foundation
import FoundationModels
import OSLog
import Synchronization

@available(iOS 26.0, *)
@Generable
struct MonthlyInsight {
    @Guide(description: "ユーザーへのひとことコメント。60文字以内。数値や金額は書かない。前向きで押しつけがましくない口調。")
    var comment: String
}

@available(iOS 26.0, *)
@Generable
struct CancelReason {
    @Guide(description: "解約を検討してよい理由の説明。80文字以内。数値や金額は書かない。断定せず提案の形にする。")
    var reason: String
}

/// 端末内モデル（FoundationModels）でコメントを作る（8章）。
/// 失敗・5秒のタイムアウト・ガードレールによる拒否・数値を含む出力はテンプレート文にフォールバックする。
@available(iOS 26.0, *)
nonisolated struct FoundationModelInsightService: InsightService {
    static let instructions = """
        あなたは家計簿アプリの穏やかなアシスタントです。
        与えられた事実だけをもとに、短い日本語のコメントを書きます。
        数値・金額・日付は絶対に書かないでください（アプリ側で表示します）。
        投資や金融商品についての助言は一切しないでください。
        ユーザーを責めず、提案の形で伝えてください。
        """
    static let timeout: Duration = .seconds(5)
    /// 出力の条件。指示文（8.4）に加えてプロンプトで伝える。
    static let rules = """
        条件：
        - です・ます調で、やさしく書いてください。
        - 事実に書かれていないこと（料金・手数料・違約金・他社サービスなど）は書かないでください。
        - 新しいサービスの契約はすすめないでください。
        - 数字は使わないでください。
        """
    /// 長い出力が止まらずに文脈の上限を超えることがあるため、生成するトークン数を抑える
    static let monthlyOptions = GenerationOptions(temperature: 0.5, maximumResponseTokens: 160)
    static let reasonOptions = GenerationOptions(temperature: 0.5, maximumResponseTokens: 200)

    private let fallback = TemplateInsightService()
    private static let logger = Logger(subsystem: "com.hachimaki.SubscBook", category: "Insight")

    func monthlyComment(for facts: MonthlyInsightFacts) async -> InsightResult {
        let prompt = """
            今月のサブスクの状況：
            \(facts.promptLines.joined(separator: "\n"))
            \(Self.rules)
            この状況をふまえて、ユーザーへのひとことコメントを書いてください。
            """
        if let text = await generate(maxLength: 60, allowedTerms: facts.allowedTerms, operation: {
            let session = LanguageModelSession(instructions: Self.instructions)
            return try await session.respond(to: prompt, generating: MonthlyInsight.self, options: Self.monthlyOptions)
                .content.comment
        }) {
            return InsightResult(text: text, isGenerated: true)
        }
        return await fallback.monthlyComment(for: facts)
    }

    func cancelReason(for facts: CancelReasonFacts) async -> InsightResult {
        let prompt = """
            次のサブスクを見直すきっかけになる理由を、ひとつか二つの文で書いてください。\
            文の終わりは、見直してみませんか、のような提案にしてください。
            \(facts.promptLines.joined(separator: "\n"))
            \(Self.rules)
            """
        if let text = await generate(maxLength: 80, allowedTerms: facts.allowedTerms, operation: {
            let session = LanguageModelSession(instructions: Self.instructions)
            return try await session.respond(to: prompt, generating: CancelReason.self, options: Self.reasonOptions)
                .content.reason
        }) {
            return InsightResult(text: text, isGenerated: true)
        }
        return await fallback.cancelReason(for: facts)
    }

    /// 生成してチェックを通った文だけを返す。失敗の理由は端末内のログにだけ残す（本文は記録しない）。
    private func generate(
        maxLength: Int,
        allowedTerms: [String],
        operation: @escaping @Sendable () async throws -> String
    ) async -> String? {
        let generated: String
        do {
            generated = try await withTimeout(Self.timeout, operation: operation)
        } catch {
            // エラーの説明には生成途中の文（サービス名など）が含まれることがあるので、種類だけを記録する
            Self.logger.notice("AI generation fell back: \(String(describing: type(of: error)), privacy: .public)")
            return nil
        }
        guard let text = InsightSanitizer.sanitize(generated, maxLength: maxLength, allowedTerms: allowedTerms) else {
            Self.logger.notice("AI output rejected by sanitizer (length \(generated.count, privacy: .public))")
            #if DEBUG
            Self.logger.debug("rejected output: \(generated, privacy: .public)")
            #endif
            return nil
        }
        return text
    }
}

enum InsightTimeoutError: Error {
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
                continuation.resume(throwing: InsightTimeoutError.timedOut)
            }
        }
    }
}

/// continuation を一度だけ resume するための門
nonisolated final class ResumeGate: Sendable {
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
#endif
