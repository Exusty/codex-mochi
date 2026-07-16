import AppKit

@MainActor
final class ApplicationMain {
    static func run() {
        let application = NSApplication.shared
        let delegate = AppDelegate()
        application.setActivationPolicy(.accessory)
        application.delegate = delegate
        application.run()
        withExtendedLifetime(delegate) {}
    }
}

ApplicationMain.run()
