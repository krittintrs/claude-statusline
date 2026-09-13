#!/usr/bin/env bash
# claude-statusline — a curated statusline for Claude Code.
# Reads session JSON on stdin, prints a colored multi-line bar.
# Works on macOS, Linux, and Windows (via Git Bash). Parser priority: jq → python → PowerShell.
input=$(cat)

RESET=$'\033[0m'
BOLD=$'\033[1m'
DIM=$'\033[2m'
GREEN=$'\033[32m'
YELLOW=$'\033[33m'
RED=$'\033[31m'
CYAN=$'\033[36m'
WHITE=$'\033[97m'
GRAY=$'\033[90m'

SEP="${DIM} | ${RESET}"

# ── Config ────────────────────────────────────────────────────────────────────
# How aggressively folder/worktree/branch clip on a narrow terminal: each field
# gets a COLUMNS/FIELD_WIDTH_DIVISOR budget. Line 1 also carries the model,
# effort, context bar, and cost after these three fields, so don't set this so
# low (i.e. too generous a per-field budget) that those get pushed off the
# line — raise the divisor for tighter clipping, lower it to allow more.
FIELD_WIDTH_DIVISOR=8

pct_color() {
  local p; p=$(printf '%.0f' "$1" 2>/dev/null)
  if   [ "${p:-0}" -ge 80 ]; then printf '%s' "$RED"
  elif [ "${p:-0}" -ge 50 ]; then printf '%s' "$YELLOW"
  else                            printf '%s' "$GREEN"
  fi
}

# 10-cell bar for a 0-100 percentage. spend_limit can report over 100 once
# exceeded, so the fill is capped at 10/10 rather than overflowing the bar.
mk_bar() {
  local pct="${1:-0}" f e i out=""
  f=$(( pct / 10 )); [ "$f" -gt 10 ] && f=10; [ "$f" -lt 0 ] && f=0
  e=$(( 10 - f ))
  i=0; while [ $i -lt $f ]; do out="${out}█"; i=$((i+1)); done
  i=0; while [ $i -lt $e ]; do out="${out}░"; i=$((i+1)); done
  printf '%s' "$out"
}

mk_countdown() {
  local resets="$1" style="$2"
  [ -z "$resets" ] || [ "$resets" = "None" ] && return
  local now; now=$(date +%s 2>/dev/null); [ -z "$now" ] && return
  local rem=$(( resets - now )); [ "$rem" -le 0 ] && return
  local d=$(( rem / 86400 )) h=$(( (rem % 86400) / 3600 )) m=$(( (rem % 3600) / 60 ))
  if [ "$style" = "dhm" ]; then
    [ "$d" -gt 0 ] && echo "${d}d ${h}h" || { [ "$h" -gt 0 ] && echo "${h}h ${m}m" || echo "${m}m"; }
  else
    [ "$h" -gt 0 ] && echo "${h}h ${m}m" || echo "${m}m"
  fi
}

# ── Parser detection: jq → python → PowerShell ────────────────────────────────
JQ=""; PYTHON=""
for c in jq /usr/bin/jq /usr/local/bin/jq /opt/homebrew/bin/jq /mingw64/bin/jq \
          "/c/Program Files/Git/usr/bin/jq.exe" "/c/ProgramData/chocolatey/bin/jq.exe"; do
  if command -v "$c" >/dev/null 2>&1 || [ -f "$c" ]; then JQ="$c"; break; fi
done
if [ -z "$JQ" ]; then
  for c in python3 python \
      "$HOME/AppData/Local/Programs/Python/Python313/python.exe" \
      "$HOME/AppData/Local/Programs/Python/Python312/python.exe" \
      "$HOME/AppData/Local/Programs/Python/Python311/python.exe"; do
    _py=$(command -v "$c" 2>/dev/null || ([ -f "$c" ] && echo "$c"))
    [[ "$_py" == *"WindowsApps"* ]] && continue
    if [ -n "$_py" ] && "$_py" -c "import sys" 2>/dev/null; then PYTHON="$_py"; break; fi
  done
fi

