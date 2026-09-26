import SwiftUI

/// AIコメントの利用可否（非対応の場合は理由を表示）
struct SettingsInsightSection: View {
    @Environment(InsightProvider.self) private var insights

    var body: some View {
        Section {
            LabeledContent("AIコメント") {
                Text(insights.availability.isAvailable ? "利用できます" : "定型のコメントを表示中")
                    .foregroundStyle(insights.availability.isAvailable ? Color.green : .secondary)
            }
        } header: {
            Text("AI")
        } footer: {
            Text(insights.availability.message + "AIが使えない場合も、すべての機能をご利用いただけます。")
        }
    }
}
