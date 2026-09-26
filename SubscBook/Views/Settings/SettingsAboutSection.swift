import SwiftUI

/// 利用規約・プライバシーポリシー・バージョン
struct SettingsAboutSection: View {
    private var version: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "-"
        let build = info?["CFBundleVersion"] as? String ?? "-"
        return "\(version)（\(build)）"
    }

    var body: some View {
        Section("このアプリについて") {
            Link(destination: AppLinks.termsOfUse) {
                HStack {
                    Text("利用規約")
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .foregroundStyle(.tertiary)
                        .accessibilityHidden(true)
                }
            }
            .tint(.primary)
            NavigationLink("プライバシーポリシー") {
                PrivacyPolicyView()
            }
            LabeledContent("バージョン", value: version)
        }
    }
}
