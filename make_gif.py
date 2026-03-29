#!/usr/bin/env python3
"""Generate animated GIF demo of Tempo time tracker."""

from PIL import Image, ImageDraw, ImageFont
import os

OUT = os.path.join(os.path.dirname(__file__), 'assets', 'tempo-demo.gif')

# ── Canvas ────────────────────────────────────────────────────
W, H = 320, 338
SC = 2
SW, SH = W * SC, H * SC

# ── Palette ───────────────────────────────────────────────────
BG       = (255, 255, 255)
TEXT     = (26,  26,  26 )
TEXT2    = (107, 107, 107)
PH       = (170, 170, 170)
BORDER   = (224, 224, 224)
GREEN    = (124, 169,   3)
GREEND   = (104, 145,   2)
RED      = (255,  59,  48)
TIMERC   = (34,  34,  34 )
INPUTDIS = (248, 248, 248)

GCAL = {
    1: (121, 134, 203),
    2: (51,  182, 121),
    3: (142,  36, 170),
    4: (230, 124, 115),
    5: (246, 191,  38),
    6: (244,  81,  30),
    7: (3,   155, 229),
    8: (97,   97,  97),
    9: (63,   81, 181),
   10: (11,  128,  67),
   11: (213,   0,   0),
}

AVENIR  = '/System/Library/Fonts/Avenir Next.ttc'
GEORGIA = '/System/Library/Fonts/Supplemental/Georgia.ttf'

# ── Font helpers ──────────────────────────────────────────────
_font_cache = {}
def F(size, bold=False, serif=False):
    key = (size, bold, serif)
    if key not in _font_cache:
        if serif:
            _font_cache[key] = ImageFont.truetype(GEORGIA, int(size * SC))
        else:
            idx = 6 if bold else 0
            _font_cache[key] = ImageFont.truetype(AVENIR, int(size * SC), index=idx)
    return _font_cache[key]

def S(n): return int(n * SC)

# ── Layout constants ──────────────────────────────────────────
TB_H  = S(56)
PX    = S(18)
PY    = S(20)
IX0   = PX
IX1   = SW - PX
IW    = IX1 - IX0

# Main widget content positions
TIMER_Y  = TB_H + PY
INP_Y    = TIMER_Y + S(72) + PY
INP_H    = S(44)
CP_Y     = INP_Y + INP_H + PY
BTN_Y    = CP_Y + S(18) + PY
BTN_H    = S(48)

# ── Core drawing ─────────────────────────────────────────────

def new_img():
    img = Image.new('RGB', (SW, SH), BG)
    draw = ImageDraw.Draw(img)
    return img, draw

def clip_to_widget(img):
    """Apply 16px rounded corners to image."""
    mask = Image.new('L', (SW, SH), 0)
    md = ImageDraw.Draw(mask)
    md.rounded_rectangle([0, 0, SW-1, SH-1], radius=S(16), fill=255)
    result = Image.new('RGB', (SW, SH), BG)
    result.paste(img, mask=mask)
    return result

def draw_titlebar(d):
    d.rectangle([0, 0, SW, TB_H], fill=BG)
    d.line([(0, TB_H), (SW, TB_H)], fill=BORDER, width=1)
    d.text((IX0, TB_H // 2), 'Tempo', font=F(13, bold=True), fill=TEXT, anchor='lm')
    for i, c in enumerate([RED, TEXT2, TEXT2]):
        cx = IX1 - i * S(22)
        cy = TB_H // 2
        r = S(5)
        d.ellipse([cx-r, cy-r, cx+r, cy+r], fill=c)

def draw_timer_text(d, text, running=False):
    f = F(72, serif=True)
    bbox = f.getbbox(text)
    tw = bbox[2] - bbox[0]
    tx = (SW - tw) // 2 - bbox[0]
    # Baseline position: we want the glyphs to start at TIMER_Y
    ty = TIMER_Y - bbox[1]
    d.text((tx, ty), text, font=f, fill=TIMERC)

def draw_session_input(d, text='', focused=False, disabled=False):
    y0, y1 = INP_Y, INP_Y + INP_H
    bg = INPUTDIS if disabled else BG
    outline = GREEN if focused else BORDER
    ow = S(2) if focused else S(1)
    d.rounded_rectangle([IX0, y0, IX1, y1], radius=S(16), fill=bg, outline=outline, width=ow)
    if focused and text is not None:
        # Green focus glow
        glow = (*GREEN, 30)
    f = F(14)
    cx = IX0 + S(20)
    cy = (y0 + y1) // 2
    if text:
        d.text((cx, cy), text.lower(), font=f, fill=TEXT, anchor='lm')
    else:
        d.text((cx, cy), 'Work session', font=f, fill=PH, anchor='lm')

def draw_color_picker(d, selected_id, y_top):
    r = S(9)
    gap = S(8)
    x = IX0 + r
    for cid, rgb in GCAL.items():
        cy = y_top + r
        d.ellipse([x-r, cy-r, x+r, cy+r], fill=rgb)
        if cid == selected_id:
            # White gap ring
            d.ellipse([x-r-S(2), cy-r-S(2), x+r+S(2), cy+r+S(2)], outline=BG, width=S(2))
            # Green outer ring
            d.ellipse([x-r-S(4), cy-r-S(4), x+r+S(4), cy+r+S(4)], outline=GREEN, width=S(2))
        x += r * 2 + gap

def draw_idle_buttons(d, start_pressed=False):
    y0, y1 = BTN_Y, BTN_Y + BTN_H
    gap = S(10)
    start_w = IW * 55 // 100
    log_w = IW - start_w - gap
    # Start
    bg = GREEND if start_pressed else GREEN
    d.rounded_rectangle([IX0, y0, IX0+start_w, y1], radius=S(16), fill=bg)
    d.text(((IX0*2+start_w)//2, (y0+y1)//2), 'Start', font=F(14, bold=True), fill=BG, anchor='mm')
    # Log an event
    lx0 = IX0 + start_w + gap
    d.rounded_rectangle([lx0, y0, IX1, y1], radius=S(16), fill=BG, outline=BORDER, width=S(1))
    d.text(((lx0+IX1)//2, (y0+y1)//2), 'Log an event', font=F(14, bold=True), fill=TEXT, anchor='mm')

def draw_running_buttons(d, done_pressed=False):
    y0, y1 = BTN_Y, BTN_Y + BTN_H
    gap = S(10)
    disc_w = S(48)
    half = (IW - disc_w - gap * 2) // 2
    # Done
    bg = GREEND if done_pressed else GREEN
    d.rounded_rectangle([IX0, y0, IX0+half, y1], radius=S(16), fill=bg)
    d.text(((IX0*2+half)//2, (y0+y1)//2), 'Done', font=F(14, bold=True), fill=BG, anchor='mm')
    # Adjust
    ax0 = IX0 + half + gap
    ax1 = ax0 + half
    d.rounded_rectangle([ax0, y0, ax1, y1], radius=S(16), fill=BG, outline=BORDER, width=S(1))
    d.text(((ax0+ax1)//2, (y0+y1)//2), 'Adjust', font=F(14, bold=True), fill=TEXT, anchor='mm')
    # Discard circle
    dx0 = ax1 + gap
    dcx = (dx0 + IX1) // 2
    dcy = (y0 + y1) // 2
    dr = S(20)
    d.ellipse([dcx-dr, dcy-dr, dcx+dr, dcy+dr], fill=(255, 245, 244), outline=(255, 210, 207), width=S(1))
    d.text((dcx, dcy), '×', font=F(16), fill=RED, anchor='mm')

# ── Review panel ─────────────────────────────────────────────
RV_HDR_Y0 = 0
RV_HDR_Y1 = TB_H
RV_BODY_Y  = TB_H

RV_TP_Y  = RV_BODY_Y + PY          # time pickers top
RV_TP_H  = S(52)
RV_NI_Y  = RV_TP_Y + RV_TP_H + S(14)
RV_NI_H  = S(44)
RV_CP_Y  = RV_NI_Y + RV_NI_H + S(14)
RV_BTN_Y = RV_CP_Y + S(18) + S(14)
RV_BTN_H = S(50)

def draw_review_panel(d, name, color_id, start_str, end_str, end_focused=False, log_pressed=False):
    d.rectangle([0, 0, SW, SH], fill=BG)
    # Header
    d.rectangle([0, RV_HDR_Y0, SW, RV_HDR_Y1], fill=BG)
    d.line([(0, RV_HDR_Y1), (SW, RV_HDR_Y1)], fill=BORDER, width=1)
    # Back arrow (drawn manually)
    bx, by = IX0, TB_H // 2
    d.line([(bx+S(6), by-S(4)), (bx, by), (bx+S(6), by+S(4))], fill=TEXT2, width=S(2))
    d.line([(bx, by), (bx+S(14), by)], fill=TEXT2, width=S(2))
    d.text((bx+S(20), by), 'Back', font=F(13), fill=TEXT2, anchor='lm')
    d.text((SW//2, TB_H//2), (name or 'Work session').lower(), font=F(13, bold=True), fill=TEXT, anchor='mm')
    # Close X (drawn manually)
    cx, cy, cr = IX1-S(6), TB_H//2, S(5)
    d.line([(cx-cr, cy-cr), (cx+cr, cy+cr)], fill=TEXT2, width=S(2))
    d.line([(cx+cr, cy-cr), (cx-cr, cy+cr)], fill=TEXT2, width=S(2))

    # Time pickers
    half_w = (IW - S(16)) // 2
    for i, (label, t, focused) in enumerate([
        ('Start', start_str, False),
        ('End',   end_str,   end_focused),
    ]):
        bx0 = IX0 + i * (half_w + S(16))
        bx1 = bx0 + half_w
        outline = GREEN if focused else BORDER
        ow = S(2) if focused else S(1)
        d.rounded_rectangle([bx0, RV_TP_Y, bx1, RV_TP_Y+RV_TP_H],
                            radius=S(16), fill=BG, outline=outline, width=ow)
        d.text((bx0+S(14), RV_TP_Y+S(10)), label, font=F(11, bold=True), fill=TEXT2, anchor='lt')
        d.text((bx0+S(14), RV_TP_Y+S(30)), t, font=F(13), fill=TEXT, anchor='lt')

    # Name input
    d.rounded_rectangle([IX0, RV_NI_Y, IX1, RV_NI_Y+RV_NI_H],
                       radius=S(16), fill=BG, outline=BORDER, width=S(1))
    txt = (name or '').lower() if name else ''
    if txt:
        d.text((IX0+S(20), RV_NI_Y+RV_NI_H//2), txt, font=F(14), fill=TEXT, anchor='lm')
    else:
        d.text((IX0+S(20), RV_NI_Y+RV_NI_H//2), 'Work session', font=F(14), fill=PH, anchor='lm')

    # Color picker
    draw_color_picker(d, color_id, RV_CP_Y)

    # Log button
    bg = GREEND if log_pressed else GREEN
    d.rounded_rectangle([IX0, RV_BTN_Y, IX1, RV_BTN_Y+RV_BTN_H], radius=S(16), fill=bg)
    d.text((SW//2, RV_BTN_Y+RV_BTN_H//2), 'Log to Calendar', font=F(15, bold=True), fill=BG, anchor='mm')

# ── Flash overlay ─────────────────────────────────────────────
def draw_flash_overlay(img, alpha_frac=1.0):
    """Overlay a green flash strip with 'Logged to calendar' text."""
    overlay = img.copy()
    od = ImageDraw.Draw(overlay)
    # Semi-transparent green bar in center
    bar_h = S(60)
    bar_y0 = (SH - bar_h) // 2
    bar_y1 = bar_y0 + bar_h
    # Draw on top of existing
    od.rectangle([0, bar_y0, SW, bar_y1], fill=(*GREEN, int(255 * alpha_frac)))
    od.text((SW//2, (bar_y0+bar_y1)//2), 'Logged to calendar',
            font=F(15), fill=BG, anchor='mm')
    return overlay

# ── Render a frame ────────────────────────────────────────────
def render(state):
    img, d = new_img()
    panel = state.get('panel', 'main')

    if panel == 'main':
        draw_titlebar(d)
        timer = state.get('timer', '00:00:00')
        draw_timer_text(d, timer, running=state.get('running', False))
        draw_session_input(d,
            text=state.get('text', ''),
            focused=state.get('focused', False),
            disabled=state.get('running', False))
        draw_color_picker(d, state.get('color', 7), CP_Y)
        if state.get('running'):
            draw_running_buttons(d, done_pressed=state.get('done_pressed', False))
        else:
            draw_idle_buttons(d, start_pressed=state.get('start_pressed', False))

    elif panel == 'review':
        draw_review_panel(d,
            name=state.get('text', ''),
            color_id=state.get('color', 7),
            start_str=state.get('start_str', '2:30 PM'),
            end_str=state.get('end_str', '4:10 PM'),
            end_focused=state.get('end_focused', False),
            log_pressed=state.get('log_pressed', False))

    img = clip_to_widget(img)

    # Flash overlay (full green screen with message)
    if state.get('flash'):
        fd = ImageDraw.Draw(img)
        # Green background
        mask = Image.new('L', (SW, SH), 0)
        md = ImageDraw.Draw(mask)
        md.rounded_rectangle([0, 0, SW-1, SH-1], radius=S(16), fill=255)
        flash_layer = Image.new('RGB', (SW, SH), GREEN)
        # Confetti dots
        fld = ImageDraw.Draw(flash_layer)
        import random
        random.seed(42)
        dots = [(121,134,203),(246,191,38),(255,255,255),(3,155,229),(230,124,115)]
        for _ in range(40):
            cx = random.randint(S(20), SW - S(20))
            cy = random.randint(S(20), SH - S(20))
            r = random.randint(S(2), S(6))
            c = dots[random.randint(0, len(dots)-1)]
            fld.ellipse([cx-r, cy-r, cx+r, cy+r], fill=c)
        # Checkmark circle with check drawn as lines
        ck_cx, ck_cy, ck_s = SW//2, SH//2 - S(24), S(16)
        fld.ellipse([ck_cx-ck_s, ck_cy-ck_s, ck_cx+ck_s, ck_cy+ck_s], fill=BG)
        # Green checkmark lines inside circle
        fld.line([(ck_cx-S(7), ck_cy+S(1)), (ck_cx-S(1), ck_cy+S(7)), (ck_cx+S(9), ck_cy-S(7))],
                fill=GREEN, width=S(3))
        fld.text((SW//2, SH//2 + S(26)), 'Logged to calendar', font=F(15), fill=BG, anchor='mm')
        img.paste(flash_layer, mask=mask)

    # Downsample to 1x
    out = img.resize((W, H), Image.LANCZOS)
    return out

# ── Scene builder ─────────────────────────────────────────────
def frames_for(state, count, delay_ms):
    """Return list of (image, delay_ms) tuples."""
    return [(render(state), delay_ms)] * count

def scene_idle():
    """2 frames × 800ms = 1.6s idle"""
    s = {'panel': 'main', 'timer': '00:00:00', 'text': '', 'color': 7}
    return frames_for(s, 2, 800)

def scene_focus_and_type(text='design sprint'):
    """Focus input then type character by character."""
    result = []
    base = {'panel': 'main', 'timer': '00:00:00', 'color': 7}
    # Focus
    result.append((render({**base, 'focused': True, 'text': ''}), 300))
    # Type each char
    for i in range(1, len(text)+1):
        result.append((render({**base, 'focused': True, 'text': text[:i]}), 80))
    # Brief pause after typing
    result.append((render({**base, 'focused': True, 'text': text}), 400))
    return result

def scene_color_select(from_id, to_id, text):
    """Animate color selection change."""
    base = {'panel': 'main', 'timer': '00:00:00', 'text': text}
    result = []
    # Show current
    result.append((render({**base, 'color': from_id}), 300))
    # Brief highlight on new color (show as selected)
    result.append((render({**base, 'color': to_id}), 500))
    return result

def scene_start(text, color_id):
    """Click start button."""
    base = {'panel': 'main', 'timer': '00:00:00', 'text': text, 'color': color_id}
    result = []
    result.append((render({**base, 'start_pressed': True}), 150))
    result.append((render({**base, 'running': True, 'timer': '00:00:01'}), 200))
    return result

def scene_timer_running(text, color_id, seconds_list):
    """Show timer counting."""
    result = []
    for sec in seconds_list:
        mins, s = divmod(sec, 60)
        hrs, mins = divmod(mins, 60)
        t = f'{hrs:02d}:{mins:02d}:{s:02d}'
        state = {'panel': 'main', 'timer': t, 'text': text, 'color': color_id, 'running': True}
        result.append((render(state), 1000))
    return result

def scene_done_pressed(text, color_id, timer):
    """Done button pressed briefly."""
    s = {'panel': 'main', 'timer': timer, 'text': text, 'color': color_id,
         'running': True, 'done_pressed': True}
    return [(render(s), 150)]

def scene_review(text, color_id, start_str, end_str, end_focused=False, log_pressed=False):
    s = {'panel': 'review', 'text': text, 'color': color_id,
         'start_str': start_str, 'end_str': end_str,
         'end_focused': end_focused, 'log_pressed': log_pressed}
    return [(render(s), 400)]

def scene_flash():
    s = {'panel': 'main', 'timer': '00:00:00', 'text': '', 'color': 7, 'flash': True}
    return frames_for(s, 3, 500)

def scene_reset():
    s = {'panel': 'main', 'timer': '00:00:00', 'text': '', 'color': 7}
    return frames_for(s, 2, 600)

# ── Assemble all scenes ────────────────────────────────────────
def build_frames():
    SESSION_NAME = 'design sprint'
    COLOR_START = 7   # Peacock
    COLOR_END   = 5   # Banana
    TIMER_FINAL = '00:00:07'
    REVIEW_START = '2:30 PM'
    REVIEW_END_1 = '4:00 PM'
    REVIEW_END_2 = '4:30 PM'

    frames = []
    frames += scene_idle()
    frames += scene_focus_and_type(SESSION_NAME)
    frames += scene_color_select(COLOR_START, COLOR_END, SESSION_NAME)

    # Brief pause before Start
    frames.append((render({'panel':'main','timer':'00:00:00','text':SESSION_NAME,'color':COLOR_END}), 300))

    frames += scene_start(SESSION_NAME, COLOR_END)
    frames += scene_timer_running(SESSION_NAME, COLOR_END, [2, 3, 4, 5, 6, 7])
    frames += scene_done_pressed(SESSION_NAME, COLOR_END, TIMER_FINAL)

    # Review panel appears
    frames += scene_review(SESSION_NAME, COLOR_END, REVIEW_START, REVIEW_END_1)
    frames += scene_review(SESSION_NAME, COLOR_END, REVIEW_START, REVIEW_END_1, end_focused=True)
    # Adjust end time
    for et in ['4:10 PM', '4:20 PM', '4:30 PM']:
        frames += scene_review(SESSION_NAME, COLOR_END, REVIEW_START, et, end_focused=True)
    # Unfocus
    frames += scene_review(SESSION_NAME, COLOR_END, REVIEW_START, REVIEW_END_2)
    # Press log
    frames += scene_review(SESSION_NAME, COLOR_END, REVIEW_START, REVIEW_END_2, log_pressed=True)

    # Flash
    frames += scene_flash()
    frames += scene_reset()

    return frames

# ── Save GIF ──────────────────────────────────────────────────
def save_gif(frames, path):
    images = [f[0] for f in frames]
    delays = [f[1] for f in frames]
    images[0].save(
        path,
        save_all=True,
        append_images=images[1:],
        loop=0,
        duration=delays,
        optimize=False,
    )
    size_kb = os.path.getsize(path) // 1024
    print(f'Saved {path} ({len(images)} frames, {size_kb} KB)')

if __name__ == '__main__':
    print('Building frames...')
    frames = build_frames()
    print(f'  {len(frames)} frames total')
    print('Saving GIF...')
    save_gif(frames, OUT)
    print('Done!')
