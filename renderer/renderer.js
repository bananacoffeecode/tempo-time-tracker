// Google Calendar color IDs and their hex values
const GCAL_COLORS = [
  { id: 1,  name: 'Lavender',  hex: '#7986CB' },
  { id: 2,  name: 'Sage',      hex: '#33B679' },
  { id: 3,  name: 'Grape',     hex: '#8E24AA' },
  { id: 4,  name: 'Flamingo',  hex: '#E67C73' },
  { id: 5,  name: 'Banana',    hex: '#F6BF26' },
  { id: 6,  name: 'Tangerine', hex: '#F4511E' },
  { id: 7,  name: 'Peacock',   hex: '#039BE5' },
  { id: 8,  name: 'Graphite',  hex: '#616161' },
  { id: 9,  name: 'Blueberry', hex: '#3F51B5' },
  { id: 10, name: 'Basil',     hex: '#0B8043' },
  { id: 11, name: 'Tomato',    hex: '#D50000' },
];

// State
let selectedColorId = 7;
let isRunning = false;
let isCollapsed = false;
let timerInterval = null;
let elapsedSeconds = 0;
let demoTimerInterval = null;
let demoTimerSeconds  = 0;
let isReviewing  = false;
let reviewStart  = null;
let reviewEnd    = null;
let reviewName   = '';
let reviewColorId = 7;
let sessionStartedAt = null;
let startPicker = null, endPicker = null;

// DOM refs
const content    = document.getElementById('content');
const sessionInput  = document.getElementById('session-name');
const colorPicker   = document.getElementById('color-picker');
const timerEl       = document.getElementById('timer');
const btnStart      = document.getElementById('btn-start');
const btnDiscard    = document.getElementById('btn-discard');
const btnDone       = document.getElementById('btn-done');
const btnAdjust     = document.getElementById('btn-adjust');
const flash         = document.getElementById('flash');
const closeBtn      = document.getElementById('close-btn');
const collapseBtn   = document.getElementById('collapse-btn');
const titlebar      = document.getElementById('titlebar');
const collapsedBar  = document.getElementById('collapsed-bar');
const miniStartBtn  = document.getElementById('mini-start-btn');
const miniStopBtn   = document.getElementById('mini-stop-btn');
const miniCloseBtn  = document.getElementById('mini-close-btn');
const miniName      = document.getElementById('mini-name');
const miniTimer     = document.getElementById('mini-timer');
const confettiCanvas = document.getElementById('confetti-canvas');
const appContainer   = document.getElementById('app-container');

// Review panel
const reviewPanel        = document.getElementById('review-panel');
const reviewBackBtn      = document.getElementById('review-back-btn');
const reviewCloseBtn     = document.getElementById('review-close-btn');
const reviewSessionLabel = document.getElementById('review-session-label');
const btnLog             = document.getElementById('btn-log');
const btnLogDiscard      = document.getElementById('btn-log-discard');
const reviewNameInput    = document.getElementById('review-name-input');
const reviewColorPickerEl = document.getElementById('review-color-picker');

// Onboarding
const onboarding         = document.getElementById('onboarding');
const onboardStep1       = document.getElementById('onboard-step-1');
const onboardStep2       = document.getElementById('onboard-step-2');
const onboardEmailInput  = document.getElementById('onboard-email');
const onboardContinueBtn = document.getElementById('onboard-continue-btn');
const onboardBackBtn     = null; // removed from step 2 design
const onboardAuthBtn     = document.getElementById('onboard-auth-btn');
const onboardWaiting     = document.getElementById('onboard-waiting');
const onboardNoCreds     = document.getElementById('onboard-no-creds');
const onboardQuitBtn     = document.getElementById('onboard-quit-btn');

// Settings
const settingsPanel        = document.getElementById('settings-panel');
const settingsHeader       = document.getElementById('settings-header');
const settingsBackBtn      = document.getElementById('settings-back-btn');
const settingsCloseBtn     = document.getElementById('settings-close-btn');
const settingsEmailDisplay = document.getElementById('settings-email-display');
const settingsDefaultName  = document.getElementById('settings-default-name');
const settingsLogoutBtn    = document.getElementById('settings-logout-btn');
const settingsBtn          = document.getElementById('settings-btn');

// ── Review helpers ───────────────────────────────

function formatDuration(ms) {
  const totalMin = Math.round(ms / 60000);
  const h = Math.floor(totalMin / 60);
  const m = totalMin % 60;
  return h > 0 ? `${h}h ${m > 0 ? m + 'm' : ''}`.trim() : `${m}m`;
}

