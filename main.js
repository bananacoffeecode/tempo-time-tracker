const { app, BrowserWindow, Tray, nativeImage, ipcMain, screen, Menu, shell } = require('electron');
const path = require('path');
const { hasValidToken, startOAuthFlow, exchangeManualCode, loadCredentials,
        getUserEmail, setUserEmail, revokeToken } = require('./auth');
const { createEvent } = require('./calendar');

// Prevent multiple instances
if (!app.requestSingleInstanceLock()) {
  app.quit();
}


let tray = null;
let win = null;
let isQuitting = false;
let sessionStart = null;
let sessionColorId = 7;
let sessionName = '';
let trayInterval = null;
let settingsStore;

function createWindow() {
  win = new BrowserWindow({
    width: 320,
    height: 480,
    show: false,
    frame: false,
    alwaysOnTop: true,
    resizable: false,
    skipTaskbar: true,
    transparent: true,
    hasShadow: true,
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      contextIsolation: true,
      nodeIntegration: false,
    },
  });

  win.setAlwaysOnTop(true, 'floating');
  win.setVisibleOnAllWorkspaces(true, { visibleOnFullScreen: true });

  win.loadFile(path.join(__dirname, 'renderer', 'index.html'));

  win.on('blur', () => {
    // Keep visible if a session is running
    if (!sessionStart) {
      // win.hide(); // Uncomment to auto-hide on blur
    }
  });

  // Hide instead of destroy when close is requested from renderer
  win.on('close', (e) => {
    if (!isQuitting && !win.isDestroyed()) {
      e.preventDefault();
      win.hide();
    }
  });
}

function formatTrayTime(seconds) {
  const h = Math.floor(seconds / 3600).toString().padStart(2, '0');
  const m = Math.floor((seconds % 3600) / 60).toString().padStart(2, '0');
  const s = (seconds % 60).toString().padStart(2, '0');
  return `${h}:${m}:${s}`;
}

function getSettingsStore() {
  if (!settingsStore) {
    const Store = require('electron-store');
    settingsStore = new Store({ name: 'app-settings' });
  }
  return settingsStore;
}

function createTray() {
  const iconPath = path.join(__dirname, 'assets', 'tray-icon.png');
  let icon = nativeImage.createFromPath(iconPath);
  if (icon.isEmpty()) {
    icon = nativeImage.createFromPath(path.join(__dirname, 'assets', 'tray-icon@2x.png'));
  }
  icon.setTemplateImage(true);
  tray = new Tray(icon);
  tray.setToolTip('Tempo');

  tray.on('click', () => {
    if (!win || win.isDestroyed()) return;
    if (win.isVisible()) {
      win.webContents.send('tray-click-hide');
      return;
    }
    const store = getSettingsStore();
    const savedX = store.get('windowX');
    const savedY = store.get('windowY');
    if (savedX !== undefined && savedY !== undefined) {
      win.setPosition(savedX, savedY, false);
    } else {
      positionWindow();
    }
    win.webContents.send('window-will-show');
    win.show();
    win.focus();
  });
}

function positionWindow() {
  if (!win || win.isDestroyed()) return;
  const trayBounds = tray.getBounds();
  const display = screen.getPrimaryDisplay();
  const { workArea } = display;
  const winWidth = 320;

  let x = Math.round(trayBounds.x + trayBounds.width / 2 - winWidth / 2);
  let y = Math.round(trayBounds.y + trayBounds.height + 4);

  // Keep within screen bounds
  x = Math.max(workArea.x, Math.min(x, workArea.x + workArea.width - winWidth));

  win.setPosition(x, y, false);
}

ipcMain.handle('set-window-size', (e, { width, height }) => {
  win.setSize(width, height, true);
});

ipcMain.on('move-window-by', (e, { dx, dy }) => {
  const [x, y] = win.getPosition();
  win.setPosition(x + dx, y + dy, false);
});

ipcMain.handle('hide-window', () => {
  const [x, y] = win.getPosition();
  const store = getSettingsStore();
  store.set('windowX', x);
  store.set('windowY', y);
  win.hide();
});

ipcMain.handle('discard-session', () => {
  if (trayInterval) { clearInterval(trayInterval); trayInterval = null; }
  tray.setTitle('');
  sessionStart = null;
  sessionName = '';
});

// IPC Handlers
ipcMain.handle('auth-status', () => {
  const hasCreds = !!loadCredentials();
  const hasToken = hasValidToken();
  return { hasCreds, hasToken };
});

ipcMain.handle('start-auth', async (event) => {
  try {
    await startOAuthFlow({
      onUrl: (url) => event.sender.send('auth-url', url),
    });
    event.sender.send('auth-complete', { success: true });
    return { success: true };
  } catch (err) {
    event.sender.send('auth-error', err.message);
    return { success: false, error: err.message };
  }
});

