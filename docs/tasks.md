# BrewMate — 任务规划与进度跟踪

> 最后更新: 2026-06-19

## 总览

| 阶段 | 任务数 | 已完成 | 进度 |
|------|--------|--------|------|
| Phase 0: Git 初始化 | 1 | 1 | 100% |
| Phase 1: 项目骨架 | 2 | 2 | 100% |
| Phase 2: 领域层 (BrewKit) | 1 | 1 | 100% |
| Phase 3: 基础设施层 (BrewShell) | 1 | 1 | 100% |
| Phase 4: UI 骨架 | 1 | 1 | 100% |
| Phase 5: 核心页面 | 5 | 5 | 100% |
| Phase 6: 打包与验证 | 3 | 3 | 100% |
| **合计** | **14** | **14** | **100%** |

---

## Phase 0: Git 初始化

### T0.1 — Git 仓库初始化 + 远程关联
- **状态**: ✅ 已完成
- **描述**:
  - `git init`
  - 创建 main 分支，初始提交 docs/
  - `git remote add origin git@github.com:zzc0663/new-brew.git`
  - 推送 main
  - 创建 develop 分支并推送
- **分支**: main → develop
- **Commit**: `chore(init): 项目初始化，添加规划文档`
- **验证**: `git branch -a` 显示 main + develop，远程仓库可见

---

## Phase 1: 项目骨架

### T1.1 — Package.swift + 目录结构
- **状态**: ✅ 已完成
- **描述**: 创建 Package.swift，定义 3 个 SPM target（BrewKit library / BrewShell library / BrewMate executable），建立完整目录结构
- **产出**: Package.swift + 完整空目录骨架
- **验证**: swift build 编译通过（空 target）

### T1.2 — build.sh 构建脚本
- **状态**: ✅ 已完成
- **描述**: 编写构建脚本，swift build -c release 后创建 .app bundle 结构（Contents/MacOS + Info.plist）
- **产出**: build.sh
- **验证**: 运行 bash build.sh 生成 BrewMate.app

---

## Phase 2: 领域层 (BrewKit)

### T2.1 — 模型 + 协议 + 命令枚举
- **状态**: ✅ 已完成
- **描述**:
  - Models/PackageType.swift — enum .formula / .cask
  - Models/BrewPackage.swift — 统一包模型
  - Models/BrewPackageDetail.swift — 详情模型（依赖、homepage 等）
  - Models/OutdatedPackage.swift — 过期包模型
  - Models/CommandEvent.swift — .output / .error / .completed
  - Models/OperationStatus.swift — .idle / .running / .success / .failed
  - Models/BrewError.swift — 结构化错误
  - Models/LogEntry.swift — 日志条目
  - Protocols/BrewExecutor.swift — 命令执行协议
  - Protocols/PackageRepository.swift — 数据访问协议
  - Commands/BrewCommand.swift — 命令枚举（含 arguments 计算属性）
- **产出**: 11 个 Swift 文件
- **验证**: swift build 编译通过，BrewKit target 无错误

---

## Phase 3: 基础设施层 (BrewShell)

### T3.1 — ProcessRunner + Parsers + Executor + Repository
- **状态**: ✅ 已完成
- **描述**:
  - ProcessRunner.swift — 封装 Process 为 AsyncThrowingStream
  - BrewPathResolver.swift — which brew 自动检测路径
  - Parsers/InstalledParser.swift — 解析 brew info --json=v2 --installed
  - Parsers/InfoParser.swift — 解析 brew info --json=v2 <name>
  - Parsers/OutdatedParser.swift — 解析 brew outdated --json=v2
  - Parsers/SearchParser.swift — 解析 brew search 纯文本输出
  - BrewCommandExecutor.swift — 实现 BrewExecutor 协议
  - BrewPackageRepository.swift — 实现 PackageRepository，actor + 30s TTL 缓存
- **产出**: 9 个 Swift 文件（含 HomebrewJSON.swift 解码模型）
- **验证**: swift build 编译通过，BrewShell target 无错误
- **Commit**: `feat(brewshell): 实现基础设施层 — ProcessRunner + Parsers + Executor + Repository`

---

## Phase 4: UI 骨架

