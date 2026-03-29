class TimePicker {
  constructor(wrapEl, h24, onChange) {
    this.wrap = wrapEl;
    this.onChange = onChange;
    this.hourInput = null;
    this.minInput = null;
    this.amBtn = null;
    this.pmBtn = null;
    this.face = null;
    this.dropdown = null;

    const [h, m] = (h24 || '00:00').split(':').map(Number);
    this.hour24 = isNaN(h) ? 0 : Math.max(0, Math.min(23, h));
    this.minute = isNaN(m) ? 0 : Math.max(0, Math.min(59, m));

    this._build();
    this._update();
  }

  setValue(h24) {
    const [h, m] = (h24 || '00:00').split(':').map(Number);
    this.hour24 = isNaN(h) ? 0 : Math.max(0, Math.min(23, h));
    this.minute = isNaN(m) ? 0 : Math.max(0, Math.min(59, m));
    this._update();
  }

  open() {
    // Close any other open picker first
    if (TimePicker._current && TimePicker._current !== this) {
      TimePicker._current.close();
    }
    TimePicker._current = this;
    this.wrap.classList.add('tp-open');
    // Restart animation by removing and re-adding display
    this.dropdown.style.display = 'none';
    void this.dropdown.offsetWidth;
    this.dropdown.style.display = 'flex';
    this._syncDropdown();
  }

  close() {
    if (TimePicker._current === this) TimePicker._current = null;
    this.wrap.classList.remove('tp-open');
    this.dropdown.style.display = 'none';
  }

  toggle() {
    if (this.dropdown.style.display === 'flex') this.close();
    else this.open();
  }

  _get12h() {
    const pm = this.hour24 >= 12;
    let h = this.hour24 % 12;
    if (h === 0) h = 12;
    return { h, pm };
  }

  _update() {
    const { h, pm } = this._get12h();
    const hStr = String(h).padStart(2, '0');
    const mStr = String(this.minute).padStart(2, '0');
    if (this.face) this.face.textContent = `${hStr}:${mStr} ${pm ? 'PM' : 'AM'}`;
    this._syncDropdown();
  }

  _syncDropdown() {
    if (!this.hourInput) return;
    const { h, pm } = this._get12h();
    this.hourInput.value = String(h).padStart(2, '0');
    this.minInput.value = String(this.minute).padStart(2, '0');
    this.amBtn.classList.toggle('tp-active', !pm);
    this.pmBtn.classList.toggle('tp-active', pm);
  }

  _adjustHour(delta) {
    const { h, pm } = this._get12h();
    let newH = h + delta;
    if (newH > 12) newH = 1;
    if (newH < 1) newH = 12;
    this.hour24 = pm ? (newH === 12 ? 12 : newH + 12) : (newH === 12 ? 0 : newH);
    this._update();
    this._fireChange();
  }

  _adjustMin(delta) {
    this.minute = ((this.minute + delta * 5) % 60 + 60) % 60;
    this._update();
    this._fireChange();
  }

  _setAMPM(pm) {
    const wasPM = this.hour24 >= 12;
    if (pm === wasPM) return;
    this.hour24 = pm ? this.hour24 + 12 : this.hour24 - 12;
    this._update();
    this._fireChange();
  }

  _fireChange() {
    const h = String(this.hour24).padStart(2, '0');
    const m = String(this.minute).padStart(2, '0');
    this.onChange(`${h}:${m}`);
  }

  _build() {
    this.wrap.innerHTML = '';
    this.wrap.style.position = 'relative';

    // Face display
    this.face = document.createElement('span');
    this.face.className = 'tp-face';

    // Clock icon button
    const clockBtn = document.createElement('button');
    clockBtn.className = 'tp-clock-btn';
    clockBtn.type = 'button';
    if (window.icon) clockBtn.innerHTML = window.icon('Clock', 15);
    else clockBtn.textContent = '🕐';

    // Dropdown
    this.dropdown = document.createElement('div');
    this.dropdown.className = 'tp-dropdown';
    this.dropdown.style.display = 'none';

    // Hour column
    const hourCol = document.createElement('div');
    hourCol.className = 'tp-col';
    const hourUp = document.createElement('button');
    hourUp.className = 'tp-arrow';
    hourUp.type = 'button';
    hourUp.textContent = '▲';
    this.hourInput = document.createElement('input');
    this.hourInput.className = 'tp-num';
    this.hourInput.type = 'text';
    this.hourInput.maxLength = 2;
    const hourDown = document.createElement('button');
    hourDown.className = 'tp-arrow';
    hourDown.type = 'button';
    hourDown.textContent = '▼';
    hourCol.append(hourUp, this.hourInput, hourDown);

    // Separator
    const sep = document.createElement('span');
    sep.className = 'tp-sep';
    sep.textContent = ':';

    // Minute column
    const minCol = document.createElement('div');
    minCol.className = 'tp-col';
    const minUp = document.createElement('button');
    minUp.className = 'tp-arrow';
    minUp.type = 'button';
    minUp.textContent = '▲';
    this.minInput = document.createElement('input');
    this.minInput.className = 'tp-num';
    this.minInput.type = 'text';
    this.minInput.maxLength = 2;
    const minDown = document.createElement('button');
    minDown.className = 'tp-arrow';
    minDown.type = 'button';
    minDown.textContent = '▼';
    minCol.append(minUp, this.minInput, minDown);

    // AM/PM column
    const ampmCol = document.createElement('div');
    ampmCol.className = 'tp-ampm-col';
    this.amBtn = document.createElement('button');
    this.amBtn.className = 'tp-ampm-btn';
    this.amBtn.type = 'button';
    this.amBtn.textContent = 'AM';
    this.pmBtn = document.createElement('button');
    this.pmBtn.className = 'tp-ampm-btn';
    this.pmBtn.type = 'button';
    this.pmBtn.textContent = 'PM';
    ampmCol.append(this.amBtn, this.pmBtn);

    this.dropdown.append(hourCol, sep, minCol, ampmCol);
    this.wrap.append(this.face, clockBtn, this.dropdown);

    // Arrow events
    hourUp.addEventListener('click', (e) => { e.stopPropagation(); this._adjustHour(1); });
    hourDown.addEventListener('click', (e) => { e.stopPropagation(); this._adjustHour(-1); });
    minUp.addEventListener('click', (e) => { e.stopPropagation(); this._adjustMin(1); });
    minDown.addEventListener('click', (e) => { e.stopPropagation(); this._adjustMin(-1); });
    this.amBtn.addEventListener('click', (e) => { e.stopPropagation(); this._setAMPM(false); });
    this.pmBtn.addEventListener('click', (e) => { e.stopPropagation(); this._setAMPM(true); });

    // Toggle open/close
    this.face.addEventListener('click', (e) => { e.stopPropagation(); this.toggle(); });
    clockBtn.addEventListener('click', (e) => { e.stopPropagation(); this.toggle(); });

    // Hour direct input
    this.hourInput.addEventListener('focus', () => this.hourInput.select());
    this.hourInput.addEventListener('blur', () => {
      const val = parseInt(this.hourInput.value, 10);
      if (!isNaN(val) && val >= 1 && val <= 12) {
        const pm = this.hour24 >= 12;
        this.hour24 = pm ? (val === 12 ? 12 : val + 12) : (val === 12 ? 0 : val);
        this._fireChange();
      }
      this._update();
    });
    this.hourInput.addEventListener('keydown', (e) => {
      if (e.key === 'Enter') { e.preventDefault(); this.hourInput.blur(); }
    });

    // Minute direct input
    this.minInput.addEventListener('focus', () => this.minInput.select());
    this.minInput.addEventListener('blur', () => {
      const val = parseInt(this.minInput.value, 10);
      if (!isNaN(val) && val >= 0 && val <= 59) {
        this.minute = val;
        this._fireChange();
      }
      this._update();
    });
    this.minInput.addEventListener('keydown', (e) => {
      if (e.key === 'Enter') { e.preventDefault(); this.minInput.blur(); }
    });

    // Outside-click to close
    document.addEventListener('click', (e) => {
      if (!this.wrap.contains(e.target)) this.close();
    });

    // ESC to close
    document.addEventListener('keydown', (e) => {
      if (e.key === 'Escape') this.close();
    });
  }
}

TimePicker._current = null;
