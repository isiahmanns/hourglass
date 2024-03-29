import Combine

/**
 A manager object that subscribes to timer events and handles associated `TimerButton` and `TimerCategoryToggle` PresenterModel state mutation.
 */
class TimerModelStateManager {
    static let shared = TimerModelStateManager(analyticsManager: AnalyticsManager.shared,
                                               dataManager: DataManager.shared,
                                               settingsManager: SettingsManager.shared,
                                               timerEventProvider: TimerManager.shared)

    private let analyticsManager: AnalyticsManager
    private let timerModels: [TimerButton.PresenterModel.ID: TimerButton.PresenterModel]
    private let timerCategoryTogglePresenterModel: TimerCategoryToggle.PresenterModel
    private let timerEvents: [HourglassEventKey.Timer: TimerEvent]
    private let settingsManager: SettingsManager
    weak var delegate: (EventNotifying & TimerHandling)?

    private var activeTimerModelId: TimerButton.PresenterModel.ID?
    private var activeTimerModel: TimerButton.PresenterModel? {
        guard let activeTimerModelId else { return nil }
        return timerModels[activeTimerModelId]
    }

    /**
     An amount of focus time that when met, the user is notified to take a rest soon.

     This setting is triggered immediately, on the tick of the timer.
     */
    private var restWarningThreshold: SettingsThreshold {
        settingsManager.getRestWarningThreshold()
    }

    /**
     An amount of focus time that when met or surpassed, the user is forced to take a rest.

     This setting is triggered when a timer is cancelled or completed.
     */
    private var enforceRestThreshold: SettingsThreshold {
        settingsManager.getEnforceRestThreshold()
    }

    private var getBackToWorkIsEnabled: Bool {
        settingsManager.getGetBackToWorkIsEnabled()
    }

    /**
     The accumulating time-span that is represented by ticking focus timers.

     This value is incremented as a focus timer ticks and used as a gate to trigger the user's rest settings.
     This is an ever-incrementing value (even through timer cancellations) and is only reset when a rest timer is completed.
     */
    private var focusStride: Int = 0
    private var cancellables: Set<AnyCancellable> = []

    fileprivate init(analyticsManager: AnalyticsManager,
                     dataManager: DataManaging,
                     settingsManager: SettingsManager,
                     timerEventProvider: TimerEventProviding) {
        print("INITIALIZING TMSM")
        self.analyticsManager = analyticsManager
        self.timerModels = dataManager.timerModels
        self.timerCategoryTogglePresenterModel = dataManager.timerCategoryTogglePresenterModel
        self.settingsManager = settingsManager
        self.timerEvents = timerEventProvider.events
        configureEventSubscriptions()
        configureSettingsObservations()
    }

    private func configureEventSubscriptions() {
        timerEvents[.timerDidStart]?
            .sink { [weak self] timerModelId, _ in
                guard let self else { return }
                guard activeTimerModelId == nil else { fatalError() }
                activeTimerModelId = timerModelId
                activeTimerModel?.state = .active
            }
            .store(in: &cancellables)

        timerEvents[.timerDidComplete]?
            .sink { [weak self] timerModelId, timerCategory in
                guard let self else { return }
                guard let activeTimerModel, timerModelId == activeTimerModel.id else {
                    fatalError()
                }

                defer { self.activeTimerModelId = nil }

                activeTimerModel.state = .inactive
                delegate?.notifyUser(timerEvent: .timerDidComplete)

                if [.focusOnly, .restOnly].contains(timerCategoryTogglePresenterModel.state) {
                    timerCategoryTogglePresenterModel.state = .focus
                }

                switch timerCategory {
                case .focus:
                    focusStride += 1
                    showRestWarningIfNeeded()
                    enforceRestIfNeeded()
                case .rest:
                    resetFocusStride()
                    enforceFocusIfNeeded()
                }

                analyticsManager.logEvent(.timerDidComplete(activeTimerModel, timerCategory))
            }
            .store(in: &cancellables)

        timerEvents[.timerWasCancelled]?
            .sink { [weak self] timerModelId, timerCategory in
                guard let self else { return }
                guard let activeTimerModel, timerModelId == activeTimerModel.id else {
                    fatalError()
                }

                defer { self.activeTimerModelId = nil }

                activeTimerModel.state = .inactive
                analyticsManager.logEvent(.timerWasCancelled(activeTimerModel, timerCategory))
            }
            .store(in: &cancellables)
    }

    private func configureSettingsObservations() {
        settingsManager.observe(\.restWarningThreshold) { [self] newValue in
            didChangeRestSettings()
            analyticsManager.logEvent(.restWarningThresholdSet(newValue))
        }

        settingsManager.observe(\.enforceRestThreshold) { [self] newValue in
            didChangeRestSettings()
            analyticsManager.logEvent(.enforceRestThresholdSet(newValue))
        }

        settingsManager.observe(\.getBackToWork) { [self] isEnabled in
            // TODO: - Invoke didChangeRestSettings here
            if !isEnabled {
                timerCategoryTogglePresenterModel.state = .focus
            }

            analyticsManager.logEvent(.getBackToWorkSet(isEnabled))
        }
    }

    private func didChangeRestSettings() {
        try? delegate?.resetActiveTimer()
        timerCategoryTogglePresenterModel.state = .focus
        resetFocusStride()
    }

    private func resetFocusStride() {
        focusStride = 0
    }

    private func showRestWarningIfNeeded() {
        if focusStride == restWarningThreshold.rawValue {
            delegate?.notifyUser(progressEvent: .restWarningThresholdMet)
        }
    }

    private func enforceRestIfNeeded() {
        if focusStride == enforceRestThreshold.rawValue {
            delegate?.notifyUser(progressEvent: .enforceRestThresholdMet)
            timerCategoryTogglePresenterModel.state = .restOnly
        }
    }

    private func enforceFocusIfNeeded() {
        if getBackToWorkIsEnabled {
            delegate?.notifyUser(progressEvent: .getBackToWork)
            timerCategoryTogglePresenterModel.state = .focusOnly
        }
    }
}

class TimerModelStateManagerFake: TimerModelStateManager {
    override init(analyticsManager: AnalyticsManager,
                  dataManager: DataManaging,
                  settingsManager: SettingsManager,
                  timerEventProvider: TimerEventProviding) {
        super.init(analyticsManager: analyticsManager,
                   dataManager: dataManager,
                   settingsManager: settingsManager,
                   timerEventProvider: timerEventProvider)
    }
}
