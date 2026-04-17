# window-watcher

Reactive X11 window watcher that moves new windows to the workspace where they were launched from. Zero CPU usage when idle — listens to `xprop` events instead of polling.

<p align="center">
  <img src="demo.gif" alt="Window Watcher Demo" width="460">
</p>

## How it works

A background tracker monitors window focus changes and records which workspace you are on. When a new window appears from a watched application, `window-watcher` moves it to the workspace you were on before the new window appeared. It also handles existing windows that get activated from another workspace (e.g., when opening a file activates an application that lives on a different workspace).

This handles applications that reuse a single process or are spawned by other processes — regardless of how the window was created, it lands on the right workspace.

A companion tool `ww-open` is included as a workspace-aware replacement for `xdg-open`. It opens files or URLs on your current workspace — if no matching window exists there, it launches a new one instead of routing to a window on another workspace.

The `DISPLAY` variable is auto-detected at runtime, so the service works regardless of which display number your X11 session uses (`:0`, `:1`, etc.).

## Requirements

- X11 session (works with XWayland)
- `wmctrl`
- `xprop` (from `x11-utils`)
- `systemd` (user service)

## Installation

Install dependencies with your package manager:

```bash
# Debian/Ubuntu
sudo apt-get install wmctrl x11-utils

# Fedora
sudo dnf install wmctrl xprop

# Arch
sudo pacman -S wmctrl xorg-xprop
```

Then run the installer:

```bash
bash install.sh
```

This will:
1. Copy `window-watcher.sh` and `ww-open` to `~/.local/bin/`
2. Enable and start a systemd user service

## ww-open

Workspace-aware replacement for `xdg-open`. Use it to open files or URLs on your current workspace:

```bash
ww-open dashboard.html
ww-open https://example.com
```

If a matching window already exists on your current workspace, it reuses it. If not, it launches a new one.

## Uninstallation

```bash
bash uninstall.sh
```

## Configuration

Copy the example config and edit it:

```bash
cp config.example.sh config.sh
```

Edit `config.sh` to declare which windows should be managed. Add `WM_CLASS` substrings to the array:

```bash
WATCH_CLASSES=("your-app-class" "another-class")
```

The `config.sh` file is git-ignored so your local setup stays private. Re-run `bash install.sh` after editing.

You can also override the config path with the `WINDOW_WATCHER_CONFIG` environment variable.

To find the `WM_CLASS` of any window:

```bash
xprop | grep WM_CLASS
# then click on the window
```

## Debugging

Enable verbose logging:

```bash
systemctl --user set-environment DEBUG=1
systemctl --user restart window-watcher
journalctl --user -u window-watcher -f
```

## Useful commands

```bash
# View logs
journalctl --user -u window-watcher -f

# Stop the service
systemctl --user stop window-watcher

# Restart the service
systemctl --user restart window-watcher

# Check status
systemctl --user status window-watcher
```

## Testing

The project uses a Bash testing framework vendored as a git submodule.

After cloning:

```bash
git submodule update --init --recursive
```

Run all tests:

```bash
./test/run.sh
```

Run only unit or integration tests:

```bash
./test/bats-core/bin/bats test/unit/
./test/bats-core/bin/bats test/integration/
```

Tests cover:
- **Unit**: pure helper functions (`normalize_wid`, `is_watched`, `is_valid_ws`, `get_window_class`)
- **Integration**: `ww-open` branches with mocked external commands

## License

[MIT](LICENSE)
