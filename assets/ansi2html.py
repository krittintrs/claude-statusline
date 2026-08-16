#!/usr/bin/env python3
"""Render ANSI-colored terminal text (from stdin) to a standalone HTML page,
for screenshotting with a real browser (proper emoji + box-drawing glyph
fallback, unlike hand-picking a single monospace font). Pair with a headless
browser screenshot of the `#term` element, then (optionally) `mac-frame`'s
frame.py for window chrome.
Supports: reset, bold, dim, basic 16 fg, bright fg (90-97), truecolor 38;2;r;g;b."""
import sys, re, html

BASIC = {
    30:"#2e3436",31:"#cc4a3f",32:"#4e9a06",33:"#c4a000",34:"#3465a4",
    35:"#75507b",36:"#06989a",37:"#d3d7cf",
    90:"#6b6b6b",91:"#ef5350",92:"#8ae234",93:"#fce94f",94:"#729fcf",
    95:"#ad7fa8",96:"#34e2e2",97:"#ffffff",
}
FG_DEFAULT = "#d0d0d0"
BG = "#1e1e1e"
FONT = "ui-monospace, 'SF Mono', 'DejaVu Sans Mono', Menlo, Consolas, monospace"
FONT_SIZE = "28px"
LINE_HEIGHT = "38px"
PAD = "28px"

def parse(line):
    """Yield (text, color, bold, dim) spans for one line."""
    color, bold, dim = FG_DEFAULT, False, False
    out, pos = [], 0
    tok = re.compile(r'\033\[([0-9;]*)m')
    for m in tok.finditer(line):
        if m.start() > pos:
            buf = line[pos:m.start()]
            if buf:
                out.append((buf, color, bold, dim))
        codes = [int(c) if c else 0 for c in m.group(1).split(';')]
        j = 0
        while j < len(codes):
            c = codes[j]
            if c == 0: color, bold, dim = FG_DEFAULT, False, False
            elif c == 1: bold = True
            elif c == 2: dim = True
            elif c == 22: bold = dim = False
            elif c == 38 and j+1 < len(codes) and codes[j+1] == 2:
                r,g,b = codes[j+2], codes[j+3], codes[j+4]
                color = f"#{r:02x}{g:02x}{b:02x}"; j += 4
            elif c == 38 and j+1 < len(codes) and codes[j+1] == 5:
                j += 2  # 256-color: skip (rare in our output)
            elif c in BASIC: color = BASIC[c]
            elif c == 39: color = FG_DEFAULT
            j += 1
        pos = m.end()
    if pos < len(line):
        out.append((line[pos:], color, bold, dim))
    return out

def main():
    raw = sys.stdin.read().rstrip('\n')
    lines = raw.split('\n')

    body = []
    for line in lines:
        spans = []
        for text, color, bold, dim in parse(line):
            style = f"color:{color}"
            if bold: style += ";font-weight:700"
            if dim:  style += ";opacity:.55"
            spans.append(f'<span style="{style}">{html.escape(text)}</span>')
        body.append("".join(spans) or "&nbsp;")

    print(f"""<!doctype html>
<html><head><meta charset="utf-8"><style>
  html,body {{ margin:0; padding:0; background:{BG}; }}
  #term {{
    display:inline-block; background:{BG}; padding:{PAD};
    font-family:{FONT}; font-size:{FONT_SIZE}; line-height:{LINE_HEIGHT};
    white-space:pre; color:{FG_DEFAULT};
  }}
</style></head><body><div id="term">""" + "\n".join(body) + "</div></body></html>")

if __name__ == "__main__":
    main()
