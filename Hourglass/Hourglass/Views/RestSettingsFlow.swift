import SwiftUI

struct RestSettingsFlow: View {
    let viewModel: ViewModel
    let settingsManager: SettingsManager

    @State var restWarningThreshold: Int
    @State var enforceRestThreshold: Int
    @State var getBackToWorkIsEnabled: Bool

    init(viewModel: ViewModel, settingsManager: SettingsManager) {
        self.viewModel = viewModel
        self.settingsManager = settingsManager
        self.restWarningThreshold = settingsManager.getRestWarningThreshold()
        self.enforceRestThreshold = settingsManager.getEnforceRestThreshold()
        self.getBackToWorkIsEnabled = settingsManager.getGetBackToWorkIsEnabled()
    }

    var body: some View {
        VStack {
            Form {
                Picker("Rest Reminder:", selection: $restWarningThreshold) {
                    Text("Off").tag(-1)
                    Text("15").tag(15)
                    Text("20").tag(20)
                    Text("30").tag(30)
                    Text("40").tag(40)
                    Text("50").tag(50)
                    Text("60").tag(60)
                }
                .onChange(of: restWarningThreshold) { _ in
                    if !dataIsValid { enforceRestThreshold = -1 }
                }
                .help(Copy.restReminderHelp)

                Picker("Enforce Rest:", selection: $enforceRestThreshold) {
                    Text("Off").tag(-1)
                    Text("15").tag(15)
                    Text("20").tag(20)
                    Text("30").tag(30)
                    Text("40").tag(40)
                    Text("50").tag(50)
                    Text("60").tag(60)
                }
                .onChange(of: enforceRestThreshold) { _ in
                    if !dataIsValid { restWarningThreshold = -1 }
                }
                .help(Copy.enforceRestHelp)

                Toggle("Get Back to Work", isOn: $getBackToWorkIsEnabled)
                    .help(Copy.getBackToWorkHelp)

                Button("Close") {
                    defer {
                        settingsManager.setRestWarningThreshold(restWarningThreshold, conservatively: true)
                        settingsManager.setEnforceRestThreshold(enforceRestThreshold, conservatively: true)
                        settingsManager.setGetBackToWork(isEnabled: getBackToWorkIsEnabled, conservatively: true)
                    }
                    viewModel.viewState.showRestSettingsFlow.toggle()
                }
            }

            Spacer(minLength: 10)

            Text(Copy.footnote)
                .font(.system(.footnote))
        }
        .font(.system(.body))
        .padding([.leading, .top, .trailing], 20)
        .padding(.bottom, 10)
    }

    private var dataIsValid: Bool {
        switch(restWarningThreshold, enforceRestThreshold) {
        case let (a, b) where a > 0 && b > 0:
            return a < b
        default:
            return true
        }
    }
}

private extension RestSettingsFlow {
    enum Copy {
        static let restReminderHelp = "Reminds you to take a rest after (x) minutes of focus. Must be less than the enforce rest threshold."
        static let enforceRestHelp = "Disables focus timers and forces you to take a rest. Must be greater than the rest reminder threshold."
        static let getBackToWorkHelp = "Prohibits you from taking multiple rest blocks at a time."
        static let footnote = "Note: Hover to see settings descriptions."
    }
}
