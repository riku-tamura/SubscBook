import SwiftUI

/// アイコンと文字の組。通常は横に並べ、アクセシビリティサイズの文字ではアイコンを上に置いて縦に積む
/// （横に並べたままだと、文字の幅がなくなって1行に数文字しか入らず、日付などが切れるため）。
struct IconLabelStack<Icon: View, Label: View>: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    private let alignment: VerticalAlignment
    private let spacing: CGFloat
    private let icon: Icon
    private let label: Label

    init(
        alignment: VerticalAlignment = .center,
        spacing: CGFloat = 12,
        @ViewBuilder icon: () -> Icon,
        @ViewBuilder label: () -> Label
    ) {
        self.alignment = alignment
        self.spacing = spacing
        self.icon = icon()
        self.label = label()
    }

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 8) {
                icon
                label
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            HStack(alignment: alignment, spacing: spacing) {
                icon
                label
            }
        }
    }
}