# ── Parse fields ──────────────────────────────────────────────────────────────
if [ -n "$JQ" ]; then
  current_dir=$("$JQ" -r '.workspace.current_dir // .cwd // empty' <<< "$input" 2>/dev/null)
  repo_name=$("$JQ" -r '.workspace.repo.name // empty'           <<< "$input" 2>/dev/null)
  worktree=$("$JQ" -r '.workspace.git_worktree // empty'          <<< "$input" 2>/dev/null)
  model=$("$JQ" -r '.model.display_name // empty'                 <<< "$input" 2>/dev/null)
  effort=$("$JQ" -r '.effort.level // empty'                      <<< "$input" 2>/dev/null)
  used_pct=$("$JQ" -r '.context_window.used_percentage // empty'  <<< "$input" 2>/dev/null)
  cost=$("$JQ" -r '.cost.total_cost_usd // empty'                 <<< "$input" 2>/dev/null)
  rl5_pct=$("$JQ" -r '.rate_limits.five_hour.used_percentage // empty' <<< "$input" 2>/dev/null)
  rl5_resets=$("$JQ" -r '.rate_limits.five_hour.resets_at // empty'    <<< "$input" 2>/dev/null)
  rl7_pct=$("$JQ" -r '.rate_limits.seven_day.used_percentage // empty' <<< "$input" 2>/dev/null)
  rl7_resets=$("$JQ" -r '.rate_limits.seven_day.resets_at // empty'    <<< "$input" 2>/dev/null)
  spend_pct=$("$JQ" -r '.rate_limits.spend_limit.used_percentage // empty' <<< "$input" 2>/dev/null)
  spend_resets=$("$JQ" -r '.rate_limits.spend_limit.resets_at // empty'    <<< "$input" 2>/dev/null)