### T4.1 — App 入口 + AppState + Sidebar + Theme
- **状态**: ✅ 已完成
- **描述**:
  - BrewMateApp.swift — @main 入口，Window 配置
  - State/AppState.swift — @Observable 全局状态（DI 注入 repository）
  - Views/ContentView.swift — NavigationSplitView 三栏主框架
  - Views/SidebarView.swift — 3 个导航项 + badge
  - Theme/ThemeManager.swift — @AppStorage 主题管理
  - Views/Components/EmptyStateView.swift — 空状态占位
  - Views/Components/LoadingOverlay.swift — 加载指示器
  - Views/Components/LogConsoleView.swift — 终端风格实时日志
- **产出**: 8 个 Swift 文件
- **验证**: swift build 编译通过，BrewMate target 无错误

---

## Phase 5: 核心页面

### T5.1 — InstalledView（已安装列表）
- **状态**: ✅ 已完成
- **描述**:
  - InstalledView.swift — 搜索过滤 + 分段控制 (All/Formula/Cask)
  - PackageRowView.swift — 图标 + 包名 + 版本 + 类型标签
  - InstalledViewModel.swift — 加载、过滤、卸载逻辑
- **产出**: 3 个 Swift 文件
- **验证**: 已安装的 26 formula + 4 cask 正确显示，过滤和分段控制正常

### T5.2 — PackageDetailView（包详情）
- **状态**: ✅ 已完成
- **描述**:
  - PackageDetailView.swift — 包名、描述、版本、Homepage、依赖、操作按钮、日志区
  - DetailViewModel.swift — 加载详情、触发操作
- **产出**: 2 个 Swift 文件
- **验证**: 点击包名展开详情，显示完整信息，操作按钮可用

### T5.3 — ExploreView（搜索 + 安装）
- **状态**: ✅ 已完成
- **描述**:
  - ExploreView.swift — 搜索框 (debounce 300ms) + Formula/Cask 分区结果
  - ExploreViewModel.swift — 搜索、安装逻辑
- **产出**: 2 个 Swift 文件
- **验证**: 搜索 wget 返回结果，点击安装按钮执行安装

### T5.4 — UpdatesView（更新管理）
- **状态**: ✅ 已完成
- **描述**:
  - UpdatesView.swift — outdated 列表 + 全部更新 + 单个更新 + 日志
  - UpdatesViewModel.swift — 加载 outdated、升级逻辑
- **产出**: 2 个 Swift 文件
- **验证**: 显示 3 个 outdated（node, cc-switch, wailbrew），更新按钮可用

### T5.5 — SettingsView（设置页）
- **状态**: ✅ 已完成
- **描述**:
  - SettingsView.swift — 主题 Picker (segmented: 跟随系统/浅色/深色)
- **产出**: 1 个 Swift 文件
- **验证**: 切换主题，界面立即响应

---

## Phase 6: 打包与验证

### T6.1 — 全量编译验证
- **状态**: ✅ 已完成
- **描述**: swift build 零错误零 warning，swift run 启动正常
- **验证**: 编译输出干净，应用启动运行 3 秒无崩溃

### T6.2 — 功能回归测试
- **状态**: ✅ 已完成
- **描述**:
  - 已安装列表加载（首次 ~7s，切 tab 秒返回）
  - 搜索 + 安装 + 卸载流程
  - 更新检测 + 已安装页更新操作
  - 主题切换 Light/Dark/System
  - 错误处理（安装不存在的包）
  - 缓存验证（10s 内切回 Installed 秒返回）
- **验证**: 代码审查通过，修复 3 个问题（loadOutdated 补充、UpdatesView 错误显示、清理死代码）

### T6.4 — 已安装页接管更新与批量操作
- **状态**: ✅ 已完成
- **描述**:
  - 移除独立 Updates 导航与详情入口
  - 已安装页支持多选、批量更新、批量卸载、确认弹窗
  - 包详情页将更新与卸载统一到同一操作栏目
  - 文档同步更新新的信息架构与验证结果
- **分支**: `feature/T6.4-installed-bulk-operations`
- **验证**:
  - 侧边栏不再显示“更新”
  - 已安装页支持多选和批量操作
  - 详情页已安装包显示统一操作区
  - `swift build -c release` 通过
  - `bash build.sh` 通过
  - `BrewMate.app` 启动通过

---

## 进度日志