function toTimeInput(date) {
  return String(date.getHours()).padStart(2,'0') + ':' + String(date.getMinutes()).padStart(2,'0');
}
function applyTimeInput(base, hhmm) {
  const [h, m] = hhmm.split(':').map(Number);
  const d = new Date(base);
  d.setHours(h, m, 0, 0);
  return d;
}
function openReview() {
  isReviewing = true;
  reviewNameInput.value = reviewName;
  buildReviewColorPicker();
  if (!startPicker) {
    startPicker = new TimePicker(
      document.getElementById('start-picker-wrap'),
      toTimeInput(reviewStart),
      (hhmm) => {
        reviewStart = applyTimeInput(reviewStart, hhmm);
        if (reviewEnd <= reviewStart) reviewEnd = new Date(reviewEnd.getTime() + 24 * 60 * 60 * 1000);
      }
    );
    endPicker = new TimePicker(
      document.getElementById('end-picker-wrap'),
      toTimeInput(reviewEnd),
      (hhmm) => {
        let next = applyTimeInput(reviewStart, hhmm);
        if (next <= reviewStart) next = new Date(next.getTime() + 24 * 60 * 60 * 1000);
        reviewEnd = next;
      }
    );
  } else {
    startPicker.setValue(toTimeInput(reviewStart));
    endPicker.setValue(toTimeInput(reviewEnd));
  }
  reviewPanel.style.display = 'flex';
}

function buildReviewColorPicker() {
  reviewColorPickerEl.innerHTML = '';
  GCAL_COLORS.forEach(({ id, name, hex }) => {
    const dot = document.createElement('div');
    dot.className = 'color-dot' + (id === reviewColorId ? ' selected' : '');
    dot.style.backgroundColor = hex;
    dot.title = name;
    dot.dataset.id = id;
    dot.addEventListener('click', () => {
      reviewColorId = id;
      selectedColorId = id;
      reviewColorPickerEl.querySelectorAll('.color-dot').forEach(d => d.classList.remove('selected'));
      dot.classList.add('selected');
      document.querySelectorAll('#color-picker .color-dot').forEach(d => {
        d.classList.toggle('selected', parseInt(d.dataset.id) === id);
      });
    });
    reviewColorPickerEl.appendChild(dot);
  });
}

function closeReview() {
  if (startPicker) startPicker.close();
  if (endPicker) endPicker.close();
  reviewPanel.style.display = 'none';
  isReviewing = false;
}

// ── Icons ────────────────────────────────────────

function initIcons() {
  btnDiscard.innerHTML   = window.icon('Trash', 15);
  settingsBtn.innerHTML  = window.icon('Gear', 14);
  collapseBtn.innerHTML  = window.icon('ChevronUp', 14);
  closeBtn.innerHTML     = window.icon('Cross', 13);
  miniStopBtn.innerHTML  = window.icon('Check', 11);
  miniCloseBtn.innerHTML = window.icon('Cross', 13);

  const arrowIcon = document.getElementById('onboard-arrow-icon');
  if (arrowIcon) arrowIcon.innerHTML = window.icon('ArrowRight', 13);
  const menuIcon = document.getElementById('onboard-menu-icon');
  if (menuIcon) menuIcon.innerHTML = window.icon('DotsThree', 15);
  const settingsMenuIcon = document.getElementById('settings-menu-icon');
  if (settingsMenuIcon) settingsMenuIcon.innerHTML = window.icon('DotsThree', 15);
  const quitIcon = document.getElementById('onboard-quit-icon');
  if (quitIcon) quitIcon.innerHTML = window.icon('Cross', 15);
  const calIconLg = document.getElementById('onboard-cal-icon-lg');
  if (calIconLg) calIconLg.innerHTML = window.icon('Calendar', 36);

  const demoCheck = document.getElementById('demo-cal-check');
  if (demoCheck) demoCheck.innerHTML = window.icon('Check', 13);
  const nextAIcon = document.getElementById('onboard-next-a-icon');
  if (nextAIcon) nextAIcon.innerHTML = window.icon('ArrowRight', 13);
  const nextBIcon = document.getElementById('onboard-next-b-icon');
  if (nextBIcon) nextBIcon.innerHTML = window.icon('ArrowRight', 13);
  const cCalIcon = document.getElementById('onboard-slide-c-cal-icon');
  if (cCalIcon) cCalIcon.innerHTML = window.icon('Calendar', 28);
  // onboard logo is now an <img> tag — no icon needed here

  settingsBackBtn.innerHTML  = window.icon('ChevronLeft', 14);
  settingsCloseBtn.innerHTML = window.icon('Cross', 13);

  reviewBackBtn.innerHTML  = window.icon('ChevronLeft', 14);
  reviewCloseBtn.innerHTML = window.icon('Cross', 13);
  document.getElementById('settings-calendar-icon').innerHTML = window.icon('Calendar', 13);
  document.getElementById('settings-name-icon').innerHTML     = window.icon('HamburgerMenu', 13);
  btnLogDiscard.innerHTML = window.icon('Trash', 15);
}

