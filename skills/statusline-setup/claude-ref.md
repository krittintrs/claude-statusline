# Claude Code — Script template & customisation reference

## Script template

The canonical default script is **`statusline.sh`** in the repo root — read it for the full, hardened source (jq → python → PowerShell parser fallback, cross-platform). When the skill runs, use that file as the base and apply the user's customisations below before writing to `~/.claude/statusline.sh`.

If `statusline.sh` is not adjacent (skill installed standalone), fetch it:
```bash
curl -fsSL https://raw.githubusercontent.com/krittintrs/claude-statusline/main/statusline.sh
```

The script is organised so each display field sits in its own block marked `# [FIELD: name]`. Add, remove, or reorder these blocks to customise. Line 1 is assembled into `$out` and printed once; rate limits print on lines 2–3.

---

## Customisation reference

When the user requests a change, find the matching row and edit the script accordingly.

| Request | What to change |
|---------|---------------|
| Remove a field | Delete the `# [FIELD: name]` block entirely |
| No icon on ctx | Remove the `ctx_icon=` lines; change the final `out=` to `${bar} ${WHITE}${used_int}%${RESET}` |
| Plain text ctx instead of gradient | Replace the `[FIELD: ctx]` block body with: `c=$(pct_color "$used_pct"); out="${out}${SEP}${c}ctx: ${used_int}%${RESET}"` |
| Rate limits inline (not separate lines) | Build `rl5`/`rl7` strings into `$out` with `${SEP}`; delete the two `printf` blocks at the bottom |
| No rate-limit countdown | Remove `cd=$(mk_countdown ...)` and ` ◷ ${cd}` from the printf lines |
| Change color thresholds | Edit the values in `pct_color()` (default 50 / 80) |
| Reorder line-1 fields | Move `# [FIELD: ...]` blocks within the Line 1 section |
| Different separator | Change `SEP=` (default ` │ `) |
| Add session duration | After the cost block: `dur=$("$JQ" -r '.cost.total_duration_ms // empty' <<< "$input"); [ -n "$dur" ] && out="${out}${SEP}${DIM}$(( dur / 60000 ))m${RESET}"` |
| Add PR number | After the model block: `pr=$("$JQ" -r '.pr.number // empty' <<< "$input"); [ -n "$pr" ] && out="${out}${SEP}${WHITE}PR#${pr}${RESET}"` |
| Add git worktree elsewhere | The `[wt: ...]` segment is in the dir+branch block — move or restyle it |

For the full list of fields you can pull, see [fields-ref.md]. For display styles, see [styles-ref.md].

---

## settings.json block

```json
"statusLine": {
  "type": "command",
  "command": "~/.claude/statusline.sh",
  "refreshInterval": 60
}
```

`refreshInterval: 60` re-runs the script every 60 seconds so rate-limit countdowns stay live during idle sessions. Minimum is `1`; leave unset to run only on events (new assistant message, `/compact` finish, permission-mode change, vim toggle, session start).

**Updates debounce at 300ms** — rapid triggers batch into one run. If a new trigger fires while the script is still running, Claude Code **cancels the in-flight run**. Keep scripts fast (cache slow calls below); a script that routinely takes longer than the update cadence just gets killed mid-run and never shows fresh output.

Enabling a custom `statusLine` also **hides most footer keyboard hints** (`esc to interrupt`, `? for shortcuts`, the voice-dictation hint) — that's expected, not a bug the script needs to work around.

**Other optional `statusLine` keys:**
| Key | Effect |
|-----|--------|
| `padding` | Extra horizontal indent in characters (default `0`), on top of the built-in spacing |
| `hideVimModeIndicator` | `true` suppresses the built-in `-- INSERT --` text — set it when the script renders `vim.mode` itself, so it isn't shown twice |

## Performance: cache slow git calls

The script runs on every update trigger. If it shells out to `git` on each run, cache the result to a temp file keyed on **`session_id`** (stable per session, unique across sessions) — not `$$`/PID, which changes every invocation and defeats the cache. Refresh only when the cache is older than ~5s.

## Subagent rows — `subagentStatusLine`

A *separate* setting customises each subagent's row in the agent panel (Claude Code v2.1.205+):
```json
"subagentStatusLine": {
  "type": "command",
  "command": "~/.claude/subagent-statusline.sh"
}
```
The command runs once per refresh tick and receives the base hook fields, a `columns` field (usable row width), and a `tasks[]` array on stdin. Each task has `id`, `name`, `type`, `status`, `description`, `label`, `startTime`, `model`, `effort`, `contextWindowSize`, `tokenCount`, `tokenSamples`, `cwd`. `model`/`contextWindowSize` require v2.1.205+; `effort` (the level string or a numeric token budget) requires v2.1.214+ and is absent when the subagent inherits the session's effort. Write one JSON line per row to override: `{"id":"<task id>","content":"<row body>"}` (ANSI + OSC8 allowed). Omit a task's `id` to keep its default row; emit empty `content` to hide it. Only pursue this if the user explicitly wants to style subagent rows.

## Troubleshooting gotchas worth knowing

- **`allowManagedHooksOnly`** (an org policy in managed settings) makes a user's custom `statusLine` disappear silently — only a `statusLine` set in *managed* settings survives. If a user's script looks correct but nothing shows, ask whether their org enforces this.
- **Workspace trust**: `statusLine` runs under the same trust gate as hooks. Until the folder (or a parent) is trusted, the status line stays blank and `claude --debug` logs `Status line command skipped: workspace trust not accepted`.
- `claude --debug` is the fastest way to see a script's exit code and stderr from its first invocation in a session.
