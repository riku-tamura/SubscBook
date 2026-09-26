import SwiftUI

/// オンボーディングの何ページ目かを示す（●●○）
struct OnboardingStepIndicator: View {
    let step: Int
    var total = 3

    var body: some View {
        HStack(spacing: 6) {
            ForEach(1...total, id: \.self) { index in
                Capsule()
                    .fill(index == step ? Color.accentColor : Color.secondary.opacity(0.3))
                    .frame(width: index == step ? 20 : 8, height: 8)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(total)ページ中\(step)ページ目")
    }
}
