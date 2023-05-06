import UserNotifications

protocol NotificationManager {
    func fireNotification(_ notification: HourglassNotification, soundIsEnabled: Bool)
}

class UserNotificationManager: NSObject, NotificationManager {
    static let shared = UserNotificationManager(userNotificationCenter: .current())
    private let userNotificationCenter: UNUserNotificationCenter

    private init(userNotificationCenter: UNUserNotificationCenter) {
        self.userNotificationCenter = userNotificationCenter
        super.init()
        userNotificationCenter.delegate = self
        requestAuthorizationIfNeeded()
    }

    private func requestAuthorizationIfNeeded() {
        userNotificationCenter.getNotificationSettings { settings in
            if settings.authorizationStatus == .notDetermined {
                self.userNotificationCenter.requestAuthorization(options: [.sound, .alert])
                { granted, error in }
            }
        }
    }

    func fireNotification(_ notification: HourglassNotification,
                          soundIsEnabled: Bool) {
        let notificationContent = notification.contentBase
            .sound(soundIsEnabled ? .default : nil)

        let request = UNNotificationRequest(identifier: notification.id,
                                            content: notificationContent,
                                            trigger: nil)

        userNotificationCenter.removeAllDeliveredNotifications()
        userNotificationCenter.add(request)
    }
}

extension UserNotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                didReceive response: UNNotificationResponse,
                withCompletionHandler completionHandler: @escaping () -> Void) {
        print("notification was clicked")
        // Note: No programmatic way to open MenuBarExtra yet. Could use view model to tap another timer.
    }
}

extension UNMutableNotificationContent {
    func sound(_ value: UNNotificationSound?) -> Self {
        self.sound = value
        return self
    }
}
