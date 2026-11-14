import SwiftUI
import UserNotifications

@main
struct AceApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var settings: SettingsStore
    @StateObject private var core: AceCore
    @Environment(\.scenePhase) private var scenePhase

    init() {
        let s = SettingsStore()
        _settings = StateObject(wrappedValue: s)
        _core = StateObject(wrappedValue: AceCore(settings: s))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(settings)
                .environmentObject(core)
                .onOpenURL { url in handle(url) }
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active: core.becameActive()
            case .background: core.wentToBackground()
            default: break
            }
        }
        .backgroundTask(.appRefresh(BackgroundWake.id)) {
            await BackgroundWake.run()
        }
    }

    /// ace://check wakes Ace up right away. ace://talk just opens the chat.
    private func handle(_ url: URL) {
        guard url.scheme == "ace" else { return }
        switch url.host ?? "" {
        case "check":
            Task { await core.wakeUp(reason: .manual) }
        default:
            break
        }
    }
}

/// Lets Ace's own notifications show as banners even while the app is open.
final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        UIDevice.current.isBatteryMonitoringEnabled = true
        return true
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .list])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }
}
