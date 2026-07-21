# Tempo

A compact Mac menu bar app that tracks work sessions and logs them as events in your Google Calendar.

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/sulakshanas)

---

## Installing

### Homebrew (Recommended)

```bash
brew install --cask bananacoffeecode/tap/tempo
```

### Install Script

Paste this in Terminal. It downloads the latest release, removes the macOS quarantine flag, and moves the app to `/Applications`:

```bash
curl -fsSL https://tempotimetracker.in/install.sh | bash
```

### Manual

1. Download the `.dmg` from the [Releases](../../releases) page
2. Open the `.dmg` and drag **Tempo** into your Applications folder
3. If macOS blocks the app, right-click it → **Open** → **Open**
4. If you still see "Apple could not verify…", go to **System Settings → Privacy & Security**, scroll down and click **Open Anyway**

---

Once installed:

1. Launch Tempo, and it appears in your menu bar
2. Enter your email and click **Continue**
3. Click **Authorize with Google** and sign in with the Google account you want to log sessions to

> **Note:** You may see a "Google hasn't verified this app" warning. Click **Advanced → Go to Tempo (unsafe)** to proceed. This is expected for indie apps that haven't gone through Google's formal review.

---

## Using the app

Refer documentation: https://www.notion.so/sulakshana/How-to-use-33201e573e7c80e7b909ce50fd8dbf64

---

## Security

- Your OAuth tokens are stored locally on your Mac, in the app's preferences (`~/Library/Preferences/tempo.Tempo.plist`)
- The app only requests the `calendar.events` scope, so it can create events but cannot read, modify, or delete existing ones
- Disconnecting from Settings permanently deletes your stored tokens

---

## Releasing a new version

The landing page download button points at `releases/latest/download/Tempo.dmg`, so it always tracks the newest release and needs no changes. The install script fetches the latest release too. Only two things change per release: the GitHub release and the Homebrew cask.

1. Bump `MARKETING_VERSION` (and `CURRENT_PROJECT_VERSION`) in `Tempo.xcodeproj`.
2. Build a universal Release and package the DMG:
   ```bash
   xcodebuild -scheme Tempo -project Tempo.xcodeproj -configuration Release \
     -derivedDataPath build/release ARCHS="arm64 x86_64" ONLY_ACTIVE_ARCH=NO build
   APP=build/release/Build/Products/Release/Tempo.app
   mkdir -p stage && cp -R "$APP" stage/ && ln -s /Applications stage/Applications
   hdiutil create -volname Tempo -srcfolder stage -ov -format UDZO Tempo.dmg
   ```
3. Publish the release. The asset must be named exactly `Tempo.dmg` so the `latest` link resolves:
   ```bash
   gh release create vX.Y.Z Tempo.dmg -R bananacoffeecode/tempo-time-tracker \
     --title "Tempo X.Y.Z" --notes "..."
   ```
4. Update the Homebrew cask in `bananacoffeecode/homebrew-tap` (`Casks/tempo.rb`): set `version` to the new tag and `sha256` to `shasum -a 256 Tempo.dmg`.

The build is unsigned, so first launch relies on the quarantine removal in `scripts/install.sh` or a right-click Open.

---

© 2026 Sulakshana Surya. All rights reserved.

Made with <3 by Sulakshana
