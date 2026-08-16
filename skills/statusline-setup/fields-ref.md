# Available fields

Every field Claude Code sends to the statusline script as JSON on stdin. Authoritative source: https://code.claude.com/docs/en/statusline

Present these grouped as below. ✓ marks what the curated default already uses. Many fields are absent in some sessions — always parse with a fallback (`// empty` in jq).

## Model & session
| Field | Meaning | Default |
|-------|---------|:---:|
| `model.display_name` | Model name, e.g. `Sonnet 5` | ✓ |
| `model.id` | Model identifier, e.g. `claude-sonnet-4-6` | |
| `effort.level` | Reasoning effort: low/medium/high/xhigh/max (absent if unsupported; ultracode reports as xhigh) | ✓ |
| `fast_mode` | Whether Fast Mode is enabled for the session | |
| `thinking.enabled` | Whether extended thinking is on | |
| `output_style.name` | Active output style | |
| `session_name` | Custom name from `--name`/`/rename` (absent if unset) | |
| `session_id` | Unique session id (stable per session — good cache key) | |
| `prompt_id` | UUID of the prompt being processed (absent until first input; v2.1.196+) | |
| `transcript_path` | Path to the conversation transcript `.jsonl` | |
| `version` | Claude Code version | |
| `agent.name` | Agent name when run with `--agent` | |
| `vim.mode` | NORMAL/INSERT/VISUAL when vim mode is on | |

## Directory & git
| Field | Meaning | Default |
|-------|---------|:---:|
| `cwd` | Current working directory — same value as `workspace.current_dir`, which is preferred for consistency with `.project_dir` | |
| `workspace.current_dir` | Current working directory | ✓ |
| `workspace.project_dir` | Directory Claude was launched in | |
| `workspace.repo.name` | Repo name from origin remote | ✓ |
| `workspace.repo.owner`, `.host` | e.g. `anthropics`, `github.com` | |
| `workspace.git_worktree` | Worktree name when inside *any* linked worktree | ✓ |
| `workspace.added_dirs` | Dirs added via `/add-dir` | |
| `worktree.name`, `.path`, `.branch` | Active worktree during `--worktree` sessions (branch absent for hook-based worktrees) | |
| `worktree.original_cwd`, `.original_branch` | Dir/branch before entering the worktree | |
| `pr.number`, `pr.url` | Open PR for the current branch | |
| `pr.review_state` | approved / pending / changes_requested / draft | |

(Git branch itself is not in the JSON — read it with `git branch --show-current`.)

`workspace.git_worktree` (a name) fires for *any* git worktree; the richer `worktree.*` object only fires for `--worktree` sessions.

## Context window
| Field | Meaning | Default |
|-------|---------|:---:|
| `context_window.used_percentage` | % of context used (pre-calculated) | ✓ |
| `context_window.remaining_percentage` | % remaining | |
| `context_window.context_window_size` | Max tokens (200k, or 1M extended) | |
| `context_window.total_input_tokens` | Input tokens in current context | |
| `context_window.total_output_tokens` | Output tokens, latest response | |
| `context_window.current_usage.*` | Per-component token counts (cache reads/writes) | |
| `exceeds_200k_tokens` | Whether total tokens passed 200k | |

## Cost & activity
| Field | Meaning | Default |
|-------|---------|:---:|
| `cost.total_cost_usd` | Estimated session cost (client-side) | ✓ |
| `cost.total_duration_ms` | Wall-clock time since session start | |
| `cost.total_api_duration_ms` | Time spent waiting on the API | |
| `cost.total_lines_added`, `.total_lines_removed` | Lines changed this session | |

## Rate limits (Claude.ai Pro/Max only)
| Field | Meaning | Default |
|-------|---------|:---:|
| `rate_limits.five_hour.used_percentage` | 5-hour window usage 0–100 | ✓ |
| `rate_limits.five_hour.resets_at` | Unix epoch when it resets | ✓ |
| `rate_limits.seven_day.used_percentage` | 7-day window usage | ✓ |
| `rate_limits.seven_day.resets_at` | Unix epoch when it resets | ✓ |

Absent until the first API response, and only for subscribers. Each window can be independently absent.

## Environment (not JSON)
- `COLUMNS` / `LINES` — terminal size, set by Claude Code before the script runs (v2.1.153+). Use to truncate or wrap output on narrow terminals; `tput cols` and language-level width detection don't work here since Claude Code captures the script's output instead of connecting it to the terminal directly.
