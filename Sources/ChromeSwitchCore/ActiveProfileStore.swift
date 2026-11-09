import Foundation

/// Remembers which profile links should open in. Backed by UserDefaults.
public final class ActiveProfileStore {
    public static let key = "activeProfileDirectory"
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public var activeDirectory: String? {
        get { defaults.string(forKey: Self.key) }
        set { defaults.set(newValue, forKey: Self.key) }
    }

    /// The saved profile if it still exists, otherwise the first available one (or nil when Chrome has none).
    public func resolveActive(from profiles: [ChromeProfile]) -> ChromeProfile? {
        if let dir = activeDirectory, let match = profiles.first(where: { $0.directory == dir }) { return match }
        return profiles.first
    }
}
