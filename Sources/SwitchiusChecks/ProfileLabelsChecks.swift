import SwitchiusCore

func runProfileLabelsChecks() {
    do {
        let profiles = [ChromeProfile(directory: "Default", name: "Work"), ChromeProfile(directory: "Profile 2", name: "Home")]
        Harness.checkEqual(ProfileLabels.menuTitles(for: profiles), ["Default": "Work", "Profile 2": "Home"], "unique names stay plain")
    }
    do {
        let profiles = [
            ChromeProfile(directory: "Default", name: "acme.com", accountName: "Ada"),
            ChromeProfile(directory: "Profile 2", name: "acme.com", email: "bob@acme.com"),
            ChromeProfile(directory: "Profile 3", name: "acme.com"),
        ]
        Harness.checkEqual(ProfileLabels.menuTitles(for: profiles), [
            "Default": "acme.com (Ada)",
            "Profile 2": "acme.com (bob@acme.com)",
            "Profile 3": "acme.com (Profile 3)",
        ], "duplicates get account, email, then directory")
    }
    do {
        let profiles = [
            ChromeProfile(directory: "Default", name: "Me", accountName: "Ada"),
            ChromeProfile(directory: "Profile 2", name: "Me", accountName: "Ada"),
        ]
        let titles = ProfileLabels.menuTitles(for: profiles)
        Harness.checkEqual(titles["Default"], "Me (Ada)", "same account, first")
        Harness.checkEqual(titles["Profile 2"], "Me (Profile 2)", "same account, second falls back to directory")
    }
    do {
        let long = ChromeProfile(directory: "Default", name: "A very long profile name indeed")
        Harness.checkEqual(ProfileLabels.barTitle(for: long, in: [long]), "A very long profi…", "bar title truncates")
        let short = ChromeProfile(directory: "Default", name: "Work")
        Harness.checkEqual(ProfileLabels.barTitle(for: short, in: [short]), "Work", "bar title short")
    }
}
