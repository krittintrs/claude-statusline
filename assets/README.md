# Screenshots

Capture these from a real terminal and save here (referenced by the main README):

- `default.png` — the default statusline at ~42% context
- `high-context.png` — gradient at 🔥 85%+ to show the red end
- `styles.png` — the styles palette (text emphasis, color modes, bars, icons)

Tip: render with the preview command, then screenshot your terminal:

    now=$(date +%s)
    printf '{"model":{"display_name":"Sonnet 4.6"},"context_window":{"used_percentage":42},"cost":{"total_cost_usd":0.85},"workspace":{"current_dir":"/home/user/vibe","repo":{"name":"vibe"}},"rate_limits":{"five_hour":{"used_percentage":2,"resets_at":'$((now+17400))'},"seven_day":{"used_percentage":35,"resets_at":'$((now+64800))'}},"effort":{"level":"medium"}}' | bash statusline.sh
