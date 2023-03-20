import SwiftUI

struct TimerGrid: View {
    let viewModel: ViewModel
    let ySpacing = 20.0
    let xSpacing = 26.0

    var body: some View {
        HStack(alignment: .center, spacing: xSpacing) {
            VStack(alignment: .center, spacing: ySpacing) {
                Header(content: "Focus")

                ForEach(viewModel.timerModels.filterByCategory(.focus)) { model in
                    TimerButton(model: model) {
                        viewModel.didTapTimer(from: model)
                    }
                }
            }

            VStack(alignment: .center, spacing: ySpacing) {
                Header(content: "Break")

                ForEach(viewModel.timerModels.filterByCategory(.rest)) { model in
                    TimerButton(model: model) {
                        viewModel.didTapTimer(from: model)
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("timer-grid")
    }
}

private struct Header: View {
    let content: String

    var body: some View {
        Text(content)
            .foregroundColor(Color.onBackgroundPrimary)
    }
}