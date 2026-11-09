import AppKit
import SwitchiusCore
import os

/// Owns the status item and reacts to the two things that happen: a profile gets picked, or a link arrives.
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let log = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Switchius", category: "app")
    private let store = ActiveProfileStore()
    private let menu = NSMenu()
    private var statusItem: NSStatusItem!
    private var profiles: [ChromeProfile] = []

    // MARK: NSApplicationDelegate

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        menu.delegate = self
        menu.autoenablesItems = true
        statusItem.menu = menu
        reloadProfiles()
        refreshStatusItem()
        offerDefaultBrowserOnFirstLaunch()
    }

    /// Called by macOS for every link (and HTML file) we are the default handler for.
    func application(_ application: NSApplication, open urls: [URL]) {
        reloadProfiles()
        let profile = store.resolveActive(from: profiles)
        log.info("Forwarding \(urls.count, privacy: .public) URL(s) to profile \(profile?.directory ?? "none", privacy: .public)")
        ChromeLauncher.open(urls, profileDirectory: profile?.directory) { [weak self] error in
            guard let error else { return }
            self?.log.error("Chrome launch failed: \(error.localizedDescription, privacy: .public)")
            DispatchQueue.main.async { self?.showError("Could not open the link in Chrome", error) }
        }
    }

    // MARK: Profiles

    private func reloadProfiles() {
        do {
            profiles = try ChromeProfileStore.load()
        } catch {
            log.error("Could not read Chrome profiles: \(error.localizedDescription, privacy: .public)")
            profiles = []
        }
    }

    private func refreshStatusItem() {
        guard let button = statusItem.button else { return }
        if let active = store.resolveActive(from: profiles) {
            let fullTitle = ProfileLabels.menuTitles(for: profiles)[active.directory] ?? active.name
            button.image = Avatars.image(for: active, diameter: 18)
            button.title = Preferences.showNameInMenuBar ? " " + ProfileLabels.barTitle(for: active, in: profiles) : ""
            button.toolTip = "Links open in Chrome profile “\(fullTitle)”"
        } else {
            button.image = NSImage(systemSymbolName: "questionmark.circle", accessibilityDescription: "No Chrome profiles")
            button.title = ""
            button.toolTip = "No Chrome profiles found"
        }
        button.imagePosition = .imageLeft
    }

    // MARK: Menu

    func menuNeedsUpdate(_ menu: NSMenu) {
        reloadProfiles()
        refreshStatusItem()
        menu.removeAllItems()

        menu.addItem(disabledItem("Open links in"))
        if profiles.isEmpty {
            menu.addItem(disabledItem(ChromeLauncher.chromeURL == nil ? "Google Chrome is not installed" : "No Chrome profiles found"))
        } else {
            let titles = ProfileLabels.menuTitles(for: profiles)
            let active = store.resolveActive(from: profiles)
            for profile in profiles {
                let item = NSMenuItem(title: titles[profile.directory] ?? profile.name, action: #selector(selectProfile(_:)), keyEquivalent: "")
                item.target = self
                item.representedObject = profile.directory
                item.image = Avatars.image(for: profile, diameter: 16)
                item.state = profile == active ? .on : .off
                menu.addItem(item)
            }
        }

        menu.addItem(.separator())
        if !DefaultBrowser.runsFromBundle {
            menu.addItem(disabledItem("Run the .app bundle to use as default browser"))
        } else if DefaultBrowser.isCurrent {
            menu.addItem(disabledItem("Switchius is your default browser"))
        } else {
            menu.addItem(actionItem("Use Switchius as Default Browser…", #selector(makeDefaultBrowser)))
        }

        let showName = actionItem("Show Name in Menu Bar", #selector(toggleShowName))
        showName.state = Preferences.showNameInMenuBar ? .on : .off
        menu.addItem(showName)

        let login = actionItem("Launch at Login", #selector(toggleLoginItem))
        login.state = LoginItem.isEnabled ? .on : .off
        menu.addItem(login)

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit Switchius", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
    }

    private func disabledItem(_ title: String) -> NSMenuItem {
        // With autoenablesItems on, an item without an action stays disabled.
        NSMenuItem(title: title, action: nil, keyEquivalent: "")
    }

    private func actionItem(_ title: String, _ action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        return item
    }

    // MARK: Actions

    @objc private func selectProfile(_ sender: NSMenuItem) {
        guard let directory = sender.representedObject as? String else { return }
        store.activeDirectory = directory
        log.info("Active profile set to \(directory, privacy: .public)")
        refreshStatusItem()
    }

    @objc private func toggleShowName() {
        Preferences.showNameInMenuBar.toggle()
        refreshStatusItem()
    }

    /// On the very first launch from a bundle, ask macOS straight away. The user can decline; we don't ask again.
    private func offerDefaultBrowserOnFirstLaunch() {
        guard DefaultBrowser.runsFromBundle, !DefaultBrowser.isCurrent, !Preferences.didOfferDefaultBrowser else { return }
        Preferences.didOfferDefaultBrowser = true
        makeDefaultBrowser()
    }

    @objc private func makeDefaultBrowser() {
        DefaultBrowser.makeCurrent { [weak self] error in
            DispatchQueue.main.async {
                if let error {
                    // The user declining the system dialog also lands here; not worth an alert.
                    self?.log.notice("Default browser not changed: \(error.localizedDescription, privacy: .public)")
                }
                self?.refreshStatusItem()
            }
        }
    }

    @objc private func toggleLoginItem() {
        do {
            try LoginItem.setEnabled(!LoginItem.isEnabled)
        } catch {
            showError("Could not change the login item", error)
        }
    }

    private func showError(_ title: String, _ error: Error) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = title
        alert.informativeText = error.localizedDescription
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }
}