ipcMain.handle('get-profile', () => ({
  email:    getUserEmail(),
  hasCreds: !!loadCredentials(),
  hasToken: hasValidToken(),
}));
ipcMain.handle('save-email', (e, email) => { setUserEmail(email); return { success: true }; });
ipcMain.handle('disconnect-calendar', async () => { await revokeToken(); return { success: true }; });

ipcMain.handle('exchange-manual-code', async (e, code) => {
  try {
    await exchangeManualCode(code);
    return { success: true };
  } catch (err) {
    return { success: false, error: err.message };
  }
});
ipcMain.handle('quit-app', () => { isQuitting = true; app.quit(); });

function buildAppMenu() {
  return Menu.buildFromTemplate([
    { label: 'Website', click: () => shell.openExternal('https://tempo-time-tracker-1.vercel.app/') },
    { type: 'separator' },
    { label: 'Privacy Policy',  click: () => shell.openExternal('https://tempo-time-tracker-1.vercel.app/privacy-policy.html') },
    { label: 'Documentation',   click: () => shell.openExternal('https://www.notion.so/sulakshana/Tempo-32501e573e7c80018529cc40f57252f1') },
    { label: 'Support',         click: () => shell.openExternal('https://ko-fi.com/sulakshanas') },
    { label: 'Feedback',        click: () => shell.openExternal('mailto:sulakshanasurya@gmail.com?subject=Tempo%20Feedback') },
    { type: 'separator' },
    { label: 'Quit Tempo', click: () => { isQuitting = true; app.quit(); } },
  ]);
}

ipcMain.handle('show-onboard-menu',   (e) => { buildAppMenu().popup({ window: BrowserWindow.fromWebContents(e.sender) }); });
ipcMain.handle('show-settings-menu',  (e) => { buildAppMenu().popup({ window: BrowserWindow.fromWebContents(e.sender) }); });

ipcMain.handle('start-session', (event, { name, colorId }) => {
  sessionStart = new Date();
  sessionName = name;
  sessionColorId = colorId;
  if (trayInterval) clearInterval(trayInterval);
  trayInterval = setInterval(() => {
    if (!tray || tray.isDestroyed()) { clearInterval(trayInterval); trayInterval = null; return; }
    const elapsed = Math.floor((Date.now() - sessionStart.getTime()) / 1000);
    tray.setTitle(` ${formatTrayTime(elapsed)}`);
  }, 100);
  return { started: true, time: sessionStart.toISOString() };
});

ipcMain.handle('prepare-stop', () => {
  if (!sessionStart) return { error: 'No active session' };
  if (trayInterval) { clearInterval(trayInterval); trayInterval = null; }
  tray.setTitle('');
  const startISO = sessionStart.toISOString();
  const endISO   = new Date().toISOString();
  const name     = sessionName;
  const colorId  = sessionColorId;
  sessionStart = null; sessionName = ''; sessionColorId = 7;
  return { startISO, endISO, name, colorId };
});

ipcMain.handle('log-session', async (e, { startISO, endISO, name, colorId }) => {
  try {
    const event = await createEvent({
      title: name || 'Work Session',
      startTime: new Date(startISO),
      endTime:   new Date(endISO),
      colorId,
    });
    return { success: true, eventId: event.id, htmlLink: event.htmlLink };
  } catch (err) {
    console.error('Calendar error:', err.message);
    const detail = err.response?.data?.error?.message || err.message;
    return { success: false, error: detail };
  }
});

ipcMain.handle('get-settings', () => {
  const store = getSettingsStore();
  return { defaultSessionName: store.get('defaultSessionName', 'work session') };
});

ipcMain.handle('save-settings', (e, { defaultSessionName }) => {
  const store = getSettingsStore();
  store.set('defaultSessionName', defaultSessionName);
  return { success: true };
});

app.whenReady().then(() => {
  if (app.dock) {
    app.dock.setIcon(path.join(__dirname, 'assets', 'icon.png'));
    app.dock.show();
  }
  createWindow();
  createTray();

  // Show on first launch near tray
  setTimeout(() => {
    positionWindow();
    win.show();
    win.focus();
  }, 100);
});

app.on('window-all-closed', (e) => {
  e.preventDefault(); // Keep running in tray
});

app.on('activate', () => {
  if (!win || win.isDestroyed()) return;
  if (win.isVisible()) {
    win.webContents.send('tray-click-hide');
  } else {
    const store = getSettingsStore();
    const savedX = store.get('windowX');
    const savedY = store.get('windowY');
    if (savedX !== undefined && savedY !== undefined) {
      win.setPosition(savedX, savedY, false);
    } else {
      positionWindow();
    }
    win.webContents.send('window-will-show');
    win.show();
    win.focus();
  }
});

app.on('before-quit', () => {
  isQuitting = true;
  if (trayInterval) { clearInterval(trayInterval); trayInterval = null; }
  tray?.destroy();
});