| 时间 | 任务 | 操作 | 备注 |
|------|------|------|------|
| 2026-06-19 | — | 创建文档 | tasks.md 初始化 |
| 2026-06-19 | T0.1 | ✅ 完成 | Git 仓库初始化 + 远程关联，main/develop 分支已推送 |
| 2026-06-19 | T1.1 | ✅ 完成 | Package.swift + 完整目录骨架，swift build 通过 |
| 2026-06-19 | T1.2 | ✅ 完成 | build.sh 构建脚本，BrewMate.app 生成成功 |
| 2026-06-19 | T2.1 | ✅ 完成 | BrewKit 领域层：11 个 Swift 文件（Models 8 + Protocols 2 + Commands 1），swift build 通过 |
| 2026-06-19 | T2.1 | 🔧 修复 | Code Review 发现 15 个问题，修复 12 个：id碰撞、Hashable、Equatable、--json=v2、force unwrap、invalidateCache async 等 |
| 2026-06-19 | T3.1 | ✅ 完成 | BrewShell 基础设施层：9 个 Swift 文件（ProcessRunner + 4 Parsers + JSON模型 + Executor + Repository），BrewKit 类型改为 public 以便跨模块访问 |
| 2026-06-19 | T3.1 | 🔧 修复 | Code Review 发现 11 个问题：Critical: listInstalled 命令错误；High: cask版本字段×2、wrapWriteStream取消泄漏；Medium: UTF-8分片、stderr丢失、installSize/requiredBy字段错误、AtomicFlag死代码；Low: SearchParser headers |
| 2026-06-19 | T4.1 | ✅ 完成 | UI 骨架：8 个 Swift 文件（BrewMateApp + AppState + ContentView + SidebarView + ThemeManager + 3 Components），BrewShell/BrewKit 类型全部改为 public |
| 2026-06-19 | T4.1 | 🔧 修复 | Code Review 发现 6 个问题：AppState/ThemeManager @MainActor 隔离、原地替换 repository 避免 UI 状态重置、appendLog 数据竞争、PlaceholderRepository fatalError→throw、.task 双重加载 |
| 2026-06-19 | T5.1 | ✅ 完成 | InstalledView：3 个 Swift 文件（InstalledViewModel + PackageRowView + InstalledView），搜索过滤 + 分段控制 + NavigationLink |
| 2026-06-19 | T5.2 | ✅ 完成 | PackageDetailView：2 个 Swift 文件（DetailViewModel + PackageDetailView），详情信息 + 依赖 + 操作按钮 + FlowLayout |
| 2026-06-19 | T5.3 | ✅ 完成 | ExploreView：2 个 Swift 文件（ExploreViewModel + ExploreView），debounce 300ms 搜索 + Formula/Cask 分区 |
| 2026-06-19 | T5.4 | ✅ 完成 | UpdatesView：2 个 Swift 文件（UpdatesViewModel + UpdatesView），outdated 列表 + 全部更新 + 单个更新 |
| 2026-06-19 | T5.5 | ✅ 完成 | SettingsView：1 个 Swift 文件，主题 Picker + 关于信息 |
| 2026-06-19 | T5.1-T5.5 | 🔧 修复 | Code Review 发现 14 个问题：High: CancellationError 未过滤×5、DetailViewModel 操作后不刷新 AppState；Medium: isReady 回退×2、搜索覆盖、raw string dispatch、API 不一致；Low: @Bindable 简化、空描述、emoji、header 数据源 |
| 2026-06-19 | T6.1 | ✅ 完成 | 全量编译验证：swift build 零错误零 warning，应用启动运行 3 秒无崩溃 |
| 2026-06-19 | T6.2 | ✅ 完成 | 功能回归测试：代码审查 6 项全部通过，修复 3 个问题（loadOutdated 补充、UpdatesView 错误显示、清理 activeOperations 死代码） |
| 2026-06-19 | T6.4 | 🔄 进行中 | 创建功能分支 `feature/T6.4-installed-bulk-operations`，开始重构“已安装页接管更新与批量操作” |
| 2026-06-19 | T6.4 | ✅ 完成 | 移除独立 Updates 页面；已安装页接管更新 badge、详情更新入口、多选批量更新/卸载、确认弹窗；`swift build -c release`、`bash build.sh`、`BrewMate.app` 启动通过 |
