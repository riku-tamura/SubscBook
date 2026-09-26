import SwiftUI

extension View {
    /// 無料ユーザーには中身をぼかし、鍵アイコンを重ねる。タップでペイウォールを表示する（6章）。
    func premiumLocked(_ isLocked: Bool, feature: PremiumFeature) -> some View {
        modifier(PremiumLockModifier(isLocked: isLocked, feature: feature))
    }
}

private struct PremiumLockModifier: ViewModifier {
    let isLocked: Bool
    let feature: PremiumFeature
    @Environment(AppRouter.self) private var router

    func body(content: Content) -> some View {
        if isLocked {
            content
                .blur(radius: 7)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
                .overlay {
                    Button {
                        router.showPaywall(.lockedFeature(feature))
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: "lock.fill")
                                .font(.title2)
                            Text("サブスク帳プラスで利用できます")
                                .font(.subheadline.weight(.semibold))
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.accentColor)
                    .accessibilityLabel("\(feature.title)。サブスク帳プラスで利用できます")
                    .accessibilityHint("サブスク帳プラスの案内を開きます")
                }
                .clipped()
        } else {
            content
        }
    }
}
