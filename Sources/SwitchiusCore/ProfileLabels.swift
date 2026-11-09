import Foundation

/// Human-facing names for profiles, kept unique so two profiles called the same thing stay tellable apart.
public enum ProfileLabels {
    /// Menu titles keyed by profile directory. Duplicated names get the account name (or email,
    /// or the directory) appended in parentheses.
    public static func menuTitles(for profiles: [ChromeProfile]) -> [String: String] {
        var countByName: [String: Int] = [:]
        for p in profiles { countByName[p.name, default: 0] += 1 }

        var titles: [String: String] = [:]
        var seen: Set<String> = []
        for p in profiles {
            var title = p.name
            if countByName[p.name, default: 0] > 1 {
                title = "\(p.name) (\(p.accountName ?? p.email ?? p.directory))"
            }
            if seen.contains(title) { title = "\(p.name) (\(p.directory))" }
            seen.insert(title)
            titles[p.directory] = title
        }
        return titles
    }

    /// Short text for the menu bar: the menu title, truncated so it does not crowd the bar.
    public static func barTitle(for profile: ChromeProfile, in profiles: [ChromeProfile], maxLength: Int = 18) -> String {
        let title = menuTitles(for: profiles)[profile.directory] ?? profile.name
        guard title.count > maxLength else { return title }
        return String(title.prefix(maxLength - 1)).trimmingCharacters(in: .whitespaces) + "…"
    }
}
