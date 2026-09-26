import SwiftData
import SwiftUI

/// ⑤ 月次チェックイン
struct CheckInView: View {
    @Query(filter: Subscription.activePredicate) private var activeSubscriptions: [Subscription]
    @State private var viewModel: CheckInViewModel?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    CheckInFlow(viewModel: viewModel, activeSubscriptions: activeSubscriptions)
                } else {
                    ProgressView()
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(viewModel?.isFinished == true ? "閉じる" : "あとで") { dismiss() }
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = CheckInViewModel(subscriptions: activeSubscriptions)
            }
        }
    }
}

private struct CheckInFlow: View {
    let viewModel: CheckInViewModel
    let activeSubscriptions: [Subscription]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Group {
            if let subscription = viewModel.current {
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        ProgressView(value: viewModel.progress)
                            .accessibilityHidden(true)
                        HStack {
                            if viewModel.canGoBack {
                                Button("ひとつ戻る", systemImage: "chevron.backward") {
                                    withAnimation { viewModel.goBack() }
                                }
                                .font(.subheadline)
                            }
                            Spacer()
                            Text(viewModel.progressText)
                                .font(.subheadline.monospacedDigit())
                                .foregroundStyle(.secondary)
                                .accessibilityLabel("\(viewModel.queue.count)件中\(min(viewModel.index + 1, viewModel.queue.count))件目")
                        }
                    }
                    Spacer(minLength: 0)
                    CheckInCard(subscription: subscription, month: viewModel.month) { used in
                        withAnimation(.snappy) {
                            viewModel.answer(used: used, in: modelContext)
                        }
                    }
                    .id(subscription.id)
                    .transition(.asymmetric(insertion: .scale(scale: 0.9).combined(with: .opacity), removal: .opacity))
                    Spacer(minLength: 0)
                }
                .padding()
                .navigationTitle("\(viewModel.month.monthText)のチェックイン")
            } else {
                CheckInCompletion(
                    answeredCount: viewModel.queue.count,
                    suggestions: viewModel.cancelSuggestions(among: activeSubscriptions)
                )
                .navigationTitle("チェックイン")
            }
        }
    }
}

// MARK: - カード

private struct CheckInCard: View {
    let subscription: Subscription
    let month: YearMonth
    let onAnswer: (Bool) -> Void

    @State private var offset: CGSize = .zero
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
            .onChanged { offset = $0.translation }
            .onEnded { value in
                let width = value.translation.width
                if abs(width) > threshold {
                    let used = width > 0
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

// MARK: - 完了

private struct CheckInCompletion: View {
    let answeredCount: Int
    let suggestions: [CancelSuggestion]
    @Environment(AppRouter.self) private var router
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.green)
                    .symbolEffect(.bounce, value: answeredCount)
                    .accessibilityHidden(true)
                    .padding(.top, 40)
                Text(answeredCount > 0 ? "チェックイン完了" : "回答するサブスクはありません")
                    .font(.title2.weight(.bold))
                Text(answeredCount > 0
                     ? "\(answeredCount)件のサブスクを振り返りました。来月も見張りを続けます。"
                     : "先月分のチェックインはすべて回答済みです。")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)

                if !suggestions.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        CardHeader(title: "使っていないサブスクが見つかりました", systemImage: "scissors", tint: .pink)
                        Text("2ヶ月続けて使っていないサブスクが\(suggestions.count)件あります。続けるか見直してみませんか？")
                            .font(.subheadline)
                        Button("レポートで確認する") {
                            router.selectedTab = .report
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.top, 4)
                    }
                    .card()
                }

                Button("閉じる") { dismiss() }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
            }
            .padding()
        }
    }
}
