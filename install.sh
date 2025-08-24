#!/bin/bash

################################################################################
#
# Jellyfin MPV Shim - macOS Installer & First-Time Setup
#
# This script installs all necessary dependencies, configures the environment,
# and guides the user through the initial login process.
# Run this script once before using the main application.
#
################################################################################

# --- Configuration ---
CONFIG_DIR="$HOME/Library/Application Support/jellyfin-mpv-shim"
CRED_FILE="$CONFIG_DIR/cred.json"
LOCK_FILE="$CONFIG_DIR/.setup_complete" # Used to mark installation as done

# --- Dialog & Admin Functions ---
function show_dialog() {
  osascript -e "display dialog \"$1\" with title \"Jellyfin Shim Installer\" buttons {\"OK\"} default button \"OK\""
}

echo "--- Jellyfin MPV Shim Setup ---"
echo "This script will install necessary software using Homebrew."
echo "You may be prompted for your administrator password."
echo ""

# --- Step 1: Create Configuration Directory ---
if [ ! -d "$CONFIG_DIR" ]; then
    echo "Creating configuration directory..."
    sudo mkdir -p "$CONFIG_DIR"
    sudo chown "$(whoami)" "$CONFIG_DIR"
    echo "Configuration directory created at: $CONFIG_DIR"
fi

# --- Step 2: Install Dependencies ---
local brew_path=""
if [ -x "/opt/homebrew/bin/brew" ]; then brew_path="/opt/homebrew/bin"; elif [ -x "/usr/local/bin/brew" ]; then brew_path="/usr/local/bin"; fi
if [ -n "$brew_path" ]; then export PATH="$brew_path:$PATH"; fi

if ! command -v brew &> /dev/null; then
  echo "Homebrew not found. Starting installation..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [ -x "/opt/homebrew/bin/brew" ]; then export PATH="/opt/homebrew/bin:$PATH"; fi
fi

echo "Checking and installing packages (python, mpv, pipx, python-tk)..."
for pkg in python mpv pipx python-tk; do
  if ! brew list ${pkg} &> /dev/null; then
    echo "Installing ${pkg}..."
    brew install ${pkg}
  else
    echo "${pkg} is already installed."
  fi
done

export PATH="$HOME/.local/bin:$PATH"
pipx ensurepath

if ! pipx list | grep -q "jellyfin-mpv-shim"; then
  echo "Installing jellyfin-mpv-shim..."
  pipx install 'jellyfin-mpv-shim[gui]'
  pipx inject jellyfin-mpv-shim Pillow pystray
else
  echo "jellyfin-mpv-shim is already installed."
fi

# --- Step 3: Auto-configure pack-next.json ---
local config_file_path=$(find "$HOME/.local/pipx/venvs/jellyfin-mpv-shim" -name "pack-next.json" 2>/dev/null | head -n 1)
if [ -n "$config_file_path" ]; then
    if ! grep -q '"gpu_api", "vulkan"' "$config_file_path" || grep -q '"dither-fruit-default"'; then
        echo "Patching pack-next.json for macOS compatibility..."
        sed -i '' 's/"gpu_api", "opengl"/"gpu_api", "vulkan"/' "$config_file_path"
        local temp_file=$(mktemp)
        grep -v '"dither-fruit-default",' "$config_file_path" > "$temp_file"
        sed -i '' 's/"hwdec-default",/"hwdec-default"/' "$temp_file"
        mv "$temp_file" "$config_file_path"
    fi
fi

# --- Step 4: Configure Custom MPV Hotkeys ---
echo "Configuring custom hotkeys for Anime4K..."
# Find the real shaders directory
SHADERS_SOURCE_PATH=$(find "$HOME/.local/pipx/venvs/jellyfin-mpv-shim" -type d -name "shaders" 2>/dev/null | head -n 1)
SHADERS_LINK_PATH="$CONFIG_DIR/shaders"

# Create symbolic link if the source exists and the link doesn't
if [ -d "$SHADERS_SOURCE_PATH" ] && [ ! -e "$SHADERS_LINK_PATH" ]; then
    echo "Creating symbolic link for shaders directory..."
    ln -s "$SHADERS_SOURCE_PATH" "$SHADERS_LINK_PATH"
fi

