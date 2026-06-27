#!/usr/bin/env bash
# claude-statusline installer.
# Usage: curl -fsSL https://raw.githubusercontent.com/krittintrs/claude-statusline/main/install.sh | bash
set -euo pipefail

REPO_RAW="https://raw.githubusercontent.com/krittintrs/claude-statusline/main"
CLAUDE_DIR="${HOME}/.claude"
SCRIPT_DEST="${CLAUDE_DIR}/statusline.sh"
SETTINGS="${CLAUDE_DIR}/settings.json"

say()  { printf '\033[36m▸\033[0m %s\n' "$1"; }
warn() { printf '\033[33m!\033[0m %s\n' "$1"; }
ok()   { printf '\033[32m✓\033[0m %s\n' "$1"; }

mkdir -p "$CLAUDE_DIR"

# 1. Parser check
if command -v jq >/dev/null 2>&1; then
  ok "jq found"
elif command -v python3 >/dev/null 2>&1 || command -v python >/dev/null 2>&1; then
  ok "python found (jq not required)"
else
  warn "Neither jq nor python found. Install jq for best results:"
  warn "  macOS: brew install jq   •   Linux: apt install jq   •   Windows: choco install jq"
fi

# 2. Fetch the script
say "Downloading statusline.sh → ${SCRIPT_DEST}"
if [ -f "${SCRIPT_DEST}" ]; then
  cp "${SCRIPT_DEST}" "${SCRIPT_DEST}.bak"
  warn "Existing statusline.sh backed up to statusline.sh.bak"
fi
curl -fsSL "${REPO_RAW}/statusline.sh" -o "${SCRIPT_DEST}"
chmod +x "${SCRIPT_DEST}"
ok "Script installed"

# 3. Patch settings.json
say "Updating ${SETTINGS}"
STATUSLINE_JSON='{"type":"command","command":"~/.claude/statusline.sh","refreshInterval":60}'

if [ ! -f "${SETTINGS}" ]; then
  printf '{\n  "statusLine": %s\n}\n' "${STATUSLINE_JSON}" > "${SETTINGS}"
  ok "Created settings.json with statusLine"
else
  cp "${SETTINGS}" "${SETTINGS}.bak"
  warn "settings.json backed up to settings.json.bak"
  if command -v jq >/dev/null 2>&1; then
    jq --argjson sl "${STATUSLINE_JSON}" '.statusLine = $sl' "${SETTINGS}" > "${SETTINGS}.tmp" \
      && mv "${SETTINGS}.tmp" "${SETTINGS}"
    ok "Merged statusLine into settings.json"
  else
    warn "jq not available — add this to ${SETTINGS} manually:"
    printf '  "statusLine": %s\n' "${STATUSLINE_JSON}"
  fi
fi

echo ""
ok "Done. Restart Claude Code (or start a new prompt) to see your statusline."
echo "   Customize anytime: copy skills/statusline-setup into ~/.claude/skills and run /statusline-setup"
