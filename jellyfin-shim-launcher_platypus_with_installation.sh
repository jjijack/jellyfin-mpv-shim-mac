#!/bin/bash

################################################################################
#
# Jellyfin MPV Shim - macOS Installer & Launcher v2.0
#
# - On first run, it installs all dependencies and configures the environment.
# - On subsequent runs, it skips setup and launches the app directly.
#
################################################################################

# --- Configuration ---
CONFIG_DIR="$HOME/.config/jellyfin-mpv-shim"
LOCK_FILE="$CONFIG_DIR/.setup_complete"

# --- Dialog Function ---
# $1: Text to display
function show_dialog() {
  osascript -e "display dialog \"$1\" with title \"Jellyfin Shim Setup & Launcher\" buttons {\"OK\"} default button \"OK\""
}

# --- Check and Install Dependencies ---
function install_dependencies() {
  local brew_path=""
  if [ -x "/opt/homebrew/bin/brew" ]; then
    brew_path="/opt/homebrew/bin"
  elif [ -x "/usr/local/bin/brew" ]; then
    brew_path="/usr/local/bin"
  fi

  if [ -n "$brew_path" ]; then
    export PATH="$brew_path:$PATH"
  fi

  if ! command -v brew &> /dev/null; then
    show_dialog "Homebrew not found. Starting automatic installation..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    if [ -x "/opt/homebrew/bin/brew" ]; then
      export PATH="/opt/homebrew/bin:$PATH"
    fi
  fi

  # Optimized check: 'brew list <pkg>' is a more reliable way to check for installation.
  for pkg in python mpv pipx; do
    if ! brew list ${pkg} &> /dev/null; then
      show_dialog "Installing ${pkg} using Homebrew..."
      brew install ${pkg}
    fi
  done

  export PATH="$HOME/.local/bin:$PATH"
  pipx ensurepath

  if ! pipx list | grep -q "jellyfin-mpv-shim"; then
    show_dialog "Installing jellyfin-mpv-shim..."
    pipx install 'jellyfin-mpv-shim[gui]'
    pipx inject jellyfin-mpv-shim Pillow pystray
  fi
}

# --- Auto-configure pack-next.json ---
function configure_shim() {
    local config_file_path
    config_file_path=$(find "$HOME/.local/pipx/venvs/jellyfin-mpv-shim" -name "pack-next.json" 2>/dev/null | head -n 1)

    if [ -z "$config_file_path" ]; then
        echo "Warning: pack-next.json not found. Skipping auto-configuration."
        return
    fi
    
    if grep -q '"gpu_api", "vulkan"' "$config_file_path" && ! grep -q '"dither-fruit-default"'; then
        echo "Configuration is already up to date."
        return
    fi

    show_dialog "Auto-configuring for macOS compatibility..."
    sed -i '' 's/"gpu_api", "opengl"/"gpu_api", "vulkan"/' "$config_file_path"
    
    local temp_file
    temp_file=$(mktemp)
    grep -v '"dither-fruit-default",' "$config_file_path" > "$temp_file"
    sed -i '' 's/"hwdec-default",/"hwdec-default"/' "$temp_file"
    mv "$temp_file" "$config_file_path"
    echo "Configuration file has been patched."
}


################################################################################
# --- Main Logic ---
################################################################################

# Check if the lock file exists. If not, this is the first run.
if [ ! -f "$LOCK_FILE" ]; then
  show_dialog "Welcome! Starting first-time setup for Jellyfin MPV Shim. This may take a while."
  
  # Create the config directory
  mkdir -p "$CONFIG_DIR"
  
  # Step 1: Install all dependencies
  install_dependencies
  
  # Step 2: Auto-configure the shim
  configure_shim
  
  # Step 3: Create the lock file to mark setup as complete
  touch "$LOCK_FILE"
  show_dialog "Setup complete! The application will now start."
  
else
  echo "Setup already completed. Skipping installation and launching directly."
fi

# --- Launcher Logic (runs every time) ---

export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"

TARGET_ERROR="Broken pipe"
JELLYFIN_PROCESS_NAME="Jellyfin Media Player"

start_shim() {
  echo "Starting jellyfin-mpv-shim..."
  jellyfin-mpv-shim 2>&1 | while read -r line; do
    echo "$line"
    if [[ "$line" == *"$TARGET_ERROR"* ]]; then
      echo "Detected error: $TARGET_ERROR. Restarting shim..."
      pkill -f jellyfin-mpv-shim && sleep 1
      pkill -9 -f jellyfin-mpv-shim && sleep 1
      start_shim
      break
    fi
  done &
}

is_jellyfin_running() {
  pgrep -fl "$JELLYFIN_PROCESS_NAME" | grep -v $$ | grep -v "jellyfin-shim-launcher.sh" > /dev/null
}

open "/Applications/Jellyfin Media Player.app"
sleep 0.5

start_shim

trap "echo 'Exiting...'; pkill -9 -f jellyfin-mpv-shim; exit" INT TERM

while true; do
  sleep 2
  if ! is_jellyfin_running; then
    echo "Jellyfin Media Player has exited. Killing jellyfin-mpv-shim and exiting script..."
    pkill -9 -f jellyfin-mpv-shim
    exit 0
  fi
done