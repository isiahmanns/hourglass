import SwiftUI
import Combine

struct TimerButton: View {
    @StateObject var model: TimerButton.PresenterModel
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            Text(String(model.length))
        }
        .buttonStyle(TimerButton.Style(for: model.state))
        .accessibilityIdentifier("\(model.length)m-timer-button")
    }
}

extension TimerButton {
    private struct Style: ButtonStyle {
        let state: TimerButton.State
        let size: CGFloat = 32

        init(for state: TimerButton.State) {
            self.state = state
        }

        func makeBody(configuration: Self.Configuration) -> some View {
            configuration.label
                .font(.poppinsBody)
                .frame(width: size, height: size, alignment: .center)
                .background(Color.Hourglass.surface)
                .foregroundColor(Color.Hourglass.onSurface)
                .clipShape(Circle())
                .contentShape(Circle())
                .opacity(opacityProvider(configuration.isPressed))
                .overlay(overlayProvider)
        }

        @ViewBuilder
        private var overlayProvider: some View {
            switch state {
            case .inactive:
                EmptyView()
            case .active:
                Circle()
                    .stroke(Color.Hourglass.accent, lineWidth: 2.6)
            }
        }

        private func opacityProvider(_ isPressed: Bool) -> Double {
            isPressed ? 0.8 : 1.0
        }
    }
}

struct TimerButton_Previews: PreviewProvider {
    static var previews: some View {
        let timerModel = TimerButton.PresenterModel(length: 15)
        TimerButton(model: timerModel) {}
    }
}
