# Jellyfin MPV Shim for macOS 中文说明

[English README](README.md)

这是一个旨在提供 `jellyfin-mpv-shim` macOS 原生体验的综合解决方案。

此项目解决了在 macOS 上手动配置 `jellyfin-mpv-shim` 时遇到的常见兼容性问题和流程繁琐的痛点。通过自动化脚本和封装好的启动器，致力于为用户提供一个开箱即用、稳定可靠的播放环境。

## 功能特性

* **一键式安装与配置 (`install.sh`)**
    * **环境自检**: 自动检测并使用 Homebrew 安装所有必需的依赖项 (Python, mpv, pipx, python-tk)。
    * **权限处理**: 在需要时，会自动以图形化方式请求管理员权限以安装 Homebrew，无需用户手动操作。
    * **兼容性修复**: 自动修补 `jellyfin-mpv-shim` 的 `pack-next.json` 文件，将渲染后端切换为 `vulkan` 并移除有问题的 `dither` 配置，以解决在 macOS 上的解码与渲染错误。
    * **引导式首次登录**: 首次运行时，脚本会自动引导用户在终端完成 Jellyfin 服务器的登录与授权。

* **原生体验启动器 (`Jellyfin Shim Launcher.app`)**
    * **一键启动**: 提供标准的 macOS App 图标，点击即可同时启动 Jellyfin Media Player 主程序和后台的 `shim` 服务。
    * **错误自愈**: 实时监控 `shim` 服务的运行状态，当捕获到 "Broken pipe" 等常见错误时，会自动在后台重启服务，保证播放的连续性。
    * **智能进程管理**: 启动器会监控 Jellyfin Media Player 主程序的运行状态，当用户关闭主程序时，会自动终止并清理所有相关的 `shim` 进程，避免产生僵尸进程。

* **标准 DMG 安装包**
    * 提供标准的 `.dmg` 磁盘映像，用户可通过简单的拖拽方式完成安装。
    * 内置独立的卸载脚本 (`uninstall.sh`)，方便用户在需要时彻底、干净地移除所有相关组件和配置文件。

## 安装与使用

1.  **下载 DMG**: 前往 [Releases 页面](https://github.com/jjijack/jellyfin-mpv-shim-mac/releases) 下载最新的 `Jellyfin.Shim.Launcher.Installer.vX.X.X.dmg` 文件。
2.  **安装 App**: 打开 DMG 文件，将 `Jellyfin Shim Launcher.app` 图标拖拽到右侧的“应用程序”文件夹快捷方式上。
3.  **运行安装脚本**:
    * 打开您的“终端 (Terminal)”应用。
    * 输入 `bash ` (注意 `bash` 后面有一个空格)。
    * 将 `install.sh` 文件从 DMG 窗口中拖拽到终端窗口里。
    * 按**回车键**。脚本将引导您完成余下的安装和登录步骤。
4.  **启动 App**: 安装成功后，您就可以从“应用程序”文件夹或“启动台”中运行 `Jellyfin Shim Launcher` 了。

### 首次运行重要提示

根据 macOS 的安全策略，当您首次打开 `Jellyfin Shim Launcher.app` 时，可能会看到“无法验证开发者”的警告。

此时，请**右键点击应用图标，然后选择“打开”**，即可正常运行。此操作只需进行一次。

## 使用技巧

### 验证视频滤镜（着色器）是否加载

在 mpv 开始播放视频后，您可以检查视频滤镜（例如 Anime4K）是否已正确加载。

按下反引号键 (`` ` ``) 来打开 mpv 的控制台，然后输入 `show-text "${glsl-shaders}"` 并按回车。

* **成功**: 如果屏幕上出现了一长串文件路径（例如 `/Users/jjijack/.local/pipx/venvs/jellyfin-mpv-shim/...`），则代表滤镜已成功加载。
* **失败**: 如果输出为空，则代表滤镜未加载，请检查您的相关配置。

### 关于程序坞（Dock）图标的说明

启动 `Jellyfin Shim Launcher` 后，您的程序坞看起来会是这样：

最开始，只会显示 Jellyfin 的官方客户端图标和一个代表 `jellyfin-mpv-shim` 服务的 Python 火箭图标。当视频开始播放后，MPV 的图标会出现。

如果 `jellyfin-mpv-shim` 服务因错误而终止，它的图标会短暂消失，随后因为脚本的自动重启而再次出现。当您退出 Jellyfin Media Player 主程序后，这三个图标应该都会消失。

## 卸载

如果您需要卸载本程序及其所有依赖，请在终端中运行 DMG 包里附带的 `uninstall.sh` 脚本。

## 自行打包 App

对于希望从仓库里的脚本自行打包应用的高级用户，您可以使用 [Platypus](https://sveinbjorn.org/platypus) 来创建。

1.  下载并安装 Platypus。
2.  打开 Platypus，在“Script Path”中选择 `jellyfin-shim-launcher_platypus.sh` 脚本。
3.  您可以使用此文件通过 Platypus 创建一个集成化的 App。请将 `Jellyfin Media Player.app` 拖拽到“Bundled Files”文件列表中。
4.  建议将“Interface”设置为“None”，并仅勾选“Run in background”选项。
5.  设置您喜欢的应用名称和图标，然后点击“Create App”。

![Platypus 配置截图](assets/platypus_screenshot.png)

## 许可证

本项目采用 GNU 通用公共许可证 v3.0 进行授权。

本项目是 [jellyfin-mpv-shim](https://github.com/jellyfin/jellyfin-mpv-shim) 的衍生作品，旨在与其协同工作。原项目同样基于 GPLv3 授权。