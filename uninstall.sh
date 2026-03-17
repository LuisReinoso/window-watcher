#!/usr/bin/env bash
set -e

echo "Uninstalling window-watcher..."
systemctl --user stop window-watcher.service 2>/dev/null || true
systemctl --user disable window-watcher.service 2>/dev/null || true
rm -f "$HOME/.local/bin/window-watcher.sh"
rm -f "$HOME/.config/systemd/user/window-watcher.service"
rm -rf "${XDG_RUNTIME_DIR:-/tmp}/window-watcher"
systemctl --user daemon-reload
echo "Done — window-watcher removed."
