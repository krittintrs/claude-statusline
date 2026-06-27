# Display styles

Ways to render any field. The script prints ANSI-coded text to stdout; each `printf`/`echo` line is a separate row. Mix freely.

## Text emphasis
| Style | ANSI | Reads as |
|-------|------|----------|
| Bold | `\033[1m` | Primary / anchor (e.g. dir name) |
| Plain white | `\033[97m` | Important value (model, %, cost) |
| Dim | `\033[2m` | Secondary / supporting (effort, countdown) |
| Normal | — | Default terminal foreground |

## Color
| Mode | Example | Notes |
|------|---------|-------|
| Basic 16 | `\033[32m` (green) | Widest support |
| 256-color | `\033[38;5;208m` | Orange, etc. |
| Truecolor / hex | `\033[38;2;220;40;20m` | Full RGB — used for the ctx gradient |
| Threshold color | green < 50, yellow 50–79, red 80+ | Drives rate-limit + ctx coloring |

Always end colored spans with `\033[0m` (reset).

## Bars & meters
| Style | Look | Used for |
|-------|------|----------|
| Solid bar | `███░░░░░░░` | Rate limits (single threshold color) |
| Truecolor gradient bar | green→yellow→red across the fill | Context usage |
| Raw percent | `42%` | Minimalist, no bar |

Bar = N filled blocks (`█`) + (10−N) empty (`░`), N = pct/10.

## Icons
| Style | Example |
|-------|---------|
| Range emoji | 🌿 < 50 / ⚡ 50–79 / 🔥 80+ (context health) |
| Static glyph | `⎇` branch, `◷` reset clock, `📁` dir, `🌿` git |
| Tree prefix | `├` / `└` for stacked rows |

## Layout
| Style | How |
|-------|-----|
| Multi-line | One `printf` per row — line 1 summary, lines 2–3 rate limits |
| Inline separators | ` │ ` between segments on one line |
| Powerline | Arrow separators `` with colored background caps (needs a Nerd/Powerline font) |
| Minimalist / raw | Drop labels, show bare values only |
| Truncation | Use `COLUMNS` to clip long fields on narrow terminals |

## Clickable links
Wrap text in OSC 8 escapes to make it clickable (iTerm2/Kitty/WezTerm):
`printf '%b' "\e]8;;${url}\a${text}\e]8;;\a\n"`. Good for PR URLs or repo links.

## Ecosystem references (for richer ideas)
- [ccstatusline](https://github.com/sirmalloc/ccstatusline) — powerline, 30+ widgets, themes, gradient stops
- [claude-statusline-powerline](https://github.com/spences10/claude-statusline-powerline) — powerline segments + git status counts
- Official examples: https://code.claude.com/docs/en/statusline#examples
