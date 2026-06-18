# BrewMate — macOS Homebrew 图形化管理工具 (v2)

## Summary

使用 Swift + SwiftUI 构建原生 macOS 桌面应用，管理 Homebrew 的 Formula 和 Cask 包。采用三层 SPM 模块化架构（BrewKit / BrewShell / BrewMate），协议驱动、命令模式、Actor 缓存、@Observable 全局状态。支持 Light/Dark 跟随系统切换。

**环境**: macOS 14+ (Sonoma), Swift 5.9+, Homebrew 6.x (Apple Silicon `/opt/homebrew/bin/brew`)

---

## 1. 三层模块架构

依赖方向严格单向：`BrewMate(UI)` → `BrewShell(Infra)` → `BrewKit(Domain)`

```
BrewMate/
├── Package.swift                          # 3 targets: BrewKit, BrewShell, BrewMate
├── Modules/
│   ├── BrewKit/                           # 领域层 — 纯 Swift, 零外部依赖
│   │   └── Sources/BrewKit/
│   │       ├── Models/
│   │       │   ├── BrewPackage.swift      # 统一包模型 (formula+cask)
│   │       │   ├── PackageType.swift      # enum: .formula / .cask
│   │       │   ├── BrewError.swift        # 结构化错误 (LocalizedError)
│   │       │   ├── CommandEvent.swift     # .output(String) / .error(String) / .completed(Int32)
│   │       │   └── OperationStatus.swift  # .idle / .running / .success / .failed
│   │       ├── Protocols/
│   │       │   ├── BrewExecutor.swift     # func execute(_ command: BrewCommand) → AsyncThrowingStream<CommandEvent>
│   │       │   └── PackageRepository.swift# installed/search/info/outdated + invalidateCache
│   │       └── Commands/
│   │           └── BrewCommand.swift      # enum 每个 case 自知 CLI 参数
│   │
│   ├── BrewShell/                         # 基础设施层 — Process, shell, 缓存
│   │   └── Sources/BrewShell/
│   │       ├── ProcessRunner.swift        # async Process 封装 → AsyncThrowingStream
│   │       ├── BrewPathResolver.swift     # which brew 自动检测路径
│   │       ├── Parsers/
│   │       │   ├── InstalledParser.swift  # brew info --json=v2 --installed 解析
│   │       │   ├── InfoParser.swift       # brew info --json=v2 <name> 解析
│   │       │   ├── OutdatedParser.swift   # brew outdated --json=v2 解析
│   │       │   └── SearchParser.swift     # brew search 纯文本逐行解析
│   │       ├── BrewCommandExecutor.swift  # 实现 BrewExecutor 协议
│   │       └── BrewPackageRepository.swift# 实现 PackageRepository, actor + TTL 缓存
│   │
│   └── BrewMate/                          # UI 层 — SwiftUI 应用
│       └── Sources/BrewMate/
│           ├── BrewMateApp.swift          # @main, Window, Settings, AppDelegate
│           ├── State/
│           │   └── AppState.swift         # @Observable 全局共享状态
│           ├── ViewModels/
│           │   ├── InstalledViewModel.swift
│           │   ├── ExploreViewModel.swift
│           │   ├── UpdatesViewModel.swift
│           │   └── DetailViewModel.swift
│           ├── Views/
│           │   ├── ContentView.swift      # NavigationSplitView 三栏主框架
│           │   ├── SidebarView.swift      # 左侧导航
│           │   ├── Installed/
│           │   │   ├── InstalledView.swift
│           │   │   └── PackageRowView.swift
│           │   ├── Explore/
│           │   │   └── ExploreView.swift
│           │   ├── Updates/
│           │   │   └── UpdatesView.swift
│           │   ├── Detail/
│           │   │   └── PackageDetailView.swift
│           │   ├── Settings/
│           │   │   └── SettingsView.swift
│           │   └── Components/
│           │       ├── LoadingOverlay.swift
│           │       ├── LogConsoleView.swift   # 终端风格实时日志
│           │       └── EmptyStateView.swift
│           └── Theme/
│               └── ThemeManager.swift     # @AppStorage 主题管理
└── build.sh                               # 构建 .app bundle 脚本
```

---

## 2. 核心模型设计

### BrewCommand (命令模式)

```swift
enum BrewCommand: Sendable {
    case listInstalled
    case search(query: String, type: PackageType?)
    case info(name: String, type: PackageType)
    case install(name: String, type: PackageType)
    case uninstall(name: String, type: PackageType)
    case upgrade(name: String?, type: PackageType?) // nil = upgrade all
    case update
    case outdated

    var arguments: [String] { /* 每个 case 返回对应 brew CLI 参数 */ }
}
```

新增功能（如 brewfile import/export, services）只加 case，不改现有代码。

### BrewPackage (统一模型)

```swift
struct BrewPackage: Identifiable, Hashable, Sendable {
    var id: String { name }
    let name: String
    let fullName: String          // formula: full_name; cask: token
    let type: PackageType
    let description: String
    let homepage: String?
    let currentVersion: String
    let installedVersions: [String]
    let isInstalled: Bool
    let isOutdated: Bool
}
```

### Protocols

```swift
protocol BrewExecutor: Sendable {
    func execute(_ command: BrewCommand) -> AsyncThrowingStream<CommandEvent, Error>
}

protocol PackageRepository: Sendable {
    func installed() async throws -> [BrewPackage]
    func search(query: String) async throws -> [BrewPackage]
    func info(for package: String, type: PackageType) async throws -> BrewPackageDetail
    func outdated() async throws -> [OutdatedPackage]
    func invalidateCache()
    func install(name: String, type: PackageType) -> AsyncThrowingStream<CommandEvent, Error>
    func uninstall(name: String, type: PackageType) -> AsyncThrowingStream<CommandEvent, Error>
    func upgrade(name: String?, type: PackageType?) -> AsyncThrowingStream<CommandEvent, Error>
}
```