// ── Helpers ────────────────────────────────────

function formatTime(secs) {
  const h = Math.floor(secs / 3600).toString().padStart(2, '0');
  const m = Math.floor((secs % 3600) / 60).toString().padStart(2, '0');
  const s = (secs % 60).toString().padStart(2, '0');
  return `${h}:${m}:${s}`;
}

function showFlash(msg, duration = 1800) {
  flash.textContent = msg;
  flash.classList.add('show');
  setTimeout(() => flash.classList.remove('show'), duration);
}

function celebrate() {
  const ctx = confettiCanvas.getContext('2d');
  confettiCanvas.width = 320;
  confettiCanvas.height = 338;
  confettiCanvas.style.display = 'block';

  const colors = ['#7CA903', '#9DC714', '#F6BF26', '#FFFFFF', '#039BE5', '#E67C73'];
  const particles = Array.from({ length: 55 }, () => ({
    x: 60 + Math.random() * 200,
    y: 160 + Math.random() * 60,
    vx: (Math.random() - 0.5) * 6,
    vy: -(Math.random() * 5 + 2),
    size: Math.random() * 5 + 3,
    color: colors[Math.floor(Math.random() * colors.length)],
    rotation: Math.random() * Math.PI * 2,
    rotSpeed: (Math.random() - 0.5) * 0.25,
    gravity: 0.18,
  }));

  const totalFrames = 75;
  let frame = 0;

  function draw() {
    ctx.clearRect(0, 0, 320, 338);
    const progress = frame / totalFrames;
    particles.forEach(p => {
      ctx.save();
      ctx.globalAlpha = Math.max(0, 1 - progress * 1.4);
      ctx.fillStyle = p.color;
      ctx.translate(p.x, p.y);
      ctx.rotate(p.rotation);
      ctx.fillRect(-p.size / 2, -p.size / 2, p.size, p.size * 0.55);
      ctx.restore();
      p.x += p.vx;
      p.y += p.vy;
      p.vy += p.gravity;
      p.vx *= 0.99;
      p.rotation += p.rotSpeed;
    });
    frame++;
    if (frame < totalFrames) {
      requestAnimationFrame(draw);
    } else {
      ctx.clearRect(0, 0, 320, 338);
      confettiCanvas.style.display = 'none';
    }
  }

  requestAnimationFrame(draw);
}

// ── Collapse ────────────────────────────────────

function syncMiniBar() {
  if (isRunning) {
    miniName.textContent = sessionInput.value.trim() || sessionInput.placeholder;
    miniTimer.textContent = timerEl.textContent;
  } else {
    miniName.textContent = sessionInput.value.trim() || sessionInput.placeholder;
    miniTimer.textContent = '00:00:00';
  }
}

function toggleCollapse() {
  if (onboarding.style.display !== 'none') return;
  isCollapsed = !isCollapsed;
  document.body.classList.toggle('collapsed', isCollapsed);
  window.tracker.setWindowSize(
    isCollapsed ? { width: 320, height: 56 } : { width: 320, height: 338 }
  );
  if (isCollapsed) syncMiniBar();
  if (!isCollapsed && isReviewing) reviewPanel.style.display = 'flex';
  collapseBtn.innerHTML = isCollapsed
    ? window.icon('ChevronDown', 14)
    : window.icon('ChevronUp', 14);
}

// ── Color Picker ────────────────────────────────

function buildColorPicker() {
  colorPicker.innerHTML = '';
  GCAL_COLORS.forEach(({ id, name, hex }) => {
    const dot = document.createElement('div');
    dot.className = 'color-dot' + (id === selectedColorId ? ' selected' : '');
    dot.style.backgroundColor = hex;
    dot.title = name;
    dot.dataset.id = id;
    dot.addEventListener('click', () => {
      selectedColorId = id;
      document.querySelectorAll('.color-dot').forEach(d => d.classList.remove('selected'));
      dot.classList.add('selected');
    });
    colorPicker.appendChild(dot);
  });
}


