import SwiftUI

/// 設定
struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()

    var body: some View {
        NavigationStack {
            Form {
                SettingsPremiumSection(viewModel: viewModel)
                SettingsNotificationSection()
                SettingsInsightSection()
                SettingsAboutSection(appVersion: viewModel.appVersion)
                SettingsDataDeletionSection(viewModel: viewModel)
                #if DEBUG
                SettingsDebugSection()
                #endif
            }
            .navigationTitle("設定")
        }
    }
}
