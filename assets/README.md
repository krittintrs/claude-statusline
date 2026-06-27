# Assets

SVG renders of the statusline, generated from real script output (not screenshots,
so they stay crisp and themeable). Regenerate with `ansi2svg.py`:

    now=$(date +%s)
    printf '{"model":{"display_name":"Sonnet 4.6"},"context_window":{"used_percentage":42},"cost":{"total_cost_usd":0.85},"workspace":{"current_dir":"/home/user/vibe","repo":{"name":"vibe"}},"rate_limits":{"five_hour":{"used_percentage":2,"resets_at":'$((now+17400))'},"seven_day":{"used_percentage":35,"resets_at":'$((now+64800))'}},"effort":{"level":"medium"}}' \
      | bash ../statusline.sh | python3 ansi2svg.py > default.svg

- `default.svg` — ~42% context
- `high-context.svg` — 85% context (red end of the gradient)
- `styles.svg` — display-style palette
