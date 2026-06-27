# claude-statusline

A curated, good-looking statusline for [Claude Code](https://claude.com/claude-code) — plus a guided skill to customize it in plain English.

![default statusline](assets/default.png)

```
vibe ⎇ main  │  Sonnet 4.6 medium  │  🌿 ████░░░░░░ 42%  │  $0.85
├ 5h: ░░░░░░░░░░   2% ◷ 4h 50m
└ 7d: ███░░░░░░░  35% ◷ 18h 0m
```

A truecolor gradient context bar, live rate-limit countdowns, git branch/worktree, model, effort, and session cost — all in one always-visible bar below your prompt.

---

## Quick install

```bash
curl -fsSL https://raw.githubusercontent.com/krittintrs/claude-statusline/main/install.sh | bash
```

This downloads `statusline.sh` to `~/.claude/`, backs up and patches your `settings.json`, and you're done. Restart Claude Code (or send a prompt) to see it.

**Requirements:** `jq` (recommended) or `python3`. The script falls back gracefully. On Windows, run inside **Git Bash** — Claude Code executes the statusline through it.

---

## What it shows

| Segment | Example | Notes |
|---------|---------|-------|
| Repo / dir | `vibe` | Bold cyan; from `repo.name` or folder |
| Git branch | `⎇ main` | Dim cyan; truncates on narrow terminals |
| Git worktree | `[wt: feat-ui]` | Only when inside a linked worktree |
| Model + effort | `Sonnet 4.6 medium` | |
| Context usage | `🌿 ████░░░░░░ 42%` | Gradient bar + 🌿/⚡/🔥 health icon |
| Session cost | `$0.85` | |
| 5h / 7d rate limits | `5h: ░░░░░░░░░░ 2% ◷ 4h 50m` | Bar + countdown (Pro/Max only) |

---

## The design choices

This isn't a kitchen-sink widget dump — every choice is deliberate:

- **Gradient context bar** carries the "how full am I" signal by color *and* icon, so no label is needed — 🌿 under 50%, ⚡ 50–79%, 🔥 80%+.
- **White labels, colored values.** Rate-limit labels (`5h:` `7d:`) stay white and stable; only the bar and percent take threshold color (green → yellow → red). The row signals danger without screaming.
- **Tree-prefixed rate limits** (`├` `└`) on their own lines keep line 1 clean and scannable.
- **Same-hue dir + branch** (bold cyan + dim cyan) reads as one "location" unit without adding a competing color.
- **Space-padded percent** so the reset clock always aligns across rows.
- **`refreshInterval: 60`** keeps countdowns ticking even when the session is idle.

---

## Customize it

Want it different? Install the skill and just describe what you want:

```bash
# copy the skill into your Claude Code skills dir
cp -r skills/statusline-setup ~/.claude/skills/
```

Then in Claude Code:
```
/statusline-setup
```

The skill walks you through it — shows your current statusline, lists every available field and display style, previews changes live, and writes the result only when you're happy. Say things like *"remove cost"*, *"plain text instead of the gradient"*, *"add PR number"*, *"rate limits on one line"*.

- [Available fields](skills/statusline-setup/fields-ref.md) — everything you can show
- [Display styles](skills/statusline-setup/styles-ref.md) — every way to show it

---

## Manual install

If you'd rather not pipe to bash:

1. Copy `statusline.sh` to `~/.claude/statusline.sh` and `chmod +x` it.
2. Add to `~/.claude/settings.json`:
   ```json
   "statusLine": {
     "type": "command",
     "command": "~/.claude/statusline.sh",
     "refreshInterval": 60
   }
   ```
3. Restart Claude Code.

---

## Credits

Inspired by the Claude Code statusline ecosystem — [ccstatusline](https://github.com/sirmalloc/ccstatusline), [claude-statusline-powerline](https://github.com/spences10/claude-statusline-powerline), and the [official docs](https://code.claude.com/docs/en/statusline).

## License

MIT
