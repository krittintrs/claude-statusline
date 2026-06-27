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

`refreshInterval: 60` re-runs the script every 60 seconds so rate-limit countdowns stay live during idle sessions.
