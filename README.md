<img src="https://raw.githubusercontent.com/jellyfin/jellyfin-ux/master/branding/SVG/banner-dark.svg?sanitize=true" alt="Jellyfin" width="400"/>

# Jellyfin for HarmonyOS

**中文** | [English](#english)

---

## 中文

### 简介

Jellyfin for HarmonyOS 是 [Jellyfin](https://jellyfin.org) 媒体服务器的鸿蒙原生客户端，基于 [jellyfin-android](https://github.com/jellyfin/jellyfin-android) 移植开发。应用采用 WebView 优先的混合架构：主界面加载 Jellyfin Web App，原生层通过 JavaScript 桥接提供播放器、下载、全屏、设置等系统能力。

### 功能特性

- **WebView 主界面**：完整呈现 Jellyfin Web 界面，享受与桌面端一致的浏览体验
- **原生视频播放**：基于 AVPlayer 的原生播放器，支持直链播放与 HLS 转码流
- **全屏与旋转**：视频全屏时自动切换横屏，退出全屏恢复竖屏
- **播放进度上报**：实时向服务器上报播放进度，支持跨设备续播
- **下载管理**：原生下载列表，查看已缓存内容
- **多服务器支持**：可切换不同 Jellyfin 服务器
- **深色主题**：统一深色 UI，与 Jellyfin 品牌风格一致

### 系统要求

| 项目 | 要求 |
|---|---|
| 操作系统 | HarmonyOS NEXT 5.0 / HarmonyOS 6 |
| SDK 版本 | API 20（6.0.0）~ API 22（6.0.2）|
| 设备类型 | 手机、平板、折叠屏（2in1）|

### 构建方式

需要安装 [DevEco Studio](https://developer.huawei.com/consumer/cn/deveco-studio/)。

```bash
# 构建 Debug HAP
hvigorw assembleHap --mode debug

# 构建 Release HAP
hvigorw assembleHap --mode release
```

或在 DevEco Studio 中直接点击 **Build > Build Hap(s)/APP(s)**。

### 架构概览

```
UIAbility (EntryAbility)
└── Navigation (AppRoot)
    ├── ConnectPage          # 服务器连接
    ├── WebViewPage          # Jellyfin Web 主界面
    │   └── BridgeManager    # JS ↔ ArkTS 桥接（4 个代理对象）
    ├── PlayerPage           # 原生 AVPlayer 播放器
    ├── SettingsPage         # 设置
    └── DownloadsPage        # 下载管理
```

### 许可证

本项目遵循 **GNU 通用公共许可证 第 2 版（GPL-2.0）** 发布，与上游 [jellyfin-android](https://github.com/jellyfin/jellyfin-android) 项目保持一致。

```
Jellyfin for HarmonyOS
Copyright (C) 2020–2026 Jellyfin Contributors
Copyright (C) 2026 WangRuijie

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License along
with this program; if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
```

完整许可证文本见 [LICENSE](LICENSE) 文件，或访问 <https://www.gnu.org/licenses/old-licenses/gpl-2.0.html>。

### 致谢与声明

本项目是基于 **[jellyfin/jellyfin-android](https://github.com/jellyfin/jellyfin-android)** 的 HarmonyOS 移植版本，使用 ArkTS 语言重写，并针对鸿蒙系统能力进行了适配。

在此向以下项目和社区致以诚挚感谢：

- **[Jellyfin 项目](https://jellyfin.org)** 及全体贡献者——感谢你们构建并维护了这个完全免费、开源的媒体服务器
- **[jellyfin-android](https://github.com/jellyfin/jellyfin-android)** 的全体贡献者——本项目的架构设计、功能逻辑与 JS 桥接方案均参考自该项目
- **[Jellyfin Web](https://github.com/jellyfin/jellyfin-web)** 团队——应用主界面的内容由 Jellyfin Web 提供
- **华为 HarmonyOS 开发者社区**——感谢提供 ArkTS、ArkUI、AVPlayer 等平台能力文档与支持
- **[Kimi k2.5](https://kimi.ai)（Moonshot AI）**——本项目的架构设计、代码编写与重构由 Kimi k2.5 深度参与，作为 AI 协作开发者（Co-Author）共同完成

> **版权声明**：Jellyfin 名称、徽标及相关商标归 [Jellyfin Contributors](https://jellyfin.org) 所有。本项目为非官方移植版本，与 Jellyfin 官方团队无从属关系，亦未获得官方背书。

---

## English

<a name="english"></a>

### Introduction

Jellyfin for HarmonyOS is a native HarmonyOS client for the [Jellyfin](https://jellyfin.org) media server, ported from [jellyfin-android](https://github.com/jellyfin/jellyfin-android) and rewritten in ArkTS. The app uses a WebView-first hybrid architecture: the main UI is the Jellyfin Web App loaded in a WebView, while the native layer bridges system capabilities — player, downloads, fullscreen, and settings — via JavaScript proxies.

### Features

- **Full WebView UI**: Renders the complete Jellyfin Web interface for a desktop-parity browsing experience
- **Native Video Playback**: AVPlayer-based native player with direct-play and HLS transcoding support
- **Fullscreen & Rotation**: Automatically switches to landscape on fullscreen, restores portrait on exit
- **Playback Reporting**: Reports playback progress to the server in real time, enabling cross-device resume
- **Download Manager**: Native download list to browse cached content
- **Multi-Server Support**: Switch between different Jellyfin server instances
- **Dark Theme**: Consistent dark UI aligned with the Jellyfin brand palette

### Requirements

| Item | Requirement |
|---|---|
| OS | HarmonyOS NEXT 5.0 / HarmonyOS 6 |
| SDK | API 20 (6.0.0) – API 22 (6.0.2) |
| Devices | Phone, Tablet, Foldable (2-in-1) |

### Building

[DevEco Studio](https://developer.huawei.com/consumer/en/deveco-studio/) is required.

```bash
# Debug HAP
hvigorw assembleHap --mode debug

# Release HAP
hvigorw assembleHap --mode release
```

Alternatively, use **Build > Build Hap(s)/APP(s)** inside DevEco Studio.

### Architecture Overview

```
UIAbility (EntryAbility)
└── Navigation (AppRoot)
    ├── ConnectPage          # Server connection setup
    ├── WebViewPage          # Jellyfin Web main UI
    │   └── BridgeManager    # JS ↔ ArkTS bridge (4 proxy objects)
    ├── PlayerPage           # Native AVPlayer
    ├── SettingsPage         # App settings
    └── DownloadsPage        # Download management
```

### License

This project is released under the **GNU General Public License, version 2 (GPL-2.0)**, consistent with the upstream [jellyfin-android](https://github.com/jellyfin/jellyfin-android) project.

```
Jellyfin for HarmonyOS
Copyright (C) 2020–2026 Jellyfin Contributors
Copyright (C) 2026 WangRuijie

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License along
with this program; if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
```

The full license text is available in the [LICENSE](LICENSE) file or at <https://www.gnu.org/licenses/old-licenses/gpl-2.0.html>.

### Acknowledgements & Legal Notice

This project is a HarmonyOS port of **[jellyfin/jellyfin-android](https://github.com/jellyfin/jellyfin-android)**, rewritten in ArkTS and adapted for HarmonyOS platform APIs.

Sincere thanks to the following projects and communities:

- **[The Jellyfin Project](https://jellyfin.org)** and all contributors — for building and maintaining a fully free, open-source media server
- **[jellyfin-android](https://github.com/jellyfin/jellyfin-android)** contributors — the architecture, feature logic, and JS bridge design of this project are derived from their work
- **[Jellyfin Web](https://github.com/jellyfin/jellyfin-web)** team — the application's main interface is powered by Jellyfin Web
- **The HarmonyOS Developer Community** — for ArkTS, ArkUI, AVPlayer documentation and support
- **[Kimi k2.5](https://kimi.ai) (Moonshot AI)** — the architecture design, code authoring, and refactoring of this project were deeply assisted by Kimi k2.5 as an AI co-author

> **Trademark Notice**: The Jellyfin name, logo, and associated trademarks are the property of [Jellyfin Contributors](https://jellyfin.org). This is an **unofficial** port and is neither affiliated with nor endorsed by the official Jellyfin team.

---

*This README is provided in both Chinese (Simplified) and English. In case of any discrepancy, the English version shall prevail for legal interpretation purposes.*
