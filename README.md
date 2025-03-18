# Death Stranding Save Sync Tool

[English](#english) | [中文](#中文)

## English

A save synchronization/migration tool for Death Stranding Director's Cut between Steam (Windows) and App Store (macOS) versions. Currently in beta, issues and pull requests are welcome!

### Quick Start Guide

1. **Get the Tool**

   ```bash
   git clone https://github.com/yourusername/DSSAVESYNC.git
   cd DSSAVESYNC
   ```

2. **Preparation**

   - **Close Steam Cloud Sync** to prevent save conflicts
   - Close the game if it's running
   - (Optional but recommended) Back up your saves manually

3. **Run the Script**

   - Windows: Run `Windows/Script/sync_ds_save.ps1` in PowerShell
   - macOS: Run `macOS/Script/sync_ds_save.sh` in Terminal

4. **First Time Setup**
   - Choose your language (English/Chinese)
   - The tool will automatically locate your game saves
   - For Windows: Select your Steam ID if multiple save folders are found

### Sync Between Devices

We recommend using [Syncthing](https://syncthing.net/) to sync this project's folder between your Windows and macOS devices. This ensures both systems have access to the latest save files for migration.

Note: Syncthing is used to sync this tool's folder between devices, not as a replacement for Steam Cloud saves.

### Features

- Cross-platform save synchronization between Windows (Steam) and macOS (App Store) versions
- Support for manual saves, auto-saves, and quick saves
- Automatic backup of existing saves before import
- Bilingual interface (English/Chinese)
- Save timestamp comparison and conflict detection

### Save Location Settings

The tool will automatically detect your save location on first run:

#### Windows (Steam Version)

Default save location:

```
C:\Users\[Username]\AppData\Local\KojimaProductions\DeathStrandingDC\[SteamID]
```

The tool will search for save folders under the DeathStrandingDC directory and display available user IDs for selection.

#### macOS (App Store Version)

Default save location:

```
~/Library/Mobile Documents/iCloud~com~505games~deathstranding
```

### Notes

- While the tool creates backups automatically, it's recommended to backup saves manually before first use
- Close the game before synchronizing saves
- Check the sync log file in the tool's directory if you encounter issues
- This is a beta version, please report any bugs by creating an issue

### Contributing

Found a bug or want to improve the tool? Your contributions are welcome!

- Open an issue to report bugs or suggest features
- Submit pull requests to help improve the code
- Help with testing on different systems and configurations

---

## 中文

这是一个用于在 Steam (Windows) 版本与 App Store (macOS) 版本之间同步/迁移存档的工具。目前处于测试阶段，欢迎提交问题和改进建议！

### 快速开始

1. **获取工具**

   ```bash
   git clone https://github.com/yourusername/DSSAVESYNC.git
   cd DSSAVESYNC
   ```

2. **准备工作**

   - **关闭 Steam 云同步**以防止存档冲突
   - 关闭正在运行的游戏
   - （建议但非必需）手动备份存档

3. **运行脚本**

   - Windows：在 PowerShell 中运行 `Windows/Script/sync_ds_save.ps1`
   - macOS：在终端中运行 `macOS/Script/sync_ds_save.sh`

4. **首次设置**
   - 选择语言（中文/英文）
   - 工具会自动定位游戏存档
   - Windows 用户：若发现多个存档文件夹，需选择对应的 Steam ID

### 设备间同步

推荐使用 [Syncthing](https://syncthing.net/) 在 Windows 和 macOS 设备间同步本项目文件夹，确保两个系统都能访问最新的存档文件用于迁移。

注意：Syncthing 用于同步本工具的文件夹，而不是替代 Steam 云同步。

### 功能特性

- Steam (Windows) 版本与 App Store (macOS) 版本之间的存档同步
- 支持手动存档、自动存档和快速存档
- 导入前自动备份现有存档
- 双语界面（中文/英文）
- 存档时间戳比较和冲突检测

### 存档位置设置

首次运行时，工具会自动检测您的存档位置：

#### Windows (Steam 版本)

默认存档位置：

```
C:\Users\[用户名]\AppData\Local\KojimaProductions\DeathStrandingDC\[SteamID]
```

工具会在 DeathStrandingDC 目录下搜索存档文件夹，并显示可用的用户 ID 供选择。

#### macOS (App Store 版本)

默认存档位置：

```
~/Library/Mobile Documents/iCloud~com~505games~deathstranding
```

### 注意事项

- 虽然工具会备份存档，但还是推荐使用工具前备份存档
- 同步存档前请关闭游戏
- 如遇问题，请查看工具目录下的同步日志文件
- 这是测试版本，如遇到问题请提交 issue

### 参与贡献

发现问题或想改进工具？欢迎您的贡献！

- 创建 issue 报告问题或提出建议
- 提交 pull request 帮助改进代码
- 帮助在不同系统和配置下测试
