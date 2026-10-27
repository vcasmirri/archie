import Cocoa
import WebKit

/// Owns the widget window and talks to the page.
/// Page → app messages: mode (resize), dragArm, signIn, open. App → page: token, authError, signedOut, dragging.
final class WidgetController: NSObject, WKScriptMessageHandler, WKNavigationDelegate {
    private enum Mode: String {
        case compact, open, full
        var size: NSSize {
            switch self {
            case .compact: return NSSize(width: 420, height: 550)
            case .open: return NSSize(width: 900, height: 720)
            case .full: return NSSize(width: 1200, height: 860)
            }
        }
    }

    /// Runs before the page's own script, so the page knows it's inside the app.
    private static let bridgeScript = """
    window.ArchieNative = { listeners: [],
      post(m) { window.webkit.messageHandlers.archie.postMessage(m); },
      on(f) { this.listeners.push(f); },
      receive(m) { for (const f of this.listeners) f(m); } };
    """

    private let window = WidgetWindow(size: Mode.compact.size)
    private let webView: DragWebView
    private let uiDelegate = WebUIDelegate()
    private let schemeHandler: BundleSchemeHandler
    private var auth: GoogleAuth?
    private(set) var keepOnTop = Settings.keepOnTop

    override init() {
        let web = Bundle.main.resourceURL!.appendingPathComponent("web")
        schemeHandler = BundleSchemeHandler(root: web)
        let content = WKUserContentController()
        content.addUserScript(WKUserScript(source: Self.bridgeScript, injectionTime: .atDocumentStart, forMainFrameOnly: true))
        let config = WKWebViewConfiguration()
        config.userContentController = content
        config.websiteDataStore = .default()
        config.setURLSchemeHandler(schemeHandler, forURLScheme: "archie")
        webView = DragWebView(frame: .zero, configuration: config)
        super.init()
        content.add(WeakMessageProxy(self), name: "archie")
        webView.setValue(false, forKey: "drawsBackground")
        webView.underPageBackgroundColor = .clear
        webView.uiDelegate = uiDelegate
        webView.navigationDelegate = self
        webView.onDragStart = { [weak self] in self?.send(["type": "dragging"]) }
        window.contentView = webView
        window.level = keepOnTop ? .floating : .normal
        auth = GoogleAuth(clientID: Bundle.main.object(forInfoDictionaryKey: "ArchieGoogleClientID") as? String, anchor: window)
    }

    func show() {
        if !window.setFrameUsingName("ArchieWidget") { window.center() }
        window.setFrameAutosaveName("ArchieWidget")
        webView.load(URLRequest(url: Settings.pageURL))
        window.makeKeyAndOrderFront(nil)
    }

    func reload() { webView.load(URLRequest(url: Settings.pageURL)) }

    func toggleKeepOnTop() {
        keepOnTop.toggle()
        Settings.keepOnTop = keepOnTop
        window.level = keepOnTop ? .floating : .normal
    }

    func promptForPageAddress() {
        let info = "Paste your published Archie address (for example https://you.github.io/archie/). Leave it empty to use the page built into the app."
        guard let text = WebUIDelegate.ask("Page address", defaultText: Settings.pageAddress ?? "", info: info) else { return }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { Settings.pageAddress = nil }
        else if let url = URL(string: trimmed), url.scheme == "https" { Settings.pageAddress = trimmed }
        else { _ = WebUIDelegate.ask("That address needs to start with https://", defaultText: trimmed); return }
        reload()
    }

    func useBuiltInPage() {
        Settings.pageAddress = nil
        reload()
    }

    func signOut() {
        auth?.signOut()
        send(["type": "signedOut"])
    }

    func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any], let type = body["type"] as? String else { return }
        switch type {
        case "mode": if let mode = Mode(rawValue: body["mode"] as? String ?? "") { resize(to: mode) }
        case "dragArm": webView.dragArmed = true
        case "signIn": signIn(interactive: body["interactive"] as? Bool ?? true)
        case "open":
            if let text = body["url"] as? String, let url = URL(string: text), url.scheme == "https" { NSWorkspace.shared.open(url) }
        default: break
        }
    }

    private func signIn(interactive: Bool) {
        guard let auth else {
            send(["type": "authError", "message": "This copy of the app was built without a Google client ID. See the Mac README to add one."])
            return
        }
        auth.token(interactive: interactive) { [weak self] result in
            switch result {
            case .success(let token):
                self?.send(["type": "token", "access_token": token.accessToken, "expires_in": token.expiresIn, "scope": token.scope])
            case .failure(let error):
                self?.send(["type": "authError", "message": error.localizedDescription])
            }
        }
    }

    /// Keeps the top-left corner in place so the device doesn't jump when the panel opens or closes.
    private func resize(to mode: Mode) {
        var frame = window.frame
        let top = frame.maxY
        frame.size = mode.size
        frame.origin.y = top - mode.size.height
        window.setFrame(frame, display: true, animate: false)
    }

    private func send(_ payload: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: payload),
              let json = String(data: data, encoding: .utf8) else { return }
        webView.evaluateJavaScript("window.ArchieNative && window.ArchieNative.receive(\(json))", completionHandler: nil)
    }
}

/// WebKit keeps a strong hold on message handlers; this breaks the loop back to the controller.
private final class WeakMessageProxy: NSObject, WKScriptMessageHandler {
    private weak var target: WKScriptMessageHandler?
    init(_ target: WKScriptMessageHandler) { self.target = target }
    func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
        target?.userContentController(controller, didReceive: message)
    }
}
