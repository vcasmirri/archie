import Cocoa

/// Entry point: a regular Dock app with one floating, device-shaped window.
@main
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var controller: WidgetController?

    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.regular)
        app.run()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.mainMenu = MenuBuilder.build(target: self, keepOnTop: Settings.keepOnTop)
        let controller = WidgetController()
        controller.show()
        self.controller = controller
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    @objc func toggleKeepOnTop(_ sender: NSMenuItem) {
        guard let controller else { return }
        controller.toggleKeepOnTop()
        sender.state = controller.keepOnTop ? .on : .off
    }

    @objc func setPageAddress(_ sender: Any?) { controller?.promptForPageAddress() }
    @objc func useBuiltInPage(_ sender: Any?) { controller?.useBuiltInPage() }
    @objc func reloadPage(_ sender: Any?) { controller?.reload() }
    @objc func signOutOfGoogle(_ sender: Any?) { controller?.signOut() }
}
