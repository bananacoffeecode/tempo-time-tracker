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

Paste this in Terminal — downloads the latest release, removes the macOS quarantine flag, and moves the app to `/Applications`:

```bash
curl -fsSL https://raw.githubusercontent.com/bananacoffeecode/tempo-time-tracker/main/scripts/install.sh | bash
```

### Manual

1. Download the `.dmg` from the [Releases](../../releases) page
2. Open the `.dmg` and drag **Tempo** into your Applications folder
3. If macOS blocks the app, right-click it → **Open** → **Open**
4. If you still see "Apple could not verify…", go to **System Settings → Privacy & Security**, scroll down and click **Open Anyway**

---

Once installed:

1. Launch Tempo — it appears in your menu bar
2. Enter your email and click **Continue**
3. Click **Authorize with Google** and sign in with the Google account you want to log sessions to

> **Note:** You may see a "Google hasn't verified this app" warning. Click **Advanced → Go to Tempo (unsafe)** to proceed. This is expected for indie apps that haven't gone through Google's formal review.

---

## Using the app

Refer documentation: https://www.notion.so/sulakshana/How-to-use-33201e573e7c80e7b909ce50fd8dbf64

---

## Security

- Your OAuth tokens are stored locally on your Mac in `~/Library/Application Support/time-tracker/`
- The app only requests the `calendar.events` scope — it can create events but cannot read, modify, or delete existing ones
- Disconnecting from Settings permanently deletes your stored tokens

---

© 2026 Sulakshana Surya. All rights reserved.

Made with <3 by Sulakshana
