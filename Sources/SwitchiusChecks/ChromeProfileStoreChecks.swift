import Foundation
import SwitchiusCore

private func localState(_ infoCache: String, extra: String = "") -> Data {
    """
    {"profile": {"info_cache": {\(infoCache)} \(extra), "last_used": "Default"}, "other": 1}
    """.data(using: .utf8)!
}

private func tempDir() -> URL {
    URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
}

func runChromeProfileStoreChecks() throws {
    // Parses fields and orders Default first, then numerically.
    do {
        let data = localState("""
            "Profile 10": {"name": "Ten"},
            "Profile 2": {"name": "Work", "gaia_name": "Ada Lovelace", "user_name": "ada@example.com", "gaia_picture_file_name": "Google Profile Picture.png"},
            "Default": {"name": "Personal"}
        """)
        let profiles = try ChromeProfileStore.parse(localState: data)
        Harness.checkEqual(profiles.map(\.directory), ["Default", "Profile 2", "Profile 10"], "fallback order")
        let work = profiles[1]
        Harness.checkEqual(work.name, "Work", "name")
        Harness.checkEqual(work.accountName, "Ada Lovelace", "accountName")
        Harness.checkEqual(work.email, "ada@example.com", "email")
        Harness.checkEqual(work.pictureFileName, "Google Profile Picture.png", "pictureFileName")
        Harness.check(profiles[0].accountName == nil, "missing gaia_name is nil")
    }

    // Honours Chrome's own profiles_order and appends unlisted profiles.
    do {
        let data = localState("""
            "Default": {"name": "A"}, "Profile 2": {"name": "B"}, "Profile 3": {"name": "C"}
        """, extra: ", \"profiles_order\": [\"Profile 3\", \"Default\"]")
        let profiles = try ChromeProfileStore.parse(localState: data)
        Harness.checkEqual(profiles.map(\.directory), ["Profile 3", "Default", "Profile 2"], "profiles_order")
    }

    // Empty strings become nil; a missing name falls back to the directory.
    do {
        let data = localState("\"Profile 1\": {\"gaia_name\": \"\", \"user_name\": \"\"}")
        let profiles = try ChromeProfileStore.parse(localState: data)
        Harness.checkEqual(profiles, [ChromeProfile(directory: "Profile 1", name: "Profile 1")], "empty fields")
    }

    Harness.checkThrows(ChromeProfileError.malformed, "malformed JSON") {
        _ = try ChromeProfileStore.parse(localState: Data("{}".utf8))
    }

    do {
        let dir = tempDir()
        Harness.checkThrows(ChromeProfileError.localStateMissing(dir.appendingPathComponent("Local State")), "missing Local State") {
            _ = try ChromeProfileStore.load(userDataDirectory: dir)
        }
    }

    // Picture URL only when the file exists.
    do {
        let dir = tempDir()
        try FileManager.default.createDirectory(at: dir.appendingPathComponent("Default"), withIntermediateDirectories: true)
        let profile = ChromeProfile(directory: "Default", name: "X", pictureFileName: "pic.png")
        Harness.check(ChromeProfileStore.pictureURL(for: profile, userDataDirectory: dir) == nil, "no picture file → nil")
        try Data().write(to: dir.appendingPathComponent("Default/pic.png"))
        Harness.checkEqual(ChromeProfileStore.pictureURL(for: profile, userDataDirectory: dir), dir.appendingPathComponent("Default/pic.png"), "picture url")
    }
}
