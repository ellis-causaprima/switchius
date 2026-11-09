# ChromeSwitch design (2026-11-09)

## Problem

macOS has one default browser. Chrome, when it receives a link from another app, opens it in the
last-used profile. People with a work and a personal profile get links in the wrong place.

## Solution

A menu bar app that *is* the default browser and forwards every link to Chrome with
`--profile-directory=<active>`. The active profile is a single remembered choice, changed from the
menu. Nothing else: no URL rules, no other browsers, no automatic switching.

## Components

| Unit | Responsibility | Depends on |
| --- | --- | --- |
| `ChromeProfileStore` (core) | Parse `Local State` → `[ChromeProfile]`, in Chrome's order; locate cached avatar files | Foundation |
| `ProfileLabels` (core) | Unique menu titles (duplicates get account name / email / directory), truncated bar title | — |
| `ActiveProfileStore` (core) | Remember the chosen directory in UserDefaults; fall back to the first profile if it disappeared | Foundation |
| `ChromeLauncher` (app) | `NSWorkspace.openApplication` on Chrome with `createsNewApplicationInstance` and the profile flag + URLs | AppKit |
| `DefaultBrowser` (app) | Detect / request default-handler status for http and https | AppKit |
| `LoginItem` (app) | `SMAppService` register / unregister | ServiceManagement |
| `Avatars` (app) | Round profile pictures, SF Symbol fallback | AppKit, core |
| `AppDelegate` (app) | Status item, menu built on open, `application(_:open:)` → launcher | all of the above |

## Data flow

1. macOS → `application(_:open: [URL])` (we are the http/https handler).
2. Re-read profiles (cheap, keeps the saved choice honest), resolve the active one.
3. Launch Chrome with `--profile-directory=<dir> <urls…>` as a new instance. Chrome's process
   singleton forwards to the running copy and the helper exits.

## Error handling

- Chrome missing → menu says so; a link triggers an alert.
- `Local State` unreadable → empty profile list, question-mark icon, link still forwarded to Chrome
  without a profile flag (Chrome picks).
- Saved profile deleted → silently fall back to the first profile.
- Default-browser request declined → nothing happens; menu keeps offering it.

## Testing

Core logic has self-contained checks (`make test`). The AppKit layer is verified by hand: install,
`open -a ChromeSwitch https://example.com`, watch the unified log for the forwarding line, check
the tab appears in the chosen profile.

## Packaging

Swift Package + Makefile. No Xcode project: the Command Line Tools build the binary, the Makefile
assembles the bundle (Info.plist declares http/https URL types and `LSUIElement`), draws the
icon, ad-hoc signs, copies to `/Applications`, and registers with Launch Services.
