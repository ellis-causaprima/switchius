# Switchius

A tiny macOS menu bar app that decides **which Chrome profile external links open in**.

Chrome opens links from other apps (Slack, Mail, calendar invites, …) in whichever profile you
used last. If you juggle a work and a personal profile, that means Ashby, Google Meet and friends
keep landing in the wrong one. Switchius fixes that with a menu bar toggle: pick a profile, and
every link goes there until you pick another.

## How it works

Switchius registers itself as your default browser. macOS hands it every link, and it
immediately re-opens the link in Google Chrome with `--profile-directory=<your choice>`, then
brings Chrome to the front. Chrome's single-instance guard routes the link into the running
Chrome, so it feels instant. The app has no window and no Dock icon; it lives in the menu bar as
the active profile's picture.

Profiles are read live from Chrome's own profile list
(`~/Library/Application Support/Google/Chrome/Local State`), so new or renamed profiles show up
without any configuration.

## Install

Requirements: macOS 13 or newer, Google Chrome, and the Xcode Command Line Tools
(`xcode-select --install`). No Xcode needed.

```bash
git clone <this repo> && cd switchius
make install
```

That builds the app, copies it to `/Applications`, and launches it. On first launch macOS asks
whether to make Switchius your default browser; say yes. (Declined it? The menu has
**Use Switchius as Default Browser…**.) Then click the profile picture in the menu bar and pick
the profile links should open in.

Try it: click a link in Slack. It opens in the chosen profile, and Chrome comes to the front.

Menu options:

- **Show Name in Menu Bar** — adds the profile name next to the picture. Handy when two profiles
  share the same Google picture.
- **Launch at Login** — so Switchius survives a restart.

## Uninstall

```bash
make uninstall
```

Afterwards set a browser again in System Settings → Desktop & Dock → Default web browser.

## Development

```bash
make test     # self-contained checks for the core logic
make app      # build .build/Switchius.app
make install  # build + install + launch
```

Layout:

- `Sources/SwitchiusCore` — pure logic: reading Chrome's profile list, labelling profiles,
  remembering the choice. No AppKit.
- `Sources/Switchius` — the menu bar app: status item, URL handling, Chrome launch and focus,
  default-browser and login-item plumbing.
- `Sources/SwitchiusChecks` — the checks `make test` runs. XCTest is not part of the Command
  Line Tools, so these use a small assertion helper instead.
- `scripts/make-icon.swift` — draws the app icon.

The app is ad-hoc signed. Because you build it yourself, Gatekeeper is happy with that.

## FAQ

**Chrome's Dock icon bounces briefly when I open a link.** That is the short-lived helper process
Chrome uses to pass the link to the running instance. Harmless.

**Two of my profiles have the same name.** The menu appends the Google account name (or email)
so you can tell them apart.

**Can it route by URL (Ashby always to work, YouTube always to personal)?** Not by design; this app
does one thing. If you want rules, look at [Finicky](https://github.com/johnste/finicky).

**Does it work with Chrome Canary, Brave, Edge, Arc?** Not yet. It targets `com.google.Chrome`.

## License

MIT
