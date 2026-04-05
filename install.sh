#!/usr/bin/env bash
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

ok()   { echo -e "${GREEN}[ok]${NC} $1"; }
info() { echo -e "${YELLOW}[..] $1${NC}"; }
err()  { echo -e "${RED}[!!] $1${NC}"; exit 1; }

echo ""
echo "╔══════════════════════════════════════╗"
echo "║     window-watcher — installer       ║"
echo "╚══════════════════════════════════════╝"
echo ""

# 1. Check dependencies
info "Checking dependencies..."
for cmd in wmctrl xprop; do
    if ! command -v "$cmd" &>/dev/null; then
        err "'$cmd' is not installed. Please install it with your package manager (e.g. apt, dnf, pacman)."
    fi
    ok "$cmd available"
done

# 2. Check X11 session
if [[ "$XDG_SESSION_TYPE" == "wayland" ]]; then
    echo ""
    echo -e "${YELLOW}[warn] Wayland session detected.${NC}"
    echo "  wmctrl works via XWayland on Ubuntu 22.04/24.04."
    echo "  If you see errors, verify that XWayland is active."
    echo ""
fi

# 3. Install the script
info "Installing window-watcher.sh..."
mkdir -p "$HOME/.local/bin"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cp "$SCRIPT_DIR/window-watcher.sh" "$HOME/.local/bin/window-watcher.sh"
chmod +x "$HOME/.local/bin/window-watcher.sh"
ok "window-watcher.sh installed at ~/.local/bin/"

cp "$SCRIPT_DIR/ww-open" "$HOME/.local/bin/ww-open"
chmod +x "$HOME/.local/bin/ww-open"
ok "ww-open installed at ~/.local/bin/"

# 4. Install systemd service
info "Installing systemd service..."
mkdir -p "$HOME/.config/systemd/user"
cp "$SCRIPT_DIR/window-watcher.service" "$HOME/.config/systemd/user/window-watcher.service"
ok "service installed at ~/.config/systemd/user/"

# 5. Enable and start
info "Enabling service..."
systemctl --user daemon-reload
systemctl --user enable window-watcher.service
systemctl --user restart window-watcher.service
sleep 1

if systemctl --user is-active --quiet window-watcher.service; then
    ok "service running"
else
    err "service did not start — check: journalctl --user -u window-watcher -n 20"
fi

echo ""
echo "╔═══════════════════════════════════════════════════════╗"
echo "║  Installation complete                                ║"
echo "╠═══════════════════════════════════════════════════════╣"
echo "║  View logs:   journalctl --user -u window-watcher -f  ║"
echo "║  Stop:        systemctl --user stop window-watcher     ║"
echo "║  Uninstall:   bash uninstall.sh                        ║"
echo "╚═══════════════════════════════════════════════════════╝"
echo ""
echo "  To add more apps edit WATCH_CLASSES in:"
echo "  ~/.local/bin/window-watcher.sh"
echo ""
echo "  To find the WM_CLASS of any window:"
echo "  xprop | grep WM_CLASS   (then click on the window)"
echo ""
