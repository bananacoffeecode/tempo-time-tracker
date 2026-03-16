# Tempo

A compact Mac menu bar app that tracks work sessions and logs them as events in your Google Calendar.

---

## For Users — Downloading the App

### Requirements
- macOS (Apple Silicon or Intel)
- A Google account

### Steps

1. **Download** the `.dmg` file from the [Releases](../../releases) page
2. **Open** the `.dmg` and drag **Tempo** into your Applications folder
3. **Launch** the app — a clock icon appears in your menu bar
4. **Enter your email** on the first screen and click Continue
5. **Click "Authorize with Google"** — your browser opens Google's sign-in page
6. **Sign in** with the Google account whose calendar you want to log sessions to
7. Once authorized, the app is ready to use

> **Note:** You may see a warning that says "Google hasn't verified this app." This is expected — click **Advanced → Go to Tempo (unsafe)** to proceed. This warning appears because the app hasn't gone through Google's formal verification process. Your data is only used to create calendar events on your own account.

### Using the App

- Click the **menu bar icon** to show or hide the widget
- Type a **session name**, pick a **color**, then click **START**
- Click **DONE** when your session is finished — the event is instantly logged to your Google Calendar
- Click the **trash icon** next to DONE to discard a session without logging it
- Click the **gear icon** to open Settings, where you can disconnect your Google account

---

## For Developers — Building from Source

### Requirements
- Node.js v18+ (install via [nvm](https://github.com/nvm-sh/nvm))
- A Google Cloud project with the Calendar API enabled

### 1. Clone the repo

```bash
git clone https://github.com/bananacoffeecode/tempo.git
cd tempo
npm install
```

### 2. Set up Google Cloud credentials

The app uses OAuth 2.0 to access Google Calendar. You need your own credentials to build and run it.

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create a new project (e.g. `Tempo`)
3. Go to **APIs & Services → Library** → search **Google Calendar API** → Enable
4. Go to **APIs & Services → OAuth consent screen**
   - User type: **External**
   - Fill in app name, support email
   - Add scope: `https://www.googleapis.com/auth/calendar.events`
   - Add your Google account as a **test user**
5. Go to **APIs & Services → Credentials → Create Credentials → OAuth client ID**
   - Application type: **Desktop app**
   - Name: `Tempo`
6. Copy the **Client ID** and **Client Secret**

### 3. Create credentials.json

Create a file called `credentials.json` in the project root (this file is gitignored and will never be committed):

```json
{
  "client_id": "YOUR_CLIENT_ID.apps.googleusercontent.com",
  "client_secret": "YOUR_CLIENT_SECRET"
}
```

### 4. Run in development

```bash
npm start
```

### 5. Build the DMG

```bash
npm run build
```

The `.dmg` installer is output to `dist/`. The `credentials.json` file is automatically bundled inside the app — it is **not** included in the source code on GitHub.

To build for a specific architecture:

```bash
npm run build:arm64   # Apple Silicon
npm run build:x64     # Intel
```

---

## Security Notes

- `credentials.json` is listed in `.gitignore` and is **never committed to this repository**
- Your OAuth tokens (access + refresh) are stored locally on your machine in `~/Library/Application Support/time-tracker/`
- The app only requests the `calendar.events` scope — it can create events but cannot read, modify, or delete existing ones
- Disconnecting from Settings deletes both the stored tokens and your email from local storage

---

## Google Calendar Event Colors

| Color | Name |
|-------|------|
| 🟣 | Lavender |
| 🟢 | Sage |
| 🟣 | Grape |
| 🩷 | Flamingo |
| 🟡 | Banana |
| 🟠 | Tangerine |
| 🔵 | Peacock |
| ⚫ | Graphite |
| 🔵 | Blueberry |
| 🟢 | Basil |
| 🔴 | Tomato |

---

© 2026 Sulakshana Surya. All rights reserved.

Made with &lt;3 by Sulakshana
