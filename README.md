# BrewMate

一个原生 macOS 的 Homebrew 图形化管理工具，使用 Swift + SwiftUI 构建，面向日常包管理场景：查看已安装包、搜索新包、安装/卸载、更新，以及基础环境检查。

## 项目定位

BrewMate 不是 Homebrew 的替代品，而是一个更适合桌面使用的管理界面。当前版本重点覆盖 Homebrew 的核心应用管理流程，并保持架构清晰，方便后续继续扩展：

- 已安装包管理
- 搜索 Formula / Cask
- 单包安装、卸载、更新
- 已安装页批量选择、批量更新、批量卸载
- Homebrew trust 状态检查与处理
- 主题切换

## 当前界面结构

应用当前保留 3 个一级页面：

- `已安装`
  - 搜索、类型筛选
  - 焦点详情面板
  - 单包更新 / 卸载
  - 批量更新 / 批量卸载
- `探索`
  - 搜索 Formula / Cask
  - 查看详情
  - 安装未安装包
- `设置`
  - 主题切换
  - Homebrew trust 提示与“信任”操作

可更新数量会显示在侧边栏 `已安装` 项上。

## 技术结构

项目采用三层 SPM 模块化结构，依赖方向单向：

`BrewMate (UI)` -> `BrewShell (Infrastructure)` -> `BrewKit (Domain)`

### 模块说明

- `Modules/BrewKit`
  - 领域模型
  - 协议定义
  - 命令抽象
- `Modules/BrewShell`
  - `brew` 命令执行
  - JSON / 文本解析
  - Repository 实现
  - 缓存与环境检查
- `Modules/BrewMate`
  - SwiftUI 界面
  - 全局状态
  - 页面 ViewModel
  - 主题与交互逻辑

## 运行环境

- macOS 14+
- Swift 5.9+
- 已安装 Homebrew

默认通过本机 Homebrew 环境运行，应用启动时会自动检测 `brew` 路径。

## 本地开发

### 直接运行

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

可直接启动：

```bash
open BrewMate.app
```
