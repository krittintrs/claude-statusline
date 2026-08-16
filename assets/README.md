# Assets

PNG renders of the statusline, generated from real script output — screenshotted in
a browser (correct emoji/box-drawing glyphs, unlike hand-picking one monospace font)
and wrapped in a macOS window frame with `mac-frame.py`.

- `default.png` — ~42% context
- `high-context.png` — 85% context (red end of the gradient)
- `styles.png` — display-style palette

## Regenerate

1. Render real script output to a standalone HTML page:
   ```bash
   now=$(date +%s)
   printf '{"model":{"display_name":"Sonnet 5"},"context_window":{"used_percentage":42},"cost":{"total_cost_usd":0.85},"workspace":{"current_dir":"/home/user/vibe","repo":{"name":"vibe"}},"rate_limits":{"five_hour":{"used_percentage":2,"resets_at":'$((now+17400))'},"seven_day":{"used_percentage":35,"resets_at":'$((now+64800))'}},"effort":{"level":"medium"}}' \
     | bash ../statusline.sh | python3 ansi2html.py > /tmp/default.html
   ```
   (`styles.png` isn't live script output — it's a hand-authored legend. Edit an
   HTML file directly with the same `#term` structure; see the color values in
   `ansi2html.py`'s `BASIC` map and the gradient stops in `../statusline.sh`.)
2. Serve the folder (`python3 -m http.server`) and screenshot the `#term` element
   with a headless browser at `scale: device`. Pillow needs `pip install Pillow`.
3. Frame it: `python3 mac-frame.py /tmp/default-raw.png -o default.png`
