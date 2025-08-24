#!/bin/bash

################################################################################
#
# Jellyfin MPV Shim - macOS Uninstaller
#
# This script removes jellyfin-mpv-shim and all dependencies
# installed by the launcher script.
#
################################################################################

# --- Dialog Function ---
# $1: Text to display and get confirmation
function get_confirmation() {
  osascript -e "display dialog \"$1\" with title \"Jellyfin Shim Uninstaller\" buttons {\"Cancel\", \"Continue\"} default button \"Continue\""
}

# --- Main Uninstall Logic ---

# Ask for user confirmation before proceeding
get_confirmation "This script will remove jellyfin-mpv-shim and its dependencies (mpv, python, python-tk, pipx) installed via Homebrew. Are you sure you want to continue?"
if [ $? -ne 0 ]; then
    echo "Uninstall cancelled by user."
    exit 0
fi

echo "Starting uninstallation..."

# --- Manually set PATH to find brew ---
# This ensures the script can find Homebrew even in a minimal environment.
local brew_path=""
if [ -x "/opt/homebrew/bin/brew" ]; then # Apple Silicon
  brew_path="/opt/homebrew/bin"
elif [ -x "/usr/local/bin/brew" ]; then # Intel
  brew_path="/usr/local/bin"
fi

if [ -n "$brew_path" ]; then
  export PATH="$brew_path:$PATH"
fi
export PATH="$HOME/.local/bin:$PATH"


# 1. Stop any running processes to prevent files from being in use
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
    echo "Uninstalling Homebrew packages: mpv, python, python-tk, pipx..."
    # Check if packages are installed before trying to uninstall
    for pkg in mpv python python-tk pipx; do
        if brew list ${pkg} &> /dev/null; then
            brew uninstall ${pkg}
        else
            echo "${pkg} is not installed, skipping."
        fi
    done
else
    echo "Homebrew not found, skipping package uninstallation."
fi

# 4. Remove configuration files and the setup lock file
CONFIG_DIR="$HOME/.config/jellyfin-mpv-shim"
if [ -d "$CONFIG_DIR" ]; then
    echo "Removing configuration directory: $CONFIG_DIR"
    rm -rf "$CONFIG_DIR"
fi

# 5. Final user notification
echo ""
echo "------------------------------------------------------------"
echo "Uninstallation Complete!"
echo ""
echo "Please note:"
echo " - This script does NOT uninstall Homebrew itself, as you may be using it for other applications."
echo " - If you wish to completely remove Homebrew, please follow the official instructions at https://brew.sh/"
echo "------------------------------------------------------------"

exit 0