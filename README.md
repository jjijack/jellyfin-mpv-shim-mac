# Jellyfin MPV Shim for macOS

[中文说明](README.zh-CN.md)

An all-in-one solution for a native, stable, and user-friendly [jellyfin-mpv-shim](https://github.com/jellyfin/jellyfin-mpv-shim) experience on macOS.

This project solves the common compatibility issues and cumbersome setup process of using jellyfin-mpv-shim on macOS. It provides an automated installer, a robust launcher application, and a clean uninstaller, aiming for an out-of-the-box experience.

## Features

* **One-Click Installer & Setup (`install.sh`)**
    * **Automated Dependency Management**: Automatically checks for and installs all required dependencies (Homebrew, Python, mpv, pipx, python-tk) using an interactive process.
    * **Graphical Admin Privileges**: When needed, it graphically prompts for an administrator password to install Homebrew, without requiring manual `sudo` commands.
    * **Compatibility Patches**: Automatically patches the `pack-next.json` configuration file to switch the rendering backend to `vulkan` and remove problematic `dither` settings, resolving common playback errors on macOS.
    * **Guided First-Time Login**: On the first run, the installer automatically opens a Terminal window to guide the user through the official Jellyfin server login and authorization process.

* **Native-Like Launcher (`Jellyfin Shim Launcher.app`)**
    * **Simple & Intuitive**: Provides a standard macOS App that can be launched from the Applications folder or Launchpad.
    * **Error Auto-Recovery**: Actively monitors the `shim` service and automatically restarts it in the background if a "Broken pipe" error is detected, ensuring playback continuity.
    * **Intelligent Process Management**: The launcher monitors the main Jellyfin Media Player process and automatically terminates all related `shim` processes when the player is closed, preventing orphaned processes.

* **Standard DMG Distribution**
    * Provides a standard `.dmg` disk image for a familiar drag-and-drop installation experience.
    * Includes a dedicated uninstaller script (`uninstall.sh`) for a clean and complete removal of all components and configuration files.

## Installation & Usage

1.  **Download the DMG**: Go to the [Releases page](https://github.com/jjijack/jellyfin-mpv-shim-mac/releases) and download the latest `Jellyfin.Shim.Launcher.Installer.vX.X.X.dmg` file.
2.  **Install the App**: Open the DMG file, and drag the `Jellyfin Shim Launcher.app` icon onto the `Applications` folder alias.
3.  **Run the Installer Script**:
    * Open your **Terminal** application.
    * Type `bash ` (note the space after `bash`).
    * Drag the `install.sh` file from the DMG window into the Terminal window.
    * Press **Enter**. The script will guide you through the rest of the process, including asking for your password and prompting you to log in to Jellyfin.
4.  **Launch the App**: Once the installation is complete, you can run `Jellyfin Shim Launcher` from your Applications folder or Launchpad.

### Important Note for First-Time Launch

Due to macOS Gatekeeper, when you first open the `Jellyfin Shim Launcher.app`, you may see a warning that the developer cannot be verified.

To bypass this, **right-click the app icon and select "Open"** from the context menu. This only needs to be done once.

## Uninstallation

If you wish to remove the application and all its dependencies, simply run the `uninstall.sh` script included in the DMG.

## Usage Notes & Tips

### Verifying Video Filters (Shaders)

Once a video is playing in mpv, you can check if the video filters (like Anime4K) have been loaded correctly.

Press the backtick key (`` ` ``) to open the mpv console. Then, type `show-text "${glsl-shaders}"` and press Enter.

* **Success**: If a long list of file paths appears on-screen (e.g., `/Users/jjijack/.local/pipx/venvs/jellyfin-mpv-shim/...`), the filters have been successfully loaded.
* **Failure**: If the output is empty, the filters were not loaded. Please check your configuration.

### Dock Icon Behavior

Your dock will look like this after launching `Jellyfin Shim Launcher`. Initially, only the official Jellyfin app and a Python rocket indicating Jellyfin MPV Shim will appear. MPV will show up once a video starts playing.

If Jellyfin MPV Shim is terminated (due to an error), its icon will briefly disappear and then reappear as the launcher restarts it. After quitting Jellyfin Media Player, all three icons should disappear.

## Building the App Yourself

For advanced users who prefer to build the application from the source scripts, you can use [Platypus](https://sveinbjorn.org/platypus) to package the launcher.

1.  Download and install Platypus.
2.  Open Platypus and select the `jellyfin-shim-launcher.sh` script as the "Script Path".
3.  This file could be utilized by Platypus to create an integrated app. `Jellyfin Media Player.app` should be selected as a "Bundled File" by dragging it into the files list.
4.  It is recommended to set "Interface" to "None" and check "Run in background" only.
5.  Set your desired app name and icon, then click "Create App".

![Platypus Configuration](assets/platypus_screenshot.png)