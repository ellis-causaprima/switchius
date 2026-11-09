import Foundation

/// App-level switches. The active profile itself lives in `ActiveProfileStore`.
enum Preferences {
    private static let defaults = UserDefaults.standard

    /// Show the profile name next to the picture in the menu bar. Off by default: the picture alone is enough.
    static var showNameInMenuBar: Bool {
        get { defaults.bool(forKey: "showNameInMenuBar") }
        set { defaults.set(newValue, forKey: "showNameInMenuBar") }
    }

    /// Whether we already asked macOS to make us the default browser on a first launch.
    static var didOfferDefaultBrowser: Bool {
        get { defaults.bool(forKey: "didOfferDefaultBrowser") }
        set { defaults.set(newValue, forKey: "didOfferDefaultBrowser") }
    }
}
