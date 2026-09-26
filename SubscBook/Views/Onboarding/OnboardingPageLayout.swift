import SwiftUI

/// オンボーディングの各ページで共通のレイアウト
struct OnboardingPageLayout<Content: View>: View {
    /// 何ページ目か（1から）
    let step: Int
    let systemImage: String
    let title: String
    let primaryTitle: String
    let primaryAction: () -> Void
    var secondaryTitle: String?
    var secondaryAction: (() -> Void)?
    var isBusy = false
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                    OnboardingStepIndicator(step: step)
                        .padding(.top, 16)
                    Image(systemName: systemImage)
                        .font(.system(size: 64))
                        .foregroundStyle(Color.accentColor)
                        .padding(.top, 16)
                        .accessibilityHidden(true)
                    Text(title)
                        .font(.largeTitle.weight(.bold))
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)
                    content
                }
                .padding()
            }
            VStack(spacing: 8) {
                Button(action: primaryAction) {
                    Group {
                        if isBusy {
                            ProgressView().tint(.white)
                        } else {
                            Text(primaryTitle)
                        }
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(isBusy)
                if let secondaryTitle, let secondaryAction {
                    Button(secondaryTitle, action: secondaryAction)
                        .controlSize(.large)
                        .disabled(isBusy)
                }
            }
            .padding()
        }
    }
}
