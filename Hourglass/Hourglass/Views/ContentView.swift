import SwiftUI

struct ContentView: View {
    let viewModel: ViewModel
    let settingsManager: SettingsManager

    var body: some View {
        ZStack {
            AlertView(viewModel: viewModel, settingsManager: settingsManager)

            VStack(alignment: .center, spacing: 18.0) {
                HStack {
                    Logo(size: 28)
                    Spacer()
                    TimerCategoryToggle(viewModel: viewModel,
                                        presenterModel: viewModel.timerCategoryTogglePresenterModel)
                    Spacer()
                    SettingsMenu(viewModel: viewModel)
                }

                HStack {
                    ForEach(viewModel.timerModels.values.sortBySize()) { model in
                        TimerButton(model: model) {
                            viewModel.didTapTimer(from: model)
                        }
                    }
                }
            }
            .fixedSize()
            .padding(24)
            .background(Color.Hourglass.background)
            .font(.poppinsBody)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = ViewModel(analyticsManager: AnalyticsManager.shared,
                                  dataManager: DataManager.shared,
                                  settingsManager: SettingsManager.shared,
                                  timerManager: TimerManager.shared,
                                  userNotificationManager: UserNotificationManager.shared)
        let settingsManager = SettingsManager.shared
        ContentView(viewModel: viewModel, settingsManager: settingsManager)
    }
}
