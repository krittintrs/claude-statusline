---
name: statusline-setup
description: Set up or modify the Claude Code statusline — the information bar below every prompt. Ships a curated default design and can explore every available field and display style, then writes the script and patches settings.
disable-model-invocation: true
---

# statusline-setup

The statusline is a shell script that reads session JSON on stdin and prints a colored, multi-line bar below every prompt. This skill installs or modifies it.

Script lives at `~/.claude/statusline.sh`. Config goes in `~/.claude/settings.json`.

**The curated default:**
```
vibe ⎇ main  │  Sonnet 5 medium  │  🌿 ████░░░░░░ 42%  │  $0.85
├ 5h: ░░░░░░░░░░   2% ◷ 4h 50m
└ 7d: ███░░░░░░░  35% ◷ 18h 0m
```

Work through the steps in order. The whole point is to **land on a design the user is happy with, then write it** — never write before they confirm.

---

## Step 1 — Orient

Check whether `~/.claude/statusline.sh` exists.

**If it exists — they already have a statusline.** Render it with sample data:
```bash
now=$(date +%s)
printf '{
  "model":{"display_name":"Sonnet 5"},
  "context_window":{"used_percentage":42},
  "cost":{"total_cost_usd":0.85},
  "workspace":{"current_dir":"/home/user/myproject","repo":{"name":"myproject"}},
  "rate_limits":{
    "five_hour":{"used_percentage":42,"resets_at":%d},
    "seven_day":{"used_percentage":83,"resets_at":%d}
  },
  "effort":{"level":"medium"}
}' $((now + 14520)) $((now + 185400)) | bash ~/.claude/statusline.sh
```
Show the rendered output and ask:
> "This is your current statusline. What would you like to change?"

Take their answer and go to **Step 3** (discuss & preview).

**If it does not exist — they have none.** Explain in one or two sentences what a statusline is (a always-visible bar showing context usage, cost, git, rate limits). Then ask which way they want to start:
> "You don't have a statusline yet. Want to **install the curated default**, or **explore the available fields and styles first** and build your own?"

- Default → go to **Step 3** with the default design.
- Explore → go to **Step 2**.

---

## Step 2 — Explore (only when the user wants to)

Pull only what they ask for:

- **What can I show?** → read [fields-ref.md] and present the available data fields.
- **How can it look?** → read [styles-ref.md] and present the display styles.
- **Both / not sure** → present both.

Let them react and pick. This step repeats freely — they can keep asking before committing. When they have a direction, go to **Step 3**.

---

## Step 3 — Discuss & preview

Build the script per the template and **Customisation reference** in [claude-ref.md], applying whatever the user chose. Write it to a temp file and render:
```bash
now=$(date +%s)
printf '{
  "model":{"display_name":"Sonnet 5"},
  "context_window":{"used_percentage":42},
  "cost":{"total_cost_usd":0.85},
  "workspace":{"current_dir":"/home/user/myproject","repo":{"name":"myproject"}},
  "rate_limits":{
    "five_hour":{"used_percentage":42,"resets_at":%d},
    "seven_day":{"used_percentage":83,"resets_at":%d}
  },
  "effort":{"level":"medium"}
}' $((now + 14520)) $((now + 185400)) | bash /tmp/statusline-preview.sh
```
Show the output and ask:
> "Happy with this? Say yes to install, or describe what to change."

Loop here — re-render after every tweak. Only move on when the user explicitly confirms. Do not write to `~/.claude/` during this loop.

---

## Step 4 — Apply

Only after explicit confirmation.

**4a — Write the script** to `~/.claude/statusline.sh`, then `chmod +x ~/.claude/statusline.sh`.

**4b — Patch `~/.claude/settings.json`.** Read it, merge in (overwrite if present):
```json
"statusLine": {
  "type": "command",
  "command": "~/.claude/statusline.sh",
  "refreshInterval": 60
}
```
`refreshInterval: 60` re-runs the script every 60s so rate limit countdowns stay live during idle sessions.

**4c — Confirm** the statusline is live on the next prompt. If it doesn't appear, check:
- Script is executable (`chmod +x`)
- `disableAllHooks` is not `true` in settings.json
- Workspace trust was accepted — restart and accept the prompt if unsure
- `claude --debug` logs the script's exit code and stderr
