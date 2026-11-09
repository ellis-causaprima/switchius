import Foundation

/// One Chrome profile as Chrome describes it in its `Local State` file.
public struct ChromeProfile: Equatable, Hashable, Sendable {
    /// Folder name inside Chrome's user data directory, e.g. `Default` or `Profile 2`.
    /// This is the value Chrome's `--profile-directory` flag expects.
    public let directory: String
    /// The name shown in Chrome's profile menu.
    public let name: String
    /// Display name of the signed-in Google account, if any.
    public let accountName: String?
    /// Email of the signed-in Google account, if any.
    public let email: String?
    /// File name of the cached account picture inside the profile folder, if any.
    public let pictureFileName: String?

    public init(directory: String, name: String, accountName: String? = nil, email: String? = nil, pictureFileName: String? = nil) {
        self.directory = directory
        self.name = name
        self.accountName = accountName
        self.email = email
        self.pictureFileName = pictureFileName
    }
}

public enum ChromeProfileError: Error, Equatable {
    case localStateMissing(URL)
    case malformed
}

/// Reads the profile list out of Chrome's `Local State` JSON file.
public enum ChromeProfileStore {
    public static var defaultUserDataDirectory: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/Google/Chrome", isDirectory: true)
    }

    public static func localStateURL(userDataDirectory: URL = defaultUserDataDirectory) -> URL {
        userDataDirectory.appendingPathComponent("Local State")
    }

    public static func load(userDataDirectory: URL = defaultUserDataDirectory) throws -> [ChromeProfile] {
        let url = localStateURL(userDataDirectory: userDataDirectory)
        guard let data = try? Data(contentsOf: url) else { throw ChromeProfileError.localStateMissing(url) }
        return try parse(localState: data)
    }

    /// Parses the `profile.info_cache` section. Order follows Chrome's own `profiles_order`
    /// when present; otherwise `Default` first, then `Profile N` by number.
    public static func parse(localState data: Data) throws -> [ChromeProfile] {
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let profileSection = root["profile"] as? [String: Any],
              let cache = profileSection["info_cache"] as? [String: Any] else {
            throw ChromeProfileError.malformed
        }

        var byDirectory: [String: ChromeProfile] = [:]
        for (directory, value) in cache {
            guard let info = value as? [String: Any] else { continue }
            byDirectory[directory] = ChromeProfile(
                directory: directory,
                name: nonEmpty(info["name"]) ?? directory,
                accountName: nonEmpty(info["gaia_name"]),
                email: nonEmpty(info["user_name"]),
                pictureFileName: nonEmpty(info["gaia_picture_file_name"])
            )
        }

        var ordered: [ChromeProfile] = []
        if let order = profileSection["profiles_order"] as? [String] {
            for directory in order {
                if let profile = byDirectory.removeValue(forKey: directory) { ordered.append(profile) }
            }
        }
        ordered.append(contentsOf: byDirectory.values.sorted(by: directoryOrder))
        return ordered
    }

    /// Where Chrome caches the account picture for a profile, if it has one on disk.
    public static func pictureURL(for profile: ChromeProfile, userDataDirectory: URL = defaultUserDataDirectory) -> URL? {
        guard let file = profile.pictureFileName else { return nil }
        let url = userDataDirectory.appendingPathComponent(profile.directory).appendingPathComponent(file)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    private static func nonEmpty(_ value: Any?) -> String? {
        guard let s = value as? String, !s.isEmpty else { return nil }
        return s
    }

    /// `Default` first, then `Profile 1`, `Profile 2`, … numerically, then anything else alphabetically.
    static func directoryOrder(_ a: ChromeProfile, _ b: ChromeProfile) -> Bool {
        func rank(_ d: String) -> (Int, Int, String) {
            if d == "Default" { return (0, 0, d) }
            if d.hasPrefix("Profile "), let n = Int(d.dropFirst("Profile ".count)) { return (1, n, d) }
            return (2, 0, d)
        }
        return rank(a.directory) < rank(b.directory)
    }
}
