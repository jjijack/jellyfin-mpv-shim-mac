#!/bin/bash

################################################################################
#
# Jellyfin MPV Shim - macOS Uninstaller
#
# This script removes the main application, its dependencies,
# and all related configuration files.
#
################################################################################

# --- Dialog Function ---
function get_confirmation() {
  osascript -e "display dialog \"$1\" with title \"Jellyfin Shim Uninstaller\" buttons {\"Cancel\", \"Continue\"} default button \"Continue\""
}

# --- Main Uninstall Logic ---

APP_PATH="/Applications/Jellyfin Shim Launcher.app"

get_confirmation "This will completely uninstall Jellyfin Shim Launcher, its dependencies (mpv, python, etc.), and all configuration files. Are you sure you want to continue?"
if [ $? -ne 0 ]; then
    echo "Uninstall cancelled by user."
    exit 0
fi

echo "Starting uninstallation..."

# --- Manually set PATH to find brew ---
local brew_path=""
if [ -x "/opt/homebrew/bin/brew" ]; then brew_path="/opt/homebrew/bin"; elif [ -x "/usr/local/bin/brew" ]; then brew_path="/usr/local/bin"; fi
if [ -n "$brew_path" ]; then export PATH="$brew_path:$PATH"; fi
export PATH="$HOME/.local/bin:$PATH"

# 1. Stop any running processes
echo "Stopping all related processes..."
pkill -f "jellyfin-mpv-shim"
pkill -f "Jellyfin Media Player"

# 2. Uninstall pipx package
if command -v pipx &> /dev/null; then
    echo "Uninstalling jellyfin-mpv-shim..."
    pipx uninstall jellyfin-mpv-shim
fi

# 3. Uninstall Homebrew packages
if command -v brew &> /dev/null; then
    echo "Uninstalling Homebrew packages: mpv, python, pipx, python-tk..."
    for pkg in mpv python pipx python-tk; do
        if brew list ${pkg} &> /dev/null; then
            brew uninstall ${pkg}
        else
            echo "${pkg} is not installed, skipping."
        fi
    done
else
    echo "Homebrew not found, skipping package uninstallation."
fi

# 4. Remove configuration directory
CONFIG_DIR="$HOME/Library/Application Support/jellyfin-mpv-shim"
if [ -d "$CONFIG_DIR" ]; then
    echo "Removing configuration directory: $CONFIG_DIR"
    rm -rf "$CONFIG_DIR"
fi

# 5. Remove the main application itself
if [ -d "$APP_PATH" ]; then
    echo "Removing application: $APP_PATH"
    # Use sudo to ensure it can be removed without permission issues
    sudo rm -rf "$APP_PATH"
fi

# 6. Final user notification
echo ""
echo "------------------------------------------------------------"
echo "Uninstallation Complete!"
echo ""
echo "Please note:"
echo " - This script does NOT uninstall Homebrew itself, as you may be using it for other applications."
echo "------------------------------------------------------------"

exit 0