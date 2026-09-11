# -*- coding: utf-8 -*-
"""Finds the things worth tapping in a screenshot of the gate.

The gate draws itself on a Canvas, so there is no accessibility tree to query —
a driver has to look at the pixels like a child does. Everything here keys off
two facts about the design: interactive surfaces are near-white cards on a pale
lavender page, and the board is the only checkerboard on screen.
"""
from PIL import Image

BG = (246, 241, 255)        # page
NEAR_WHITE = 248            # a card's face
TILE_ALT_MAX = 243          # the board's darker tile is clearly below white


def load(path):
    return Image.open(path).convert("RGB")


def _is_white(px):
    return px[0] >= NEAR_WHITE and px[1] >= NEAR_WHITE and px[2] >= NEAR_WHITE


def content_band(im):
    """Vertical range between the top chrome and the action bar."""
    w, h = im.size
    return int(h * 0.10), int(h * 0.88)


def white_cards(im, min_frac=0.45, min_h=28):
    """Full-width-ish white cards, top to bottom, as (x0, y0, x1, y1).

    Options, program rows and number keys are all cards; which one a shape means
    is decided by the caller, which knows what it asked.
    """
    w, h = im.size
    px = im.load()
    top, bot = content_band(im)
    rows = []
    for y in range(top, bot, 2):
        run = best = 0
        start = bstart = 0
        for x in range(0, w, 4):
            if _is_white(px[x, y]):
                if run == 0:
                    start = x
                run += 4
                if run > best:
                    best, bstart = run, start
            else:
                run = 0
        rows.append((y, best, bstart))

    cards, cur = [], None
    for y, best, bstart in rows:
        wide = best >= w * min_frac
        if wide and cur is None:
            cur = [y, bstart, bstart + best]
        elif wide and cur is not None:
            cur[1] = min(cur[1], bstart)
            cur[2] = max(cur[2], bstart + best)
        elif not wide and cur is not None:
            if y - cur[0] >= min_h:
                cards.append((cur[1], cur[0], cur[2], y))
            cur = None
    if cur is not None and bot - cur[0] >= min_h:
        cards.append((cur[1], cur[0], cur[2], bot))
    return cards


def key_row(im):
    """The four number keys: separate white squares sharing one band."""
    w, h = im.size
    px = im.load()
    for (x0, y0, x1, y1) in white_cards(im, min_frac=0.10, min_h=40):
        mid = (y0 + y1) // 2
        blocks, run, start = [], 0, 0
        for x in range(0, w, 3):
            if _is_white(px[x, mid]):
                if run == 0:
                    start = x
                run += 3
            else:
                if run > w * 0.10:
                    blocks.append((start, start + run))
                run = 0
        if run > w * 0.10:
            blocks.append((start, start + run))
        if len(blocks) == 4:
            return [((a + b) // 2, mid) for a, b in blocks]
    return []


def board_rect(im):
    """The board's pixel rect.

    Measured, not guessed: a tile is either pure white or (240,242,249), and the
    gap between tiles is the page. A card is solid white with no alt tile in it,
    so requiring BOTH colours on a row picks out the board and nothing else.
    """
    w, h = im.size
    px = im.load()
    top, bot = content_band(im)

    ALT = (240, 242, 249)

    def is_w(p):
        return p[0] >= 252 and p[1] >= 252 and p[2] >= 252

    def is_a(p):
        return all(abs(p[i] - ALT[i]) <= 2 for i in range(3))

    rows = []
    for y in range(top, bot, 2):
        # Only long flat runs count. A card's border is the same colour as a
        # tile to within a few units, but it is a thin line, and using it
        # stretched the board rect across the program listing.
        nw = 0
        first = last = None
        run = 0
        start = 0
        for x in range(0, w, 3):
            p = px[x, y]
            if is_w(p):
                nw += 1
            if is_a(p):
                if run == 0:
                    start = x
                run += 3
            else:
                if run >= 30:
                    if first is None:
                        first = start
                    last = start + run
                run = 0
        if run >= 30:
            if first is None:
                first = start
            last = start + run
        if nw > w * 0.05 / 3 and first is not None:
            rows.append((y, first, last))

    if not rows:
        return None
    runs, cur = [], [rows[0]]
    for r in rows[1:]:
        if r[0] - cur[-1][0] <= 34:   # tile gaps leave blank rows mid-board
            cur.append(r)
        else:
            runs.append(cur)
            cur = [r]
    runs.append(cur)
    run = max(runs, key=len)
    if len(run) < 6:
        return None

    # The alt tiles stop one inset short of the board edge; the union across
    # rows covers every column because the colours alternate.
    x0 = min(r[1] for r in run)
    x1 = max(r[2] for r in run)
    pad = 3
    return (x0 - pad, run[0][0] - pad, x1 + pad, run[-1][0] + pad)


def cell_center(rect, bw, bh, cx, cy):
    """Screen point of board cell (cx, cy), y counting up from the bottom row."""
    x0, y0, x1, y1 = rect
    cw = (x1 - x0) / bw
    ch = (y1 - y0) / bh
    return (int(x0 + (cx + 0.5) * cw), int(y0 + (bh - 1 - cy + 0.5) * ch))


def card_groups(im, min_frac=0.45):
    """White bands merged back into whole cards.

    A card's own text breaks the white scan into slices — an option card with an
    arrow row and a label row reads as three bands, which made "the third
    option" point at the middle of the second one. A slice belongs to the card
    above it when it is short, or when it sits right underneath it.
    """
    bands = white_cards(im, min_frac=min_frac, min_h=12)
    if not bands:
        return []
    groups = [list(bands[0])]
    for b in bands[1:]:
        h = b[3] - b[1]
        gap = b[1] - groups[-1][3]
        if h < 40 or gap < 30:
            groups[-1][2] = max(groups[-1][2], b[2])
            groups[-1][3] = b[3]
        else:
            groups.append(list(b))
    return [tuple(g) for g in groups]


def chip_row(im, n):
    """The tray: the lowest band holding exactly [n] separate white chips.

    Scanned at several heights, because a chip's own arrow splits it into two
    white runs — at one height a row of three chips counts as six.
    """
    w, h = im.size
    px = im.load()
    found = []
    for (x0, y0, x1, y1) in white_cards(im, min_frac=0.08, min_h=30):
        for frac in (0.12, 0.2, 0.85, 0.5):
            y = int(y0 + (y1 - y0) * frac)
            blocks, run, start = [], 0, 0
            for x in range(0, w, 3):
                if _is_white(px[x, y]):
                    if run == 0:
                        start = x
                    run += 3
                else:
                    if run > w * 0.06:
                        blocks.append((start, start + run))
                    run = 0
            if run > w * 0.06:
                blocks.append((start, start + run))
            if len(blocks) == n:
                found.append([((a + b) // 2, y) for a, b in blocks])
                break
    return found[-1] if found else []
