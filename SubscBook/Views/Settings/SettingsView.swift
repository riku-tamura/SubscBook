import SwiftUI

/// 設定
struct SettingsView: View {
    var body: some View {
        NavigationStack {
            Form {
                SettingsPremiumSection()
                SettingsNotificationSection()
                SettingsInsightSection()
                SettingsAboutSection()
                SettingsDataDeletionSection()
                #if DEBUG
                SettingsDebugSection()
                #endif
            }
            .navigationTitle("設定")
        }
    }
}
