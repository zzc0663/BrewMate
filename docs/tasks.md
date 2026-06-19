# BrewMate — 任务规划与进度跟踪

> 最后更新: 2026-06-19

## 总览

| 阶段 | 任务数 | 已完成 | 进度 |
|------|--------|--------|------|
| Phase 0: Git 初始化 | 1 | 1 | 100% |
| Phase 1: 项目骨架 | 2 | 2 | 100% |
| Phase 2: 领域层 (BrewKit) | 1 | 0 | 0% |
| Phase 3: 基础设施层 (BrewShell) | 1 | 0 | 0% |
| Phase 4: UI 骨架 | 1 | 0 | 0% |
| Phase 5: 核心页面 | 5 | 0 | 0% |
| Phase 6: 打包与验证 | 2 | 0 | 0% |
| **合计** | **13** | **3** | **23%** |

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
- **状态**: ⬜ 待开始
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
- **状态**: ⬜ 待开始
- **描述**:
  - ProcessRunner.swift — 封装 Process 为 AsyncThrowingStream
  - BrewPathResolver.swift — which brew 自动检测路径
  - Parsers/InstalledParser.swift — 解析 brew info --json=v2 --installed
  - Parsers/InfoParser.swift — 解析 brew info --json=v2 <name>
  - Parsers/OutdatedParser.swift — 解析 brew outdated --json=v2
  - Parsers/SearchParser.swift — 解析 brew search 纯文本输出
  - BrewCommandExecutor.swift — 实现 BrewExecutor 协议
  - BrewPackageRepository.swift — 实现 PackageRepository，actor + 30s TTL 缓存
- **产出**: 8 个 Swift 文件
- **验证**: swift build 编译通过，BrewShell target 无错误

---

## Phase 4: UI 骨架

### T4.1 — App 入口 + AppState + Sidebar + Theme
- **状态**: ⬜ 待开始
- **描述**:
  - BrewMateApp.swift — @main 入口，Window 配置
  - State/AppState.swift — @Observable 全局状态（DI 注入 repository）
  - Views/ContentView.swift — NavigationSplitView 三栏主框架
  - Views/SidebarView.swift — 4 个导航项 + badge
  - Theme/ThemeManager.swift — @AppStorage 主题管理
  - Views/Components/EmptyStateView.swift — 空状态占位
  - Views/Components/LoadingOverlay.swift — 加载指示器
  - Views/Components/LogConsoleView.swift — 终端风格实时日志
- **产出**: 8 个 Swift 文件
- **验证**: swift run 启动，窗口显示三栏布局 + 侧栏导航

---

## Phase 5: 核心页面

### T5.1 — InstalledView（已安装列表）
- **状态**: ⬜ 待开始
- **描述**:
  - InstalledView.swift — 搜索过滤 + 分段控制 (All/Formula/Cask)
  - PackageRowView.swift — 图标 + 包名 + 版本 + 类型标签
  - InstalledViewModel.swift — 加载、过滤、卸载逻辑
- **产出**: 3 个 Swift 文件
- **验证**: 已安装的 26 formula + 4 cask 正确显示，过滤和分段控制正常

### T5.2 — PackageDetailView（包详情）
- **状态**: ⬜ 待开始
- **描述**:
  - PackageDetailView.swift — 包名、描述、版本、Homepage、依赖、操作按钮、日志区
  - DetailViewModel.swift — 加载详情、触发操作
- **产出**: 2 个 Swift 文件
- **验证**: 点击包名展开详情，显示完整信息，操作按钮可用

### T5.3 — ExploreView（搜索 + 安装）
- **状态**: ⬜ 待开始
- **描述**:
  - ExploreView.swift — 搜索框 (debounce 300ms) + Formula/Cask 分区结果
  - ExploreViewModel.swift — 搜索、安装逻辑
- **产出**: 2 个 Swift 文件
- **验证**: 搜索 wget 返回结果，点击安装按钮执行安装

### T5.4 — UpdatesView（更新管理）
- **状态**: ⬜ 待开始
- **描述**:
  - UpdatesView.swift — outdated 列表 + 全部更新 + 单个更新 + 日志
  - UpdatesViewModel.swift — 加载 outdated、升级逻辑
- **产出**: 2 个 Swift 文件
- **验证**: 显示 3 个 outdated（node, cc-switch, wailbrew），更新按钮可用

### T5.5 — SettingsView（设置页）
- **状态**: ⬜ 待开始
- **描述**:
  - SettingsView.swift — 主题 Picker (segmented: 跟随系统/浅色/深色)
- **产出**: 1 个 Swift 文件
- **验证**: 切换主题，界面立即响应

---

## Phase 6: 打包与验证

### T6.1 — 全量编译验证
- **状态**: ⬜ 待开始
- **描述**: swift build 零错误零 warning，swift run 启动正常
- **验证**: 编译输出干净

### T6.2 — 功能回归测试
- **状态**: ⬜ 待开始
- **描述**:
  - 已安装列表加载（首次 ~7s，切 tab 秒返回）
  - 搜索 + 安装 + 卸载流程
  - 更新检测 + 单个/全部更新
  - 主题切换 Light/Dark/System
  - 错误处理（安装不存在的包）
  - 缓存验证（10s 内切回 Installed 秒返回）
- **验证**: 全部通过

---

## 进度日志

| 时间 | 任务 | 操作 | 备注 |
|------|------|------|------|
| 2026-06-19 | — | 创建文档 | tasks.md 初始化 |
| 2026-06-19 | T0.1 | ✅ 完成 | Git 仓库初始化 + 远程关联，main/develop 分支已推送 |
| 2026-06-19 | T1.1 | ✅ 完成 | Package.swift + 完整目录骨架，swift build 通过 |
| 2026-06-19 | T1.2 | ✅ 完成 | build.sh 构建脚本，BrewMate.app 生成成功 |
