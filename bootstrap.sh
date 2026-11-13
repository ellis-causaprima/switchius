#!/bin/bash
# One-paste install for Switchius:
#
#   curl -fsSL https://raw.githubusercontent.com/ellis-causaprima/switchius/main/bootstrap.sh | bash
#
# It checks the Mac, clones the repository, builds the app on this machine and installs it.
# Building locally is the point: macOS only quarantines browser-style downloads, never a
# `git clone`, so the ad-hoc-signed app opens with no Gatekeeper warning and no Apple account.
#
# Everything runs inside main(), called on the last line, so a download cut off halfway
# executes nothing instead of half an installer.
#
# Overrides (all optional):
#   SWITCHIUS_REPO=<url>          install from a fork or a local checkout
#   SWITCHIUS_REF=<tag|branch>    a specific version; default is the newest v* tag, else main
#   SWITCHIUS_DIR=<path>          where the source checkout lives (default ~/.local/share/switchius)
#   SWITCHIUS_INSTALL_DIR=<path>  where the app goes (default /Applications, else ~/Applications)
#   SWITCHIUS_NO_LAUNCH=1         install without starting the app (for headless installs)
set -euo pipefail

REPO="${SWITCHIUS_REPO:-https://github.com/ellis-causaprima/switchius}"
REF="${SWITCHIUS_REF:-}"
DIR="${SWITCHIUS_DIR:-$HOME/.local/share/switchius}"
INSTALL_DIR="${SWITCHIUS_INSTALL_DIR:-}"
NO_LAUNCH="${SWITCHIUS_NO_LAUNCH:-}"

die() { printf '\nswitchius: %s\n' "$*" >&2; exit 1; }
step() { printf '\n▸ %s\n' "$*"; }

require_macos() {
  [ "$(uname -s)" = Darwin ] || die "Switchius is macOS only."
  local major
  major="$(sw_vers -productVersion | cut -d. -f1)"
  [ "${major:-0}" -ge 13 ] || die "Switchius needs macOS 13 or newer; this Mac has $(sw_vers -productVersion)."
}

require_chrome() {
  # Not fatal: Chrome can be installed afterwards. But say it now, not at the first link.
  if ! /usr/bin/mdfind "kMDItemCFBundleIdentifier == 'com.google.Chrome'" 2>/dev/null | grep -q .; then
    echo "  Note: Google Chrome was not found. Switchius opens links in Chrome, so install it too."
  fi
}

# `command -v git` is not enough: without the developer tools, /usr/bin/git and swiftc are stubs
# that pop Apple's installer dialog and fail. Run them and check the exit code instead.
require_toolchain() {
  if git --version >/dev/null 2>&1 && swiftc --version >/dev/null 2>&1; then
    return 0
  fi
  cat >&2 <<'NOCLT'

switchius: Apple's Command Line Tools are not installed yet. Switchius is built on your Mac,
which is what lets it run without security warnings.

Run this, click through the installer that appears (a few minutes), then paste the
Switchius line again:

  xcode-select --install
NOCLT
  exit 1
}

# Package.swift says swift-tools-version 5.9 (Command Line Tools 15 or newer).
require_swift() {
  local full major minor
  full="$(swiftc --version 2>&1 | sed -n 's/.*Swift version \([0-9][0-9.]*\).*/\1/p' | head -1)"
  major="${full%%.*}"
  minor="$(printf '%s' "$full" | cut -d. -f2)"
  if [ "${major:-0}" -gt 5 ] || { [ "${major:-0}" -eq 5 ] && [ "${minor:-0}" -ge 9 ]; }; then
    return 0
  fi
  cat >&2 <<NOSWIFT

switchius: Switchius needs Swift 5.9 or newer, and this Mac has Swift ${full:-(unreadable)}.
Update the Command Line Tools, then paste the Switchius line again:

  sudo rm -rf /Library/Developer/CommandLineTools
  xcode-select --install
NOSWIFT
  exit 1
}

# The newest v* tag, or main when there is none yet.
resolve_ref() {
  [ -n "$REF" ] && return 0
  REF="$(git ls-remote --tags --refs --sort=-v:refname "$REPO" 'v*' 2>/dev/null | head -1 | sed 's|.*/||')"
  if [ -n "$REF" ]; then
    echo "  newest release: $REF"
  else
    REF=main
    echo "  no release tagged yet, installing from main"
  fi
}

fetch() {
  step "Fetching Switchius into $DIR"
  resolve_ref
  if [ -d "$DIR/.git" ]; then
    git -C "$DIR" fetch --quiet --prune --tags --force "$REPO" "+refs/heads/*:refs/remotes/switchius-release/*" ||
      die "could not fetch $REPO. Check the network and try again."
    git -C "$DIR" checkout --quiet "$REF" ||
      die "could not switch $DIR to $REF (git's reason is above). Move $DIR aside and try again."
    # A branch needs fast-forwarding; a tag is already exact.
    if git -C "$DIR" rev-parse --verify --quiet "refs/remotes/switchius-release/$REF" >/dev/null; then
      git -C "$DIR" merge --ff-only --quiet "switchius-release/$REF" 2>/dev/null ||
        die "$DIR has local changes that $REF does not. Move $DIR aside and try again."
    fi
    echo "  updated the existing checkout ($REF)"
  else
    [ -e "$DIR" ] && die "$DIR exists but is not a git checkout. Move it aside and try again."
    mkdir -p "$(dirname "$DIR")"
    # -c advice.detachedHead=false: cloning a tag is meant to be detached; skip git's lecture.
    git -c advice.detachedHead=false clone --quiet --branch "$REF" "$REPO" "$DIR" ||
      die "could not download $REPO ($REF). Check the network and try again."
    echo "  downloaded ($REF)"
  fi
}

# /Applications is writable for admin accounts. A standard account gets ~/Applications instead,
# which works just as well for a default browser and needs no password.
choose_install_dir() {
  if [ -z "$INSTALL_DIR" ]; then
    if [ -w /Applications ]; then INSTALL_DIR=/Applications; else INSTALL_DIR="$HOME/Applications"; fi
  fi
  mkdir -p "$INSTALL_DIR"
}

build_and_install() {
  step "Building and installing into $INSTALL_DIR (about a minute)"
  local launch=1
  [ -n "$NO_LAUNCH" ] && launch=0
  make -C "$DIR" --no-print-directory install INSTALL_DIR="$INSTALL_DIR" LAUNCH="$launch" NOTES=0
}

epilogue() {
  if [ -n "$NO_LAUNCH" ]; then
    cat <<EOF

▸ Installed (not started)

  Start it with:  open "$INSTALL_DIR/Switchius.app"
EOF
  else
    cat <<EOF

▸ One thing left: two clicks

  1. macOS asks whether to make Switchius your default browser. Choose "Use Switchius".
     (Missed it? Click the menu bar picture → "Use Switchius as Default Browser…".)
  2. Click the profile picture in the menu bar and pick the Chrome profile links should open in.

  Then click a link in Slack: it opens in that profile.
EOF
  fi
  cat <<EOF

  Turn on "Launch at Login" in the same menu so it survives a restart.
  Update later by pasting the same line again.
  Uninstall:  make -C "$DIR" uninstall INSTALL_DIR="$INSTALL_DIR"
EOF
}

main() {
  require_macos
  require_toolchain
  require_swift
  require_chrome
  fetch
  choose_install_dir
  build_and_install
  epilogue
}

main "$@"
