#!/bin/bash

# Get the directory where the script is located
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

# Path to the bundled Jellyfin Media Player app
JELLYFIN_APP_PATH="$SCRIPT_DIR/Jellyfin Media Player.app"

# Add custom paths to the system PATH variable
export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"

TARGET_ERROR="Broken pipe"
JELLYFIN_PROCESS_NAME="Jellyfin Media Player"

# Function to start jellyfin-mpv-shim and handle errors
start_shim() {
  echo "Starting jellyfin-mpv-shim..."

  # Run jellyfin-mpv-shim and capture output
  jellyfin-mpv-shim --no-gui 2>&1 | while read -r line; do
    echo "$line"

    # If the target error is detected, restart the shim
    if [[ "$line" == *"$TARGET_ERROR"* ]]; then
      echo "Detected error: $TARGET_ERROR"
      echo "Force killing jellyfin-mpv-shim and restarting..."

      pkill -f jellyfin-mpv-shim
      sleep 1
      pkill -9 -f jellyfin-mpv-shim
      sleep 1
      start_shim
      break
    fi
  done &
}

# Function to check if Jellyfin Media Player is running
is_jellyfin_running() {
  pids=()
  while read -r pid _; do
    pids+=("$pid")
  done < <(pgrep -fl "$JELLYFIN_PROCESS_NAME" 2>/dev/null)

  for pid in "${pids[@]}"; do
    if [[ "$pid" == "$$" ]]; then
      continue
    fi
    if ps -o ppid= -p "$pid" 2>/dev/null | grep -qw "$$"; then
      continue
    fi
    return 0
  done
  return 1
}

# Open the Jellyfin Media Player application
if [ -d "$JELLYFIN_APP_PATH" ]; then
  open "$JELLYFIN_APP_PATH"
else
  # Fallback to the default location if not found
  open "/Applications/Jellyfin Media Player.app"
fi

sleep 0.5

start_shim

# Trap to catch INT and TERM signals and clean up on exit
trap "echo 'Exiting...'; pkill -9 -f jellyfin-mpv-shim; exit" INT TERM

# Monitor the running status of Jellyfin Media Player
while true; do
  sleep 2
  if ! is_jellyfin_running; then
    echo "Jellyfin Media Player has exited. Killing jellyfin-mpv-shim and exiting script..."
    
    pkill -f jellyfin-mpv-shim
    sleep 2

    if is_jellyfin_running; then
      echo "Jellyfin Media Player did not exit, using SIGKILL..."
      pkill -9 -f jellyfin-mpv-shim
    fi

    exit 0
  fi
done