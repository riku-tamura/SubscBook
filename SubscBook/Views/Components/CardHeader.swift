import SwiftUI

/// カードの見出し
struct CardHeader: View {
    let title: String
    let systemImage: String
    var tint: Color = .accentColor

    var body: some View {
        Label {
            Text(title)
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(tint)
        }
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(.secondary)
        .accessibilityAddTraits(.isHeader)
    }
}
