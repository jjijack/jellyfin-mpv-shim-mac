# jellyfin-mpv-shim-mac
A method to configure jellyfin-mpv-shim to work as an integrated app on macOS.

## Introduction
Jellyfin MPV Shim is a well-developed client that integrates Jellyfin with MPV, offering enhanced decoding capabilities and support for filters such as Anime4K. While it works smoothly on Windows and Linux, there are compatibility issues that may arise when running the application on macOS. With the right configurations and adjustments, however, these challenges can be overcome, allowing users to enjoy a high-quality media experience on their macOS devices.

In this guide, we'll explore the necessary steps to configure Jellyfin MPV Shim on macOS, address common compatibility issues, and further demonstrate how to integrate it seamlessly as a native-like macOS application.

## Installation
First of all, [the official installation guide for macOS](https://github.com/jellyfin/jellyfin-mpv-shim#osx-installation) is listed below. Personally, I use the CLI version, as it fully meets my needs for subsequent tasks. Once everything is set up, there's no need to interact with the CLI again—even when using the CLI version. The current version of Jellyfin MPV Shim is v2.9.0 when this article is published.

### To install the CLI version:

1. Install brew. ([Instructions](https://brew.sh/))
2. Install python3 and mpv.  
   ```bash
   brew install python mpv
   ```
3. Install pipx.  
   ```bash
   brew install pipx
   ```
4. Set path.  
   ```bash
   pipx ensurepath
   ```
5. Install jellyfin-mpv-shim.  
   ```bash
   pipx install jellyfin-mpv-shim
   ```
6. Run:  
   ```bash
   jellyfin-mpv-shim
   ```

---

### If you'd like to install the GUI version

You need a working copy of tkinter.

1. Install TK and mpv.  
   ```bash
   brew install python-tk mpv
   ```
2. Install python3.  
   ```bash
   brew install python
   ```
3. Install pipx.  
   ```bash
   brew install pipx
   ```
4. Set path.  
   ```bash
   pipx ensurepath
   ```
5. Install jellyfin-mpv-shim and pystray.  
   ```bash
   pipx install 'jellyfin-mpv-shim[gui]'
   ```
6. Run:  
   ```bash
   jellyfin-mpv-shim
   ```
## (Optional) Install Missing Modules

For the first time running the `jellyfin-mpv-shim` command, you will be prompted to enter the server address, username, and password. After running the command, you may encounter errors or warnings related to `ModuleNotFoundError`. Based on my tests, these missing modules don’t seem to affect the functionality of the client. However, simply installing the missing modules will resolve these issues.

```bash
pipx inject jellyfin-mpv-shim Pillow
pipx inject jellyfin-mpv-shim pystray
```

In my case, these two modules were missing. If you encounter other missing modules, you can try installing them in a similar way.

## Modify pack-next.json

Theoretically, you should be able to cast Jellyfin's video to MPV without this step. However, the default profile has compatibility issues, and I strongly recommend modifying it. This part is originally discussed in [this helpful GitHub comment](https://github.com/jellyfin/jellyfin-mpv-shim/issues/356#issuecomment-2313079163).

The `pack-next.json` file is located at `~/.local/pipx/venvs/jellyfin-mpv-shim/lib/python3.13/site-packages/jellyfin_mpv_shim/default_shader_pack/pack-next.json` if installed with pipx, or at `~/miniconda3/lib/python3.13/site-packages/jellyfin_mpv_shim/default_shader_pack/pack-next.json` if installed in a conda environment by default.

There are two issues with this file. First, macOS uses `vulkan`, not `opengl`. Second, `dither=fruit` may cause a crash. To fix this, modify the `gpu_api` under `hwdec-default` from `opengl` to `vulkan`, and remove `"dither-fruit-default"` under `"default-setting-groups"` (don't forget to remove the comma above). Alternatively, you can download the profile in this repo and replace it.

<img width="937" alt="Screenshot 2025-05-30 at 03 24 57" src="https://github.com/user-attachments/assets/dfbb3cd3-a862-4e27-b20b-1f3206a537c5" />
<img width="937" alt="Screenshot 2025-05-30 at 03 25 55" src="https://github.com/user-attachments/assets/ee8f4563-14e6-455d-8d04-97bafc54ecce" />

By making these changes, you should be able to utilize both hardware decoding and filters properly. You can switch filters by pressing Enter, selecting Video Playback Profiles, and choosing the desired filter, like Anime4K.

## Download Startup Script

On other platforms, Jellyfin MPV Shim is designed to run as a background service, listening for potential Jellyfin ports and forwarding them to MPV. However, on macOS, there's a bug: if you quit MPV using `Command+Q` instead of pressing `Q` within the app (which would leave MPV in the dock), Jellyfin MPV Shim encounters "Broken pipe" errors, requiring a restart of the service.

To address this, I created a startup script, `jellyfin-shim-launcher.sh`, to launch Jellyfin MPV Shim alongside the official Jellyfin Media Player app. This script will automatically restart Jellyfin MPV Shim whenever "Broken pipe" errors occur (though you'll still need to manually change the "Play On" device within the app). Additionally, it will terminate all Jellyfin MPV Shim-related processes when Jellyfin Media Player is closed. In this way, Jellyfin MPV Shim is effectively integrated with the Jellyfin Media Player app.

## Create an App

After downloading `jellyfin-shim-launcher.sh` and placing it wherever you prefer (for me, it's `~/.config/jellyfin-mpv-shim/jellyfin-shim-launcher.sh`), you can add the file to your `PATH` in `~/.zshrc` to run it from the terminal. However, for MacBooks, there's a more elegant and streamlined way to achieve this. 

Open Automator via Spotlight, then select `New Document - Application`. Next, search for `Run Shell Script` in the top-left search bar. Enter the path of your script (for me, `~/.config/jellyfin-mpv-shim/jellyfin-shim-launcher.sh`), and then press `Command+S` to save it as an application (I named it "Jellyfin Shim Launcher"). 

<img width="1112" alt="Screenshot 2025-05-30 at 03 27 08" src="https://github.com/user-attachments/assets/8d2b1941-70dc-4873-8b7f-263d8a2e5e68" />

Please note: I’ve tested that pasting the content of the script directly into Automator causes it to fail to terminate Jellyfin MPV Shim-related processes, which leads to issues on the next startup.

Once that's done, you can find a suitable icon, open the info window for your Jellyfin Shim Launcher app (`Command+I`), and drag the icon to replace the default one. Enjoy!

## Misc
<img width="202" alt="Screenshot 2025-05-30 at 03 28 07" src="https://github.com/user-attachments/assets/08e49eec-528d-48c8-b0da-876a69deec14" />

It could look like this in the Launchpad.

<img width="407" alt="Screenshot 2025-05-30 at 03 30 26" src="https://github.com/user-attachments/assets/1cdd142d-1a68-4a4d-af7f-081ac4252251" />

Set Jellyfin MPV Shim as the default, and you won’t need to switch it frequently, as long as you remember to avoid quitting MPV with `Command+Q`.

<img width="1920" alt="Screenshot 2025-05-30 at 03 38 58" src="https://github.com/user-attachments/assets/97b7cafb-d5cf-4d58-9f2b-da9fe70e30e4" />

To check if the filters have been loaded, press \` and enter `show-text "${glsl-shaders}"`. If a long list of words appears in the background (e.g., `/Users/jjijack/.local/pipx/venvs/jellyfin-mpv-shim/lib/python3.13/site-packages/jellyfin_mpv_shim/...`), the filters have been loaded successfully. If the output is empty, the filters are not loaded.
<p align="center">
<img width="161" alt="Screenshot 2025-05-30 at 03 47 28" src="https://github.com/user-attachments/assets/1e7d0a53-feb9-4849-9968-37df24fdf555" />
</p>
Your dock will look like this after launching Jellyfin Shim Launcher. Initially, only the official Jellyfin app and a Python rocket indicating Jellyfin MPV Shim will appear. MPV will show up once a video starts playing. If Jellyfin MPV Shim is terminated, its icon will briefly disappear and then reappear. After quitting Jellyfin Media Player, all three icons should disappear.

