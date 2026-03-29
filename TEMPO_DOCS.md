# Tempo — How It Works

Tempo is a Mac menu bar app that tracks your work sessions and logs them directly to Google Calendar. No manual calendar entry. No spreadsheets. You start a timer, work, stop — and Tempo handles the rest.

---

## Table of Contents

1. [Getting Started](#getting-started)
2. [The Widget](#the-widget)
3. [Tracking a Session](#tracking-a-session)
4. [Reviewing & Logging to Calendar](#reviewing--logging-to-calendar)
5. [Logging a Past Event](#logging-a-past-event)
6. [Collapsed Mode](#collapsed-mode)
7. [Settings](#settings)
8. [Installing Tempo](#installing-tempo)

---

## Getting Started

When you open Tempo for the first time, you'll see a brief onboarding screen.

> 📸 **[ADD IMAGE: onboarding screen — icon, "Tempo" title, email input, Continue button]**

**Step 1 — Enter your email**
Type the Google account email you want to connect to. This is only used to identify your account.

**Step 2 — Authorize Google Calendar**
Tempo will open your browser and ask for permission to create calendar events. It only requests write access to calendar events — nothing else is read.

Once connected, the widget opens and you're ready to track.

---

## The Widget

Tempo lives in your menu bar. Click the tray icon to open the widget. The widget is 320px wide and floats above other windows so it's always accessible.

> 📸 **[ADD IMAGE: main widget in idle state — timer at 00:00:00, "Work session" placeholder, color picker, Start + Log an event buttons]**

### Elements

| Element | Description |
|---|---|
| **Timer** | Large serif display showing elapsed time (HH:MM:SS). Shows `00:00:00` when idle. |
| **Session title** | Text input. Type a name for your session before or after starting. Defaults to "Work session" if left blank. |
| **Color picker** | 11 Google Calendar colors. The selected color is used when the event is logged. |
| **Start** | Begins tracking time. |
| **Log an event** | Opens the review panel directly without starting a timer — for logging something you already did. |
| **Settings** | Gear icon in the title bar — opens settings. |
| **Collapse** | Collapses the widget to a minimal pill. |
| **Close** | Hides the widget back to the menu bar. |

The widget can be dragged to any position on screen by clicking and dragging on the title bar area.

---

## Tracking a Session

> 📸 **[ADD IMAGE: widget in running state — timer counting, session name filled, Done + Adjust + discard buttons visible]**

**1. (Optional) Name your session**
Click the title input and type a name — e.g. "Deep work", "Design sprint", "Client call". Text is lowercased automatically.

**2. (Optional) Pick a color**
Click one of the 11 color dots. The selected dot shows a green ring. This color will appear on the Google Calendar event.

**3. Click Start**
The timer begins counting. The session title input locks. Buttons switch to **Done**, **Adjust**, and a discard button.

**4. Work**
The tray icon in the menu bar updates with your session name and elapsed time while the session is running.

**5. When you're done, click Done**
The timer stops and the review panel opens.

---

## Reviewing & Logging to Calendar

After clicking Done, the review panel slides in. Here you can verify or adjust the session before it's logged.

> 📸 **[ADD IMAGE: review panel — Start/End time pickers, session name input, color picker, Log to Calendar button]**

### What you can change

**Start time / End time**
Two time pickers show the exact start and end of your session. Tap either to adjust — useful if you forgot to start the timer on time, or worked longer than you tracked.

**Session name**
The name is pre-filled from whatever you typed before starting. You can change it here.

**Color**
Change the calendar color if needed.

### Logging

Click **Log to Calendar** to create the event. Tempo sends the event directly to your connected Google Calendar.

> 📸 **[ADD IMAGE: flash/confetti screen — green background, checkmark, "Logged to calendar" text with confetti dots]**

After logging, a green confirmation screen plays briefly with a checkmark and confetti. The widget resets to idle.

**Discard**
If you don't want to log the session, click the trash icon in the review panel. The session is dropped without creating a calendar event.

---

## Logging a Past Event

You don't need to run the timer to log something to your calendar.

Click **Log an event** (next to the Start button on the idle screen). The review panel opens immediately with a default window of the past hour. Adjust the start and end times to match what you actually did, fill in a name and color, then log it.

> 📸 **[ADD IMAGE: review panel opened via "Log an event" — time pickers, empty name input, color picker]**

---

## Collapsed Mode

Click the collapse icon in the title bar to shrink the widget to a minimal pill — 56px tall.

> 📸 **[ADD IMAGE: collapsed pill — session name on left, timer in Crimson Text, stop button on right]**

In collapsed mode:

- **Idle** — shows "READY" and a **START** button
- **Running** — shows the session name, live timer (in italic serif), and a stop button

Click anywhere on the pill to expand back to the full widget. Click the stop button to end the session and open the review panel.

---

## Settings

Click the gear icon in the title bar to open settings.

> 📸 **[ADD IMAGE: settings panel — Google Calendar section showing connected email, Logout button]**

**Google Calendar**
Shows the email address currently connected. This is a read-only display.

**Logout**
Disconnects your Google Calendar. Tokens are deleted locally. The next time you open Tempo, you'll be taken back to the onboarding screen to reconnect.

---

## Installing Tempo

Tempo is unsigned (no Apple Developer account), so depending on how you install it you may need to allow it through macOS Gatekeeper.

### Option 1 — cURL (recommended, bypasses Gatekeeper automatically)

```bash
curl -fsSL https://raw.githubusercontent.com/bananacoffeecode/tempo-time-tracker/main/scripts/install.sh | bash
```

### Option 2 — Homebrew

```bash
brew install --cask bananacoffeecode/tap/tempo
```

### Option 3 — Manual DMG

1. Download the `.dmg` from [GitHub Releases](https://github.com/bananacoffeecode/tempo-time-tracker/releases)
2. Open the DMG and drag Tempo to Applications
3. On first launch, go to **System Settings → Privacy & Security** and click **Open Anyway**

> 📸 **[ADD IMAGE: macOS Privacy & Security panel showing "Open Anyway" for Tempo — optional but helpful for the manual install flow]**

---

## How events appear in Google Calendar

Each logged session becomes a standard Google Calendar event with:
- The session name as the event title
- The exact start and end time you tracked (or adjusted in the review panel)
- The color you selected (mapped to the 11 standard Google Calendar event colors)

> 📸 **[ADD IMAGE: Google Calendar showing a logged Tempo event — title, time, color visible]**

Events are created in your **primary calendar** by default.

---

*Built with Electron, googleapis, and vanilla JS. macOS 12+.*
