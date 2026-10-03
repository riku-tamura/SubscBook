#if canImport(FoundationModels)
import Foundation
import FoundationModels
import OSLog

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
        - 新しいサービスの契約や、新しいサービス探しはすすめないでください。
        - 数字は使わないでください。
        """
    /// 長い出力が止まらずに文脈の上限を超えることがあるため、生成するトークン数を抑える
    static let monthlyOptions = GenerationOptions(temperature: 0.5, maximumResponseTokens: 160)
    static let reasonOptions = GenerationOptions(temperature: 0.5, maximumResponseTokens: 200)

    private let fallback = TemplateInsightService()
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "SubscBook", category: "Insight")

    /// 何を伝えるかはアプリが決め（定型の文）、AI にはその言い換えだけを任せる（今月のひとことも、解約候補の理由も）。
    /// 事実の箇条書きから自由に書かせると、事実と食い違う文や、ほかのサービスをすすめる文、文法の崩れた文が混ざりやすかったため。
    func monthlyComment(for facts: MonthlyInsightFacts) async -> InsightResult {
        let prompt = """
            次の文を、意味を変えずに、やさしいひとことコメントに言い換えてください。
            \(Self.withoutQuotes(TemplateInsightService.monthlyText(for: facts)))
            \(Self.rules)
            """
        if let text = await generate(maxLength: 60, forbiddenTerms: facts.contradictingTerms, operation: {
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
            次の文を、意味を変えずに、やさしい言い方に言い換えてください。
            \(Self.withoutQuotes(TemplateInsightService.cancelReasonText(for: facts)))
            \(Self.rules)
            """
        if let text = await generate(maxLength: 80, operation: {
            let session = LanguageModelSession(instructions: Self.instructions)
            return try await session.respond(to: prompt, generating: CancelReason.self, options: Self.reasonOptions)
                .content.reason
        }) {
            return InsightResult(text: text, isGenerated: true)
        }
        return await fallback.cancelReason(for: facts)
    }

    /// かぎ括弧を外す。プロンプトにあると、モデルが出力の文字列を 」 で閉じて読み取れなくなることがあるため。
    private static func withoutQuotes(_ text: String) -> String {
        text.replacingOccurrences(of: "「", with: "").replacingOccurrences(of: "」", with: "")
    }

    /// 生成してチェックを通った文だけを返す。失敗の理由は端末内のログにだけ残す（本文は記録しない）。
    private func generate(
        maxLength: Int,
        allowedTerms: [String] = [],
        forbiddenTerms: [String] = [],
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
        guard let text = InsightSanitizer.sanitize(
            generated, maxLength: maxLength, allowedTerms: allowedTerms, forbiddenTerms: forbiddenTerms
        ) else {
            Self.logger.notice("AI output rejected by sanitizer (length \(generated.count, privacy: .public))")
            #if DEBUG
            Self.logger.debug("rejected output: \(generated, privacy: .public)")
            #endif
            return nil
        }
        return text
    }
}
#endif
