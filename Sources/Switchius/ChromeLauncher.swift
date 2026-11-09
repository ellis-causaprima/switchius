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

    /// The Chrome that is already running, if any.
    static var runningChrome: NSRunningApplication? {
        NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier).first { !$0.isTerminated }
    }

    /// Launches a fresh Chrome process with the profile flag and the URLs as arguments.
    /// When Chrome is already running, its single-instance guard forwards the arguments to the
    /// running copy and the extra process exits, so the link lands in the right profile either way.
    /// Because that helper exits at once, we also bring the running Chrome to the front ourselves.
    static func open(_ urls: [URL], profileDirectory: String?, completion: @escaping (Error?) -> Void) {
        guard let chrome = chromeURL else {
            completion(LaunchError.chromeNotInstalled)
            return
        }
        let alreadyRunning = runningChrome
        let configuration = NSWorkspace.OpenConfiguration()
        var arguments: [String] = []
        if let profileDirectory {
            arguments.append("--profile-directory=\(profileDirectory)")
        }
        arguments.append(contentsOf: urls.map(\.absoluteString))
        configuration.arguments = arguments
        configuration.createsNewApplicationInstance = true
        configuration.activates = alreadyRunning == nil
        NSWorkspace.shared.openApplication(at: chrome, configuration: configuration) { _, error in
            if error == nil, let alreadyRunning {
                DispatchQueue.main.async { bringToFront(alreadyRunning) }
            }
            completion(error)
        }
    }

    /// Hands our activation to Chrome. We were just activated by macOS to handle the link,
    /// which is what lets us pass the focus on (macOS 14+ cooperative activation).
    static func bringToFront(_ chrome: NSRunningApplication) {
        if #available(macOS 14.0, *) {
            NSApp.yieldActivation(to: chrome)
            chrome.activate(from: .current, options: [])
        } else {
            chrome.activate(options: [.activateIgnoringOtherApps])
        }
    }
}