// ── Timer ───────────────────────────────────────

function startTimer() {
  elapsedSeconds = 0;
  timerEl.textContent = '00:00:00';
  timerEl.classList.remove('idle');
  timerEl.classList.add('running', 'just-started');
  setTimeout(() => timerEl.classList.remove('just-started'), 600);
  timerInterval = setInterval(() => {
    elapsedSeconds++;
    const t = formatTime(elapsedSeconds);
    timerEl.textContent = t;
    if (isCollapsed) miniTimer.textContent = t;
  }, 1000);
}

function stopTimer() {
  clearInterval(timerInterval);
  timerInterval = null;
  timerEl.classList.remove('running');
  timerEl.classList.add('idle');
}

// ── Window animation ─────────────────────────────

async function hideWindowAnimated() {
  await window.tracker.hideWindow();
}

// ── Session ─────────────────────────────────────

async function onStart() {
  const name = sessionInput.value.trim() || sessionInput.placeholder || 'work session';
  sessionInput.value = name;
  isRunning = true;
  document.body.classList.add('running');
  sessionStartedAt = new Date();

  miniName.textContent = name;
  syncMiniBar();

  const result = await window.tracker.startSession(name, selectedColorId);
  if (!result?.started) {
    resetUI();
    showFlash('START FAILED');
    return;
  }

  startTimer();
  await hideWindowAnimated();
}

async function onStop() {
  btnDone.disabled = true;
  stopTimer();
  // Keep 'running' class so UI stays stable while API calls are in-flight
  const data = await window.tracker.prepareStop();
  if (data?.error) {
    resetUI();
    showFlash('ERROR: ' + data.error.slice(0, 28), 2500);
    btnDone.disabled = false;
    return;
  }
  const result = await window.tracker.logSession({
    startISO: data.startISO,
    endISO:   data.endISO,
    name:     data.name,
    colorId:  data.colorId,
  });
  btnDone.disabled = false;
  if (result?.success) {
    celebrate();
    showFlash('Logged to calendar');
    setTimeout(resetUI, 1800);
  } else {
    resetUI();
    showFlash('ERROR: ' + (result?.error || '').slice(0, 28), 2500);
  }
}

function onAdjust() {
  reviewStart   = sessionStartedAt ? new Date(sessionStartedAt) : new Date();
  reviewEnd     = new Date();
  reviewName    = sessionInput.value.trim() || sessionInput.placeholder;
  reviewColorId = selectedColorId;
  openReview();
}

function resetUI() {
  isRunning = false;
  document.body.classList.remove('running');
  timerEl.classList.add('idle');
  timerEl.textContent = '00:00:00';
  sessionInput.value = '';
  syncMiniBar();
  setTimeout(() => sessionInput.focus(), 50);
}

// ── App init ────────────────────────────────────

function stopDemoTimer() {
  if (demoTimerInterval) { clearInterval(demoTimerInterval); demoTimerInterval = null; }
}
function startDemoTimer() {
  stopDemoTimer();
  demoTimerSeconds = 0;
  const el = document.getElementById('demo-timer-display');
  if (!el) return;
  el.textContent = '00:00:00';
  demoTimerInterval = setInterval(() => {
    el.textContent = formatTime(++demoTimerSeconds);
  }, 1000);
}

function showOnboarding(step) {
  titlebar.style.display      = 'none';
  content.style.display       = 'none';
  settingsPanel.style.display = 'none';
  document.body.classList.add('onboarding');
  onboarding.style.display    = 'flex';
  window.tracker.setWindowSize({ width: 320, height: 408 });

  onboardStep1.style.display = 'none';
  onboardStep2.style.display = 'none';

  if (step === 1 || step === 'c') {
    onboardStep1.style.display = 'flex';
  } else if (step === 2) {
    onboardStep2.style.display = 'flex';
  }
}

function showMainWidget() {
  onboarding.style.display = 'none';
  document.body.classList.remove('onboarding');
  titlebar.style.display = 'flex';
  content.style.display  = 'flex';
  window.tracker.setWindowSize({ width: 320, height: 338 });
  setTimeout(() => sessionInput.focus(), 100);
}

