#!/bin/bash

# Add custom paths to the system PATH variable
export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"

TARGET_ERROR="Broken pipe"
JELLYFIN_PROCESS_NAME="Jellyfin Media Player"

# Function to start jellyfin-mpv-shim and handle errors
start_shim() {
  echo "Starting jellyfin-mpv-shim..."

  # Run jellyfin-mpv-shim and capture output
  jellyfin-mpv-shim 2>&1 | while read -r line; do
    echo "$line"

    # If the target error is detected, restart the shim
    if [[ "$line" == *"$TARGET_ERROR"* ]]; then
      echo "Detected error: $TARGET_ERROR"
      echo "Force killing jellyfin-mpv-shim and restarting..."

      # Attempt a graceful shutdown first with SIGTERM (default signal)
      pkill -f jellyfin-mpv-shim
      sleep 1  # Wait for the process to exit

      # If the process is still running, force kill it with SIGKILL
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

  # Loop through pids to check if any valid Jellyfin processes are running
  for pid in "${pids[@]}"; do
    # Skip the current script process
    if [[ "$pid" == "$$" ]]; then
      continue
    fi

    # Skip child processes of the current script
    if ps -o ppid= -p "$pid" 2>/dev/null | grep -qw "$$"; then
      continue
    fi

    # If a valid Jellyfin process is found, consider it running
    return 0
  done

  # No valid processes found, consider Jellyfin Media Player has exited
  return 1
}

# Open the Jellyfin Media Player application
open "/Applications/Jellyfin Media Player.app"
sleep 0.5

start_shim

# Trap to catch INT and TERM signals and clean up on exit
trap "echo 'Exiting...'; pkill -9 -f jellyfin-mpv-shim; exit" INT TERM

# Monitor the running status of Jellyfin Media Player
while true; do
  sleep 2
  if ! is_jellyfin_running; then
    echo "Jellyfin Media Player has exited. Killing jellyfin-mpv-shim and exiting script..."
    
    # Attempt a graceful shutdown first with SIGTERM
    pkill -f jellyfin-mpv-shim
    sleep 2  # Wait for process to exit

    # If still running, force kill with SIGKILL
    if is_jellyfin_running; then
      echo "Jellyfin Media Player did not exit, using SIGKILL..."
      pkill -9 -f jellyfin-mpv-shim
    fi

    exit 0
  fi
done
