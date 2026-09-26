import SwiftData
import SwiftUI

/// チェックインの進行（進み具合と、回答中のカード）
struct CheckInQuestionView: View {
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
                            viewModel.answer(used: used, for: subscription, in: modelContext)
                        }
                    }
                    .id(subscription.id)
                    .transition(.asymmetric(insertion: .scale(scale: 0.9).combined(with: .opacity), removal: .opacity))
                    Spacer(minLength: 0)
                }
                .padding()
                .navigationTitle("\(viewModel.month.monthText)のチェックイン")
            } else {
                CheckInCompletionView(
                    answeredCount: viewModel.queue.count,
                    emptyReason: viewModel.emptyReason,
                    suggestions: viewModel.cancelSuggestions(among: activeSubscriptions)
                )
                .navigationTitle("チェックイン")
            }
        }
        .alert("保存できませんでした", isPresented: Binding(
            get: { viewModel.saveErrorMessage != nil },
            set: { if !$0 { viewModel.saveErrorMessage = nil } }
        )) {
            Button("OK") {}
        } message: {
            Text(viewModel.saveErrorMessage ?? "")
        }
    }
}
