#!/usr/bin/env bash
set -e

echo "Uninstalling window-watcher..."
systemctl --user stop window-watcher.service 2>/dev/null || true
systemctl --user disable window-watcher.service 2>/dev/null || true

# Restore default URL handler if ww-open is current default
current_default=$(xdg-settings get default-web-browser 2>/dev/null)
if [[ "$current_default" == "ww-open.desktop" ]]; then
    # Try to find the real browser from config
    if [[ -f "$HOME/.local/bin/config.sh" ]]; then
        source "$HOME/.local/bin/config.sh"
    fi
    if [[ -n "$BROWSER_CMD" ]]; then
        desktop_file=$(grep -rl "Exec=.*$BROWSER_CMD" /usr/share/applications/ 2>/dev/null | head -1)
        if [[ -n "$desktop_file" ]]; then
            xdg-settings set default-web-browser "$(basename "$desktop_file")" 2>/dev/null
            echo "Restored default URL handler to $(basename "$desktop_file")"
        fi
    fi
fi

rm -f "$HOME/.local/bin/window-watcher.sh"
rm -f "$HOME/.local/bin/ww-open"
rm -f "$HOME/.local/bin/config.sh"
rm -f "$HOME/.local/share/applications/ww-open.desktop"
rm -f "$HOME/.config/systemd/user/window-watcher.service"
rm -rf "${XDG_RUNTIME_DIR:-/tmp}/window-watcher"
systemctl --user daemon-reload
echo "Done — window-watcher removed."