### BrewError (结构化错误)

```swift
enum BrewError: LocalizedError {
    case commandFailed(command: String, exitCode: Int32, stderr: String)
    case notFound(package: String)
    case alreadyInstalled(package: String)
    case brewNotFound
    case parsingFailed(detail: String)
    // 每个 case 提供 errorDescription，直接显示给用户
}
```

---

## 3. Actor 缓存策略

`BrewPackageRepository` 用 `actor` 保证线程安全，内置 30 秒 TTL 缓存：

- `installed()` / `outdated()` 优先返回缓存
- `install` / `uninstall` / `upgrade` 操作完成后自动调 `invalidateCache()`
- 下次读取时惰性刷新

`brew info --json=v2 --installed` 从 7 秒变为：首次 7 秒，后续瞬间返回。

---

## 4. @Observable 全局状态

```swift
@Observable
class AppState {
    var installed: [BrewPackage] = []
    var outdated: [OutdatedPackage] = []
    var activeOperations: [String: OperationStatus] = [:]
    var commandLog: [LogEntry] = []
    var selectedSidebar: SidebarItem = .installed
    var selectedPackage: BrewPackage?

    let repository: PackageRepository  // DI 注入
}
```

所有 View 读取同一个 AppState，Explore 安装包 → Installed 自动看到更新（通过 invalidateCache + refresh）。

---

## 5. UI 层设计

### 窗口结构

`NavigationSplitView` 三栏: Sidebar(200pt) | List(flexible) | Detail(300pt+)

### SidebarView (4 个导航项)

| 图标 | 标签 | 说明 |
|------|------|------|
| `house.fill` | 已安装 | InstalledView |
| `magnifyingglass` | 探索 | ExploreView |
| `arrow.triangle.2.circlepath` | 更新 | UpdatesView (有可更新时显示 badge) |
| `gearshape` | 设置 | SettingsView |

### InstalledView

- 顶部: 本地搜索过滤 + 分段控制 (All / Formula / Cask)
- 列表: PackageRowView (图标 + 包名 + 版本 + 类型标签)
- 选中行展开 PackageDetailView
- 右键菜单: 卸载 / 查看详情 / 复制名称

### ExploreView

- 搜索输入框, debounce 300ms 后触发 `brew search`
- 结果分 Formula / Cask 两个 Section
- 已安装的包显示绿色勾 + "已安装" 标签
- 未安装显示 "安装" 按钮

### UpdatesView

- 自动加载 `brew outdated`
- 每行: 包名 + 当前版本 → 最新版本
- "全部更新" 按钮 + 单个 "更新" 按钮
- 更新时 LogConsoleView 实时显示 brew 输出

### PackageDetailView

- 包名、描述、版本、Homepage 外链
- 依赖列表
- 操作按钮: 安装 / 卸载 / 更新 (根据状态动态显示)
- 底部 LogConsoleView

### SettingsView

- 主题切换: Picker segmented (跟随系统 / 浅色 / 深色)
- 使用 `preferredColorScheme()` modifier 生效

### ThemeManager

```swift
enum AppTheme: String, CaseIterable {
    case system, light, dark
}
// @AppStorage("appTheme") 持久化
```

---

## 6. 构建方案

- **开发**: `swift run` 直接运行
- **打包**: `build.sh` 执行 `swift build -c release` → 创建 `BrewMate.app/Contents/MacOS/` + `Info.plist` → 产出可双击运行的 `.app`

---

## 7. 实现顺序

1. **Package.swift + BrewKit** — 3 个 target 定义、模型、协议、命令枚举
2. **BrewShell** — ProcessRunner、Parsers、BrewCommandExecutor、BrewPackageRepository
3. **BrewMate App 骨架** — AppState、ContentView、SidebarView、ThemeManager
4. **InstalledView** — 列表 + 过滤 + PackageRowView + PackageDetailView
5. **ExploreView** — 搜索 + 安装
6. **UpdatesView** — 更新列表 + 全部更新 + LogConsoleView
7. **SettingsView** — 主题切换
8. **build.sh** — 打包脚本

---

## 8. Test Plan

| 场景 | 验证方式 |
|------|---------|
| `swift build` 编译通过 | 零 error zero warning |
| 启动显示三栏布局 | 运行后 Sidebar + List + Detail 正常 |
| 已安装列表加载 | 首次 ~7s 加载 26 formula + 4 cask，切换 tab 秒返回 |
| 搜索 | 输入 `wget` → 300ms debounce → 显示结果 |
| 安装/卸载 | Explore 安装 → Installed 列表刷新；Installed 卸载 → 列表刷新 |
| 更新检测 | Updates 显示 3 个 outdated (node, cc-switch, wailbrew) |
| 实时日志 | 安装/更新时 LogConsoleView 逐行输出 brew stdout |
| 主题切换 | Settings 切 Light/Dark/System，界面立即响应 |
| 错误处理 | 安装不存在的包 → 显示友好错误，不崩溃 |
| 缓存 | Installed 页首次加载后，10 秒内再切回，数据瞬间出现 |

---

## 9. Assumptions

- macOS 14+ (Sonoma)，Swift 5.9+ (支持 `@Observable`, `async/await`, `AsyncThrowingStream`)
- brew 路径默认 `/opt/homebrew/bin/brew`，通过 `which brew` 自动检测
- `brew search` 不支持 `--json`，解析纯文本（每行一个结果）
- 不含 `brew services` 管理（v2 可扩展）
- 不含应用图标设计（使用默认 SF Symbol）
- 应用无沙盒限制（直接调用 brew CLI 需要文件系统权限）