async function initApp() {
  const [p, settings] = await Promise.all([
    window.tracker.getProfile(),
    window.tracker.getSettings(),
  ]);
  // sessionInput.placeholder = settings.defaultSessionName || 'work session'; // hidden for now
  sessionInput.placeholder = 'Work session';
  sessionInput.value = '';
  if (!p.hasCreds) {
    onboardNoCreds.style.display = 'block';
    onboardContinueBtn.disabled  = true;
    showOnboarding(1);
  } else if (!p.email) {
    showOnboarding(1);
  } else if (!p.hasToken) {
    showOnboarding(2);
  } else {
    showMainWidget();
  }
}

// ── Onboarding events ────────────────────────────

onboardContinueBtn.addEventListener('click', async () => {
  const email = onboardEmailInput.value.trim();
  if (!email || !email.includes('@')) {
    onboardEmailInput.classList.add('input-error');
    onboardEmailInput.focus();
    return;
  }
  onboardEmailInput.classList.remove('input-error');
  await window.tracker.saveEmail(email);
  showOnboarding(2);
});

onboardEmailInput.addEventListener('keydown', (e) => {
  if (e.key === 'Enter') onboardContinueBtn.click();
});

// back button removed from step 2

// ── Menu buttons ─────────────────────────────────
document.getElementById('onboard-menu-btn').addEventListener('click', () => {
  window.tracker.showOnboardMenu();
});
document.getElementById('settings-menu-btn').addEventListener('click', (e) => {
  e.stopPropagation();
  window.tracker.showSettingsMenu();
});

onboardAuthBtn.addEventListener('click', async () => {
  onboardAuthBtn.disabled    = true;
  onboardAuthBtn.textContent = 'Connecting...';
  onboardWaiting.style.display = 'block';
  const result = await window.tracker.startAuth();
  if (!result?.success) {
    onboardAuthBtn.disabled      = false;
    onboardAuthBtn.textContent   = 'Retry';
    onboardWaiting.style.display = 'none';
  }
});

window.tracker.onAuthComplete(() => {
  showFlash('AUTHORIZED', 1500);
  setTimeout(showMainWidget, 500);
});

window.tracker.onAuthError(() => {
  onboardAuthBtn.disabled      = false;
  onboardAuthBtn.textContent   = 'Retry';
  onboardWaiting.style.display = 'none';
});

// ── Settings events ──────────────────────────────

settingsBtn.addEventListener('click', (e) => {
  e.stopPropagation();
  if (settingsPanel.style.display !== 'none') {
    settingsBtn.classList.add('flash-open');
    setTimeout(() => settingsBtn.classList.remove('flash-open'), 700);
    return;
  }
  openSettings();
});

settingsBackBtn.addEventListener('click', (e) => {
  e.stopPropagation();
  closeSettings();
});

settingsCloseBtn.addEventListener('click', async (e) => {
  e.stopPropagation();
  settingsPanel.style.display = 'none';
  await hideWindowAnimated();
});

async function openSettings() {
  const [p, settings] = await Promise.all([
    window.tracker.getProfile(),
    window.tracker.getSettings(),
  ]);
  settingsEmailDisplay.value = p.email || '';
  settingsDefaultName.value = settings.defaultSessionName || '';
  settingsPanel.style.display = 'flex';
}

function closeSettings() {
  settingsPanel.style.display = 'none';
  // sessionInput.placeholder = settingsDefaultName.value.trim() || 'work session'; // hidden for now
}


/* hidden for now — default session name feature disabled
settingsDefaultName.addEventListener('blur', async () => {
  const val = settingsDefaultName.value.trim() || 'work session';
  await window.tracker.saveSettings({ defaultSessionName: val });
});

settingsDefaultName.addEventListener('keydown', (e) => {
  if (e.key === 'Enter') settingsDefaultName.blur();
});
*/

settingsLogoutBtn.addEventListener('click', async () => {
  settingsLogoutBtn.disabled = true;
  settingsLogoutBtn.textContent = 'Logging out...';
  await window.tracker.disconnectCalendar();
  closeSettings();
  showOnboarding(1);
});

// ── Review event listeners ───────────────────────

btnLog.addEventListener('click', async () => {
  btnLog.disabled = true;
  stopTimer();
  document.body.classList.remove('running');
  isRunning = false;
  await window.tracker.discardSession();
  const result = await window.tracker.logSession({
    startISO:  reviewStart.toISOString(),
    endISO:    reviewEnd.toISOString(),
    name:      reviewNameInput.value.trim() || reviewName,
    colorId:   reviewColorId,
  });
  closeReview();
  resetUI();
  if (result?.success) { celebrate(); showFlash('Logged to calendar'); }
  else showFlash('ERROR: ' + (result?.error || '').slice(0, 28), 2500);
  btnLog.disabled = false;
});

