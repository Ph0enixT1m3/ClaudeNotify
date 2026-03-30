import Cocoa
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {

    func applicationDidFinishLaunching(_ notification: Notification) {
        let args = CommandLine.arguments
        let message = args.count > 1 ? args[1] : ""
        let title   = args.count > 2 ? args[2] : "Claude Code"
        let sound   = args.count > 3 ? args[3] : "default"

        if message.isEmpty { NSApp.terminate(nil); return }

        let center = UNUserNotificationCenter.current()
        center.delegate = self

        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { DispatchQueue.main.async { NSApp.terminate(nil) }; return }
            self.send(title: title, message: message, sound: sound)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 120) { NSApp.terminate(nil) }
    }

    func send(title: String, message: String, sound: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body  = message
        content.sound = sound == "none" ? nil : UNNotificationSound(named: UNNotificationSoundName(sound))
        let req = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        )
        UNUserNotificationCenter.current().add(req, withCompletionHandler: nil)
    }

    func userNotificationCenter(_ c: UNUserNotificationCenter,
                                didReceive r: UNNotificationResponse,
                                withCompletionHandler done: @escaping () -> Void) {
        done()
        if let app = NSWorkspace.shared.runningApplications.first(where: {
            $0.bundleIdentifier == "com.microsoft.VSCode"
        }) {
            app.activate(options: [.activateIgnoringOtherApps])
        } else {
            NSWorkspace.shared.open(URL(fileURLWithPath: "/Applications/Visual Studio Code.app"))
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            exit(0)
        }
    }

    func userNotificationCenter(_ c: UNUserNotificationCenter,
                                willPresent n: UNNotification,
                                withCompletionHandler done: @escaping (UNNotificationPresentationOptions) -> Void) {
        done([.banner, .sound])
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = AppDelegate()
app.delegate = delegate
app.run()
