import SwiftUI

struct AlertView: View {
    @StateObject var viewModel: ViewModel
    let settingsManager: SettingsManager

    var body: some View {
        Color.clear
            .confirmationDialog(Copy.startNewTimerDialogPrompt,
                                isPresented: $viewModel.viewState.showStartNewTimerDialog) {
                Button(Copy.startNewTimerDialogConfirm, role: .none) {
                    viewModel.didReceiveStartNewTimerDialog(response: .yes)
                }
                Button(Copy.startNewTimerDialogCancel, role: .cancel) {
                    viewModel.didReceiveStartNewTimerDialog(response: .no)
                }
            }
            .alert(Copy.timerResetAlert, isPresented: $viewModel.viewState.showTimerResetAlert) {}
            .sheet(isPresented: $viewModel.viewState.showRestSettingsFlow) {
                RestSettingsFlow(viewModel: viewModel, settingsManager: settingsManager)
            }
    }
}

private extension AlertView {
    enum Copy {
        static let startNewTimerDialogPrompt = "Are you sure you want to start a new timer?"
        static let startNewTimerDialogConfirm = "Start timer"
        static let startNewTimerDialogCancel = "Cancel"
        static let timerResetAlert = "Timer settings have been reset."
    }
}
