# window-watcher configuration
# Copy this file to config.sh and edit to match your setup.
#
# Find your WM_CLASS values with: xprop | grep WM_CLASS (then click a window)

# Applications whose windows should be moved to the launch workspace.
WATCH_CLASSES=("your-app-class" "another-class")

# The actual browser command (needed when ww-open is set as default URL handler).
BROWSER_CMD="your-browser-command"
