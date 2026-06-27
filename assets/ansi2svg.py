#!/usr/bin/env python3
"""Render ANSI-colored terminal text (from stdin) to a standalone SVG.
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
CW, CH = 9.0, 20      # char cell width/height
PAD = 16
FONT = "ui-monospace, 'SF Mono', 'DejaVu Sans Mono', Menlo, Consolas, monospace"

def parse(line):
    """Yield (text, color, bold, dim) spans for one line."""
    color, bold, dim = FG_DEFAULT, False, False
    out, i, buf = [], 0, ""
    tok = re.compile(r'\033\[([0-9;]*)m')
    pos = 0
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

def cwidth(ch):
    """Cell width of a char: emoji/wide = 2, else 1."""
    cp = ord(ch)
    if cp == 0x26A1 or cp >= 0x1F000 or 0x2600 <= cp <= 0x27BF:
        return 2
    return 1

def visible_len(line):
    return sum(cwidth(c) for c in re.sub(r'\033\[[0-9;]*m', '', line))

def main():
    raw = sys.stdin.read().rstrip('\n')
    lines = raw.split('\n')
    cols = max((visible_len(l) for l in lines), default=20)
    W = int(PAD*2 + cols*CW)
    H = int(PAD*2 + len(lines)*CH)
    svg = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" '
           f'viewBox="0 0 {W} {H}" font-family="{FONT}" font-size="14">',
           f'<rect width="{W}" height="{H}" rx="8" fill="{BG}"/>']
    y = PAD + 14
    for line in lines:
        x = PAD
        for text, color, bold, dim in parse(line):
            t = html.escape(text)
            # advance x per char to keep monospace alignment even across emoji
            attrs = f'fill="{color}"'
            if bold: attrs += ' font-weight="700"'
            if dim:  attrs += ' opacity="0.55"'
            svg.append(f'<text x="{x:.1f}" y="{y}" xml:space="preserve" {attrs}>{t}</text>')
            x += sum(cwidth(c) for c in text)*CW
        y += CH
    svg.append('</svg>')
    sys.stdout.write('\n'.join(svg) + '\n')

if __name__ == "__main__":
    main()
