import Foundation
import ChromeSwitchCore

func runActiveProfileStoreChecks() {
    let profiles = [ChromeProfile(directory: "Default", name: "A"), ChromeProfile(directory: "Profile 2", name: "B")]

    func withDefaults(_ body: (UserDefaults) -> Void) {
        let suite = "ChromeSwitchChecks.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        body(defaults)
        defaults.removePersistentDomain(forName: suite)
    }

    withDefaults { defaults in
        Harness.checkEqual(ActiveProfileStore(defaults: defaults).resolveActive(from: profiles)?.directory, "Default", "unset → first profile")
    }
    withDefaults { defaults in
        let store = ActiveProfileStore(defaults: defaults)
        store.activeDirectory = "Profile 2"
        Harness.checkEqual(store.resolveActive(from: profiles)?.directory, "Profile 2", "saved choice honoured")
        Harness.checkEqual(ActiveProfileStore(defaults: defaults).activeDirectory, "Profile 2", "choice persisted")
    }
    withDefaults { defaults in
        let store = ActiveProfileStore(defaults: defaults)
        store.activeDirectory = "Profile 9"
        Harness.checkEqual(store.resolveActive(from: profiles)?.directory, "Default", "deleted profile → first")
        Harness.check(store.resolveActive(from: []) == nil, "no profiles → nil")
    }
}
