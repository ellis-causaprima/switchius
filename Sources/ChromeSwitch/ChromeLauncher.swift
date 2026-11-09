import AppKit

/// Opens URLs in Google Chrome, pinned to one profile via `--profile-directory`.
enum ChromeLauncher {
    static let bundleIdentifier = "com.google.Chrome"

    enum LaunchError: LocalizedError {
        case chromeNotInstalled
        var errorDescription: String? { "Google Chrome is not installed (bundle id \(ChromeLauncher.bundleIdentifier) not found)." }
    }

    static var chromeURL: URL? {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier)
    }

    /// Launches a fresh Chrome process with the profile flag and the URLs as arguments.
    /// When Chrome is already running, its single-instance guard forwards the arguments to the
    /// running copy and the extra process exits, so the link lands in the right profile either way.
    static func open(_ urls: [URL], profileDirectory: String?, completion: @escaping (Error?) -> Void) {
        guard let chrome = chromeURL else {
            completion(LaunchError.chromeNotInstalled)
            return
        }
        let configuration = NSWorkspace.OpenConfiguration()
        var arguments: [String] = []
        if let profileDirectory {
            arguments.append("--profile-directory=\(profileDirectory)")
        }
        arguments.append(contentsOf: urls.map(\.absoluteString))
        configuration.arguments = arguments
        configuration.createsNewApplicationInstance = true
        configuration.activates = true
        NSWorkspace.shared.openApplication(at: chrome, configuration: configuration) { _, error in
            completion(error)
        }
    }
}
