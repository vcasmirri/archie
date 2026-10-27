import Foundation

/// Small preferences kept between launches.
enum Settings {
    private static let defaults = UserDefaults.standard

    /// The page the widget shows when no address has been set: the copy bundled inside the app.
    static let builtInURL = URL(string: "archie://app/index.html")!

    static var keepOnTop: Bool {
        get { defaults.bool(forKey: "keepOnTop") }
        set { defaults.set(newValue, forKey: "keepOnTop") }
    }

    /// An https address (for example your GitHub Pages site). Nil means "use the built-in page".
    static var pageAddress: String? {
        get { defaults.string(forKey: "pageAddress") }
        set { defaults.set(newValue, forKey: "pageAddress") }
    }

    static var pageURL: URL {
        if let text = pageAddress, let url = URL(string: text), url.scheme == "https" { return url }
        return builtInURL
    }
}
