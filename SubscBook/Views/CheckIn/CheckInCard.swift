import SwiftUI

struct CheckInCard: View {
    let subscription: Subscription
    let month: YearMonth
    let onAnswer: (Bool) -> Void

    @State private var offset: CGSize = .zero
    /// スワイプで回答を確定し、カードが画面外へ出ていく間は他の操作を受け付けない
    @State private var isAnswering = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// この距離を超えてスワイプしたら回答する
    private let threshold: CGFloat = 110

    var body: some View {
        VStack(spacing: 24) {
            card
                .offset(x: offset.width, y: offset.height * 0.2)
                .rotationEffect(.degrees(reduceMotion ? 0 : Double(offset.width / 20)))
                .gesture(dragGesture)
                .accessibilityElement(children: .combine)
                .accessibilityHint("右にスワイプで使った、左にスワイプで使っていない")
                .accessibilityAction(named: "使った") { onAnswer(true) }
                .accessibilityAction(named: "使っていない") { onAnswer(false) }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) { answerButtons }
                VStack(spacing: 12) { answerButtons }
            }
            .disabled(isAnswering)
        }
    }

    private var card: some View {
        VStack(spacing: 16) {
            CategoryIcon(name: subscription.name, category: subscription.category, size: 72)
            Text(subscription.name)
                .font(.title2.weight(.bold))
                .multilineTextAlignment(.center)
            Text(subscription.priceText)
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
            Text("先月（\(month.monthText)）、\(subscription.name)を使いましたか？")
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 24))
        .overlay { swipeHint }
        .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
    }

    /// スワイプ中に回答を示すラベル
    @ViewBuilder
    private var swipeHint: some View {
        let progress = min(abs(offset.width) / threshold, 1)
        if offset.width != 0 {
            let used = offset.width > 0
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(used ? Color.green : Color.orange, lineWidth: 4)
                .overlay(alignment: used ? .topLeading : .topTrailing) {
                    Text(used ? "使った" : "使っていない")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(used ? Color.green : Color.orange, in: .capsule)
                        .padding(16)
                }
                .opacity(progress)
                .accessibilityHidden(true)
        }
    }

    @ViewBuilder
    private var answerButtons: some View {
        Button {
            onAnswer(false)
        } label: {
            Label("使っていない", systemImage: "moon.zzz")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .tint(.orange)
        .controlSize(.large)

        Button {
            onAnswer(true)
        } label: {
            Label("使った", systemImage: "checkmark")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                guard !isAnswering else { return }
                offset = value.translation
            }
            .onEnded { value in
                guard !isAnswering else { return }
                let width = value.translation.width
                if abs(width) > threshold {
                    let used = width > 0
                    isAnswering = true
                    withAnimation(.easeIn(duration: 0.2)) {
                        offset = CGSize(width: used ? 600 : -600, height: value.translation.height)
                    }
                    Task {
                        try? await Task.sleep(for: .milliseconds(200))
                        onAnswer(used)
                    }
                } else {
                    withAnimation(.spring) { offset = .zero }
                }
            }
    }
}
