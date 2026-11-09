import AppKit

/// Whether this app is the system's default handler for web links, and how to become it.
enum DefaultBrowser {
    static var isCurrent: Bool {
        guard let probe = URL(string: "https://example.com"),
              let handler = NSWorkspace.shared.urlForApplication(toOpen: probe),
              let handlerID = Bundle(url: handler)?.bundleIdentifier,
              let ownID = Bundle.main.bundleIdentifier else { return false }
        return handlerID == ownID
    }

    /// True when running from a real `.app` bundle (as opposed to `swift run`), which is required
    /// for Launch Services to accept us as a browser.
    static var runsFromBundle: Bool {
        Bundle.main.bundleURL.pathExtension == "app"
    }

    /// Asks macOS to make this app the default for http and https. macOS shows its own
    /// confirmation dialog for the http scheme; https follows without a second prompt.
    static func makeCurrent(completion: @escaping (Error?) -> Void) {
        let app = Bundle.main.bundleURL
        NSWorkspace.shared.setDefaultApplication(at: app, toOpenURLsWithScheme: "http") { error in
            if let error {
                completion(error)
                return
            }
            NSWorkspace.shared.setDefaultApplication(at: app, toOpenURLsWithScheme: "https") { error in
                completion(error)
            }
        }
    }
}
