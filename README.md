# BrewMate

一个原生 macOS 的 Homebrew 图形化管理工具，使用 Swift + SwiftUI 构建，面向日常包管理场景：查看已安装包、搜索新包、安装、卸载、更新，以及基础环境检查。

## 项目介绍

BrewMate 不是 Homebrew 的替代品，而是一个更适合桌面使用的管理界面。当前版本重点覆盖 Homebrew 的核心使用流程，并保持结构清晰，方便后续继续扩展。

当前支持：

- 查看已安装的 Formula / Cask
- 搜索新的 Formula / Cask
- 单包安装、卸载、更新
- 已安装页批量更新、批量卸载
- 包详情查看
- Homebrew trust 状态检查与处理
- 跟随系统、浅色、深色主题切换

项目采用三层 SPM 模块化结构：

`BrewMate (UI)` -> `BrewShell (Infrastructure)` -> `BrewKit (Domain)`

运行环境：

- macOS 14+
- Swift 5.9+
- 已安装 Homebrew

## 构建与使用

### 本地开发运行

```bash
swift run BrewMate
```

### Release 构建

```bash
swift build -c release
```

### 打包 `.app`

```bash
bash build.sh
```

产物位于：

- `BrewMate.app`

### 生成应用图标

```bash
node scripts/generate_app_icon.js
```

生成产物位于：

- `Assets/AppIcon-1024.png`
- `Assets/AppIcon.iconset/`
- `Assets/AppIcon.icns`

### 启动应用

```bash
open BrewMate.app
```