btnLogDiscard.addEventListener('click', async () => {
  await window.tracker.discardSession();
  closeReview();
  stopTimer();
  resetUI();
});

// Sync name from adjust modal → main widget in real-time
reviewNameInput.addEventListener('input', () => {
  sessionInput.value = reviewNameInput.value;
});

// Back from adjust — session still running
reviewBackBtn.addEventListener('click', () => closeReview());
reviewCloseBtn.addEventListener('click', () => { closeReview(); hideWindowAnimated(); });

// ── Event listeners ─────────────────────────────

btnStart.addEventListener('click', onStart);

document.getElementById('btn-log-event').addEventListener('click', () => {
  const now = new Date();
  reviewStart   = new Date(now.getTime() - 60 * 60 * 1000);
  reviewEnd     = now;
  reviewName    = '';
  reviewColorId = selectedColorId;
  openReview();
});

btnDone.addEventListener('click', onStop);
btnAdjust.addEventListener('click', onAdjust);
btnDiscard.addEventListener('click', async () => {
  stopTimer();
  await window.tracker.discardSession();
  resetUI();
});

closeBtn.addEventListener('click', async (e) => {
  e.stopPropagation();
  await hideWindowAnimated();
});

document.addEventListener('keydown', async (e) => {
  if (e.key === 'Escape') {
    if (isReviewing) { closeReview(); }
    else await hideWindowAnimated();
  }
});

onboardQuitBtn.addEventListener('click', () => {
  window.tracker.quitApp();
});

collapseBtn.addEventListener('click', (e) => {
  e.stopPropagation();
  toggleCollapse();
});

// Drag-to-move + click-to-toggle for both bars
function makeBarDraggable(element, onClickCallback) {
  element.addEventListener('mousedown', (e) => {
    if (e.target.closest('button')) return;
    const startSX = e.screenX, startSY = e.screenY;
    let lastSX = e.screenX, lastSY = e.screenY;
    let dragged = false;

    function onMove(ev) {
      const dx = ev.screenX - lastSX;
      const dy = ev.screenY - lastSY;
      if (!dragged && Math.abs(ev.screenX - startSX) + Math.abs(ev.screenY - startSY) >= 4) {
        dragged = true;
      }
      if (dragged && (dx !== 0 || dy !== 0)) {
        window.tracker.moveWindowBy({ dx, dy });
        lastSX = ev.screenX;
        lastSY = ev.screenY;
      }
    }

    function onUp(ev) {
      document.removeEventListener('mousemove', onMove);
      document.removeEventListener('mouseup', onUp);
      if (!dragged && Math.abs(ev.screenX - startSX) + Math.abs(ev.screenY - startSY) < 6) {
        onClickCallback();
      }
    }

    document.addEventListener('mousemove', onMove);
    document.addEventListener('mouseup', onUp);
  });
}

makeBarDraggable(titlebar, toggleCollapse);
makeBarDraggable(collapsedBar, toggleCollapse);
makeBarDraggable(settingsHeader, () => {
  closeSettings();
  if (!isCollapsed) toggleCollapse();
});
makeBarDraggable(document.getElementById('review-header'), toggleCollapse);

// Mini actions — stopPropagation so they don't also trigger expand
miniStartBtn.addEventListener('click', (e) => { e.stopPropagation(); onStart(); });
miniStopBtn.addEventListener('click', (e) => { e.stopPropagation(); onStop(); }); // calls onStop = direct log
miniCloseBtn.addEventListener('click', async (e) => { e.stopPropagation(); await hideWindowAnimated(); });

sessionInput.addEventListener('keydown', (e) => {
  if (e.key === 'Enter' && !isRunning) onStart();
});

sessionInput.addEventListener('input', () => {
  if (isRunning) syncMiniBar();
});

// ── Init ─────────────────────────────────────────

window.tracker.onWindowShow(() => {
  appContainer.classList.remove('appearing');
  void appContainer.offsetWidth;
  appContainer.classList.add('appearing');
  setTimeout(() => appContainer.classList.remove('appearing'), 300);
});

window.tracker.onTrayClickHide(() => {
  hideWindowAnimated();
});

initIcons();
buildColorPicker();
initApp();