elif [ -n "$PYTHON" ]; then
  parsed=$(printf '%s\n' "$input" | "$PYTHON" -c "
import sys, json
try:
    d = json.loads(sys.stdin.read().strip())
    ws  = d.get('workspace') or {}
    rl  = d.get('rate_limits') or {}
    rl5 = rl.get('five_hour') or {}
    rl7 = rl.get('seven_day') or {}
    spend = rl.get('spend_limit') or {}
    repo = ws.get('repo') or {}
    f = [
        (d.get('model') or {}).get('display_name',''),
        str(ws.get('current_dir') or d.get('cwd') or '.'),
        repo.get('name',''),
        ws.get('git_worktree',''),
        str((d.get('context_window') or {}).get('used_percentage','')),
        str((d.get('cost') or {}).get('total_cost_usd','')),
        str(rl5.get('used_percentage','')), str(rl5.get('resets_at','')),
        str(rl7.get('used_percentage','')), str(rl7.get('resets_at','')),
        str(spend.get('used_percentage','')), str(spend.get('resets_at','')),
        str((d.get('effort') or {}).get('level','')),
    ]
    sys.stdout.write('\n'.join(f) + '\n')
except Exception:
    fallback = [''] * 13
    fallback[1] = '.'
    sys.stdout.write('\n'.join(fallback) + '\n')
" 2>/dev/null | tr -d '\r')
  mapfile -t _f <<< "$parsed"
  model="${_f[0]:-}";     current_dir="${_f[1]:-.}";  repo_name="${_f[2]:-}"
  worktree="${_f[3]:-}";  used_pct="${_f[4]:-}";      cost="${_f[5]:-}"
  rl5_pct="${_f[6]:-}";   rl5_resets="${_f[7]:-}";    rl7_pct="${_f[8]:-}"
  rl7_resets="${_f[9]:-}"; spend_pct="${_f[10]:-}";   spend_resets="${_f[11]:-}"
  effort="${_f[12]:-}"

else
  # PowerShell fallback (Windows without jq/python)
  _tmp=$(mktemp 2>/dev/null || echo "/tmp/cstatus-$$.json")
  printf '%s' "$input" > "$_tmp"
  _wintmp=$(cygpath -w "$_tmp" 2>/dev/null || echo "$_tmp")
  parsed=$(powershell.exe -NoProfile -NonInteractive -Command "
    \$d = Get-Content -Raw '$_wintmp' | ConvertFrom-Json -ErrorAction SilentlyContinue
    if (\$d) {
      \$ws=\$d.workspace; \$rl=\$d.rate_limits
      \$rl5=if(\$rl){\$rl.five_hour}; \$rl7=if(\$rl){\$rl.seven_day}; \$spend=if(\$rl){\$rl.spend_limit}
      \"\$(\$d.model.display_name)\`n\$(if(\$ws){\$ws.current_dir})\`n\$(if(\$ws){\$ws.repo.name})\`n\$(if(\$ws){\$ws.git_worktree})\`n\$(\$d.context_window.used_percentage)\`n\$(\$d.cost.total_cost_usd)\`n\$(if(\$rl5){\$rl5.used_percentage})\`n\$(if(\$rl5){\$rl5.resets_at})\`n\$(if(\$rl7){\$rl7.used_percentage})\`n\$(if(\$rl7){\$rl7.resets_at})\`n\$(if(\$spend){\$spend.used_percentage})\`n\$(if(\$spend){\$spend.resets_at})\`n\$(\$d.effort.level)\"
    }
  " 2>/dev/null | tr -d '\r')
  rm -f "$_tmp"
  mapfile -t _f <<< "$parsed"
  model="${_f[0]:-}";     current_dir="${_f[1]:-.}";  repo_name="${_f[2]:-}"
  worktree="${_f[3]:-}";  used_pct="${_f[4]:-}";      cost="${_f[5]:-}"
  rl5_pct="${_f[6]:-}";   rl5_resets="${_f[7]:-}";    rl7_pct="${_f[8]:-}"
  rl7_resets="${_f[9]:-}"; spend_pct="${_f[10]:-}";   spend_resets="${_f[11]:-}"
  effort="${_f[12]:-}"
fi

# ── Git context ───────────────────────────────────────────────────────────────
branch=$(git -C "${current_dir:-$(pwd)}" -c gc.auto=0 branch --show-current 2>/dev/null)
display_name="${repo_name:-$(basename "${current_dir:-$(pwd)}")}"

# Clip long fields on narrow terminals: folder, worktree, and branch each get
# their own COLUMNS/FIELD_WIDTH_DIVISOR budget (see Config, above) so no single
# long field (e.g. an auto-generated worktree name) can blow past the line on
# its own — and so the three of them together still leave room for the rest
# of line 1 (model, effort, context bar, cost).
trunc_field() {
  local s="$1" max="$2"
  [ "$max" -ge 1 ] && [ "${#s}" -gt "$max" ] && printf '%s' "${s:0:$(( max > 1 ? max - 1 : 0 ))}…"
}

if [ -n "$COLUMNS" ] && [ "$COLUMNS" -gt 0 ]; then
  max_field=$(( COLUMNS / FIELD_WIDTH_DIVISOR ))
  t=$(trunc_field "$display_name" "$max_field"); [ -n "$t" ] && display_name="$t"
  t=$(trunc_field "$worktree" "$max_field");     [ -n "$t" ] && worktree="$t"
  t=$(trunc_field "$branch" "$max_field");       [ -n "$t" ] && branch="$t"
fi

# ── Line 1 ────────────────────────────────────────────────────────────────────
# [FIELD: dir+branch]
out="${BOLD}${CYAN}${display_name}${RESET}"
[ -n "$worktree" ] && out="${out} ${DIM}${GRAY}[wt: ${worktree}]${RESET}"
[ -n "$branch"   ] && out="${out} ${DIM}${CYAN}⎇ ${branch}${RESET}"

# [FIELD: model+effort]
if [ -n "$model" ] && [ "$model" != "None" ]; then
  out="${out}${SEP}${WHITE}${model}${RESET}"
  [ -n "$effort" ] && [ "$effort" != "None" ] && out="${out} ${DIM}${effort}${RESET}"
fi

# [FIELD: ctx] — truecolor gradient bar + emoji icon
if [ -n "$used_pct" ] && [ "$used_pct" != "None" ]; then
  used_int=$(printf '%.0f' "$used_pct" 2>/dev/null)
  filled=$(( used_int / 10 ))
  if   [ "${used_int:-0}" -ge 80 ]; then ctx_icon="🔥"
  elif [ "${used_int:-0}" -ge 50 ]; then ctx_icon="⚡"
  else                                    ctx_icon="🌿"
  fi
  _e=$'\033'
  bar=""; i=1
  while [ $i -le 10 ]; do
    pos=$(( (i - 1) * 100 / 9 ))
    if [ "$pos" -le 50 ]; then
      _r=$(( 220 * pos / 50 )); _g=200; _b=$(( 80 - 80 * pos / 50 ))
    else
      _adj=$(( pos - 50 )); _r=220; _g=$(( 200 - 160 * _adj / 50 )); _b=$(( 20 * _adj / 50 ))
    fi
    if [ "$i" -le "$filled" ]; then
      bar="${bar}${_e}[38;2;${_r};${_g};${_b}m█${_e}[0m"
    else
      bar="${bar}${_e}[2m░${_e}[0m"
    fi
    i=$((i+1))
  done
  out="${out}${SEP}${ctx_icon} ${bar} ${WHITE}${used_int}%${RESET}"
fi

# [FIELD: cost]
if [ -n "$cost" ] && [ "$cost" != "None" ]; then
  fmt_cost=$(printf '%.2f' "$cost" 2>/dev/null)
  [ -n "$fmt_cost" ] && out="${out}${SEP}${WHITE}\$${fmt_cost}${RESET}"
fi

printf '%b\n' "$out"

# ── Rate-limit stale-cache fallback ─────────────────────────────────────────────
# rate_limits is absent right after session start/resume/`/clear` (no API
# response yet) and briefly again once a window's resets_at passes. Rather than
# dropping the row (which reads as a glitch), fall back to the last-seen value
# from a small cache file and mark it (stale). Expired entries are never
# written back, so a rolled-over window naturally falls off the cache too.
CACHE_FILE="${HOME}/.claude/.statusline-rl-cache"
cache_get() { grep -m1 "^$1=" "$CACHE_FILE" 2>/dev/null | cut -d= -f2-; }

now_ts=$(date +%s 2>/dev/null)
c_rl5_pct=$(cache_get RL5_PCT); c_rl5_resets=$(cache_get RL5_RESETS)
c_rl7_pct=$(cache_get RL7_PCT); c_rl7_resets=$(cache_get RL7_RESETS)
c_spend_pct=$(cache_get RL_SPEND_PCT); c_spend_resets=$(cache_get RL_SPEND_RESETS)

rl5_stale=""; rl7_stale=""; spend_stale=""
if { [ -z "$rl5_pct" ] || [ "$rl5_pct" = "None" ]; } \
   && [ -n "$c_rl5_resets" ] && [ -n "$now_ts" ] && [ "$c_rl5_resets" -gt "$now_ts" ] 2>/dev/null; then
  rl5_pct="$c_rl5_pct"; rl5_resets="$c_rl5_resets"; rl5_stale=1
fi
if { [ -z "$rl7_pct" ] || [ "$rl7_pct" = "None" ]; } \
   && [ -n "$c_rl7_resets" ] && [ -n "$now_ts" ] && [ "$c_rl7_resets" -gt "$now_ts" ] 2>/dev/null; then
  rl7_pct="$c_rl7_pct"; rl7_resets="$c_rl7_resets"; rl7_stale=1
fi
if { [ -z "$spend_pct" ] || [ "$spend_pct" = "None" ]; } \
   && [ -n "$c_spend_resets" ] && [ -n "$now_ts" ] && [ "$c_spend_resets" -gt "$now_ts" ] 2>/dev/null; then
  spend_pct="$c_spend_pct"; spend_resets="$c_spend_resets"; spend_stale=1
fi

{
  [ -n "$rl5_pct" ] && [ "$rl5_pct" != "None" ] && [ -n "$rl5_resets" ] && [ -n "$now_ts" ] \
    && [ "$rl5_resets" -gt "$now_ts" ] 2>/dev/null \
    && printf 'RL5_PCT=%s\nRL5_RESETS=%s\n' "$rl5_pct" "$rl5_resets"
  [ -n "$rl7_pct" ] && [ "$rl7_pct" != "None" ] && [ -n "$rl7_resets" ] && [ -n "$now_ts" ] \
    && [ "$rl7_resets" -gt "$now_ts" ] 2>/dev/null \
    && printf 'RL7_PCT=%s\nRL7_RESETS=%s\n' "$rl7_pct" "$rl7_resets"
  [ -n "$spend_pct" ] && [ "$spend_pct" != "None" ] && [ -n "$spend_resets" ] && [ -n "$now_ts" ] \
    && [ "$spend_resets" -gt "$now_ts" ] 2>/dev/null \
    && printf 'RL_SPEND_PCT=%s\nRL_SPEND_RESETS=%s\n' "$spend_pct" "$spend_resets"
} > "$CACHE_FILE" 2>/dev/null

# ── Lines 2-4: rate limits ────────────────────────────────────────────────────
# spend_limit only appears behind a Claude apps gateway that sets a spend
# limit — most users never see it, and the row is skipped entirely when it's
# absent, same as 5h/7d. Whichever of the three rows is last gets the └
# tree-corner instead of ├.
show5=""; show7=""; shows=""
[ -n "$rl5_pct" ] && [ "$rl5_pct" != "None" ] && [ -n "$rl5_resets" ] && show5=1
[ -n "$rl7_pct" ] && [ "$rl7_pct" != "None" ] && [ -n "$rl7_resets" ] && show7=1
[ -n "$spend_pct" ] && [ "$spend_pct" != "None" ] && [ -n "$spend_resets" ] && shows=1

last_row=""
[ -n "$show5" ] && last_row=5
[ -n "$show7" ] && last_row=7
[ -n "$shows" ] && last_row=s

TREE_MID=$(printf '\xe2\x94\x9c'); TREE_END=$(printf '\xe2\x94\x94')

# [FIELD: 5h]
if [ -n "$show5" ]; then
  rl5_int=$(printf '%.0f' "$rl5_pct" 2>/dev/null)
  bar=$(mk_bar "$rl5_int")
  if [ -n "$rl5_stale" ]; then c="$DIM"; suffix=" ${DIM}(stale)${RESET}"
  else c=$(pct_color "$rl5_pct"); suffix=""; fi
  glyph="$TREE_MID"; [ "$last_row" = 5 ] && glyph="$TREE_END"
  cd=$(mk_countdown "$rl5_resets" "hm")
  printf "${DIM}${glyph}${RESET} ${WHITE}5h:${RESET} ${c}${bar}%3d%%${RESET} ${DIM}◷ ${cd}${RESET}${suffix}\n" "$rl5_int"
fi

# [FIELD: 7d]
if [ -n "$show7" ]; then
  rl7_int=$(printf '%.0f' "$rl7_pct" 2>/dev/null)
  bar=$(mk_bar "$rl7_int")
  if [ -n "$rl7_stale" ]; then c="$DIM"; suffix=" ${DIM}(stale)${RESET}"
  else c=$(pct_color "$rl7_pct"); suffix=""; fi
  glyph="$TREE_MID"; [ "$last_row" = 7 ] && glyph="$TREE_END"
  cd=$(mk_countdown "$rl7_resets" "dhm")
  printf "${DIM}${glyph}${RESET} ${WHITE}7d:${RESET} ${c}${bar}%3d%%${RESET} ${DIM}◷ ${cd}${RESET}${suffix}\n" "$rl7_int"
fi

# [FIELD: spend] — behind a Claude apps gateway spend limit only; used_percentage
# can exceed 100 once the limit is blown past, so the bar just stays full at 10/10.
if [ -n "$shows" ]; then
  spend_int=$(printf '%.0f' "$spend_pct" 2>/dev/null)
  bar=$(mk_bar "$spend_int")
  if [ -n "$spend_stale" ]; then c="$DIM"; suffix=" ${DIM}(stale)${RESET}"
  else c=$(pct_color "$spend_pct"); suffix=""; fi
  glyph="$TREE_MID"; [ "$last_row" = s ] && glyph="$TREE_END"
  cd=$(mk_countdown "$spend_resets" "dhm")
  printf "${DIM}${glyph}${RESET} ${WHITE}spend:${RESET} ${c}${bar}%3d%%${RESET} ${DIM}◷ ${cd}${RESET}${suffix}\n" "$spend_int"
fi