# Create the input.conf file
INPUT_CONF_PATH="$CONFIG_DIR/input.conf"
echo "Writing hotkey configuration to $INPUT_CONF_PATH..."
cat > "$INPUT_CONF_PATH" << EOL
# Optimized shaders for lower-end GPU:
CTRL+1 no-osd change-list glsl-shaders set "~~/shaders/Anime4K_Clamp_Highlights.glsl:~~/shaders/Anime4K_Restore_CNN_M.glsl:~~/shaders/Anime4K_Upscale_CNN_x2_M.glsl:~~/shaders/Anime4K_AutoDownscalePre_x2.glsl:~~/shaders/Anime4K_AutoDownscalePre_x4.glsl:~~/shaders/Anime4K_Upscale_CNN_x2_S.glsl"; show-text "Anime4K: Mode A (Fast)"
CTRL+2 no-osd change-list glsl-shaders set "~~/shaders/Anime4K_Clamp_Highlights.glsl:~~/shaders/Anime4K_Restore_CNN_Soft_M.glsl:~~/shaders/Anime4K_Upscale_CNN_x2_M.glsl:~~/shaders/Anime4K_AutoDownscalePre_x2.glsl:~~/shaders/Anime4K_AutoDownscalePre_x4.glsl:~~/shaders/Anime4K_Upscale_CNN_x2_S.glsl"; show-text "Anime4K: Mode B (Fast)"
CTRL+3 no-osd change-list glsl-shaders set "~~/shaders/Anime4K_Clamp_Highlights.glsl:~~/shaders/Anime4K_Upscale_Denoise_CNN_x2_M.glsl:~~/shaders/Anime4K_AutoDownscalePre_x2.glsl:~~/shaders/Anime4K_AutoDownscalePre_x4.glsl:~~/shaders/Anime4K_Upscale_CNN_x2_S.glsl"; show-text "Anime4K: Mode C (Fast)"
CTRL+4 no-osd change-list glsl-shaders set "~~/shaders/Anime4K_Clamp_Highlights.glsl:~~/shaders/Anime4K_Restore_CNN_M.glsl:~~/shaders/Anime4K_Upscale_CNN_x2_M.glsl:~~/shaders/Anime4K_Restore_CNN_S.glsl:~~/shaders/Anime4K_AutoDownscalePre_x2.glsl:~~/shaders/Anime4K_AutoDownscalePre_x4.glsl:~~/shaders/Anime4K_Upscale_CNN_x2_S.glsl"; show-text "Anime4K: Mode A+A (Fast)"
CTRL+5 no-osd change-list glsl-shaders set "~~/shaders/Anime4K_Clamp_Highlights.glsl:~~/shaders/Anime4K_Restore_CNN_Soft_M.glsl:~~/shaders/Anime4K_Upscale_CNN_x2_M.glsl:~~/shaders/Anime4K_AutoDownscalePre_x2.glsl:~~/shaders/Anime4K_AutoDownscalePre_x4.glsl:~~/shaders/Anime4K_Restore_CNN_Soft_S.glsl:~~/shaders/Anime4K_Upscale_CNN_x2_S.glsl"; show-text "Anime4K: Mode B+B (Fast)"
CTRL+6 no-osd change-list glsl-shaders set "~~/shaders/Anime4K_Clamp_Highlights.glsl:~~/shaders/Anime4K_Upscale_Denoise_CNN_x2_M.glsl:~~/shaders/Anime4K_AutoDownscalePre_x2.glsl:~~/shaders/Anime4K_AutoDownscalePre_x4.glsl:~~/shaders/Anime4K_Restore_CNN_S.glsl:~~/shaders/Anime4K_Upscale_CNN_x2_S.glsl"; show-text "Anime4K: Mode C+A (Fast)"

CTRL+0 no-osd change-list glsl-shaders clr ""; show-text "GLSL shaders cleared"
EOL

# --- Step 5: First-Time Login ---
if [ ! -f "$CRED_FILE" ] || ! grep -q '"AccessToken"' "$CRED_FILE"; then
    echo ""
    echo "--- First-Time Login ---"
    echo "Please enter your Jellyfin server details below."
    jellyfin-mpv-shim
else
    echo "Login credentials already exist. Skipping login."
fi

# --- Final Step: Mark setup as complete ---
touch "$LOCK_FILE"
echo ""
echo "----------------------------------------"
show_dialog "Installation and setup complete! You can now use the 'Jellyfin Shim Launcher' app."
echo "Installation and setup complete! You can now close this terminal window."
echo "----------------------------------------"