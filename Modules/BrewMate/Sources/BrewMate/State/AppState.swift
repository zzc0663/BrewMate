import SwiftUI
import BrewKit
import BrewShell

/// 全局共享状态 — @Observable 驱动 UI 更新
/// 所有 View 读取同一个 AppState，Explore 安装包 → Installed 自动看到更新
@MainActor
final class AppState: ObservableObject {

    // MARK: - 数据

    @Published var installed: [BrewPackage] = []
    @Published var outdated: [OutdatedPackage] = []
    @Published var commandLog: [LogEntry] = []

    // MARK: - 导航

    @Published var selectedSidebar: SidebarItem = .installed
    @Published var selectedPackage: BrewPackage?
    /// 探索页选中的包
    @Published var selectedExplorePackage: BrewPackage?
    /// 更新页选中的包
    @Published var selectedOutdated: OutdatedPackage?

    // MARK: - 加载状态

    @Published var isLoadingInstalled = false
    @Published var isLoadingOutdated = false
    @Published var isTrustOperationInProgress = false
    @Published var errorMessage: String?
    @Published var trustStatus: BrewTrustStatus?
    @Published var isTrustBannerDismissed = false

    // MARK: - 依赖

    var repository: PackageRepository
    let themeManager: ThemeManager

    /// 是否已用真实 repository 替换 placeholder
    @Published var isReady = false

    init(repository: PackageRepository, themeManager: ThemeManager) {
        self.repository = repository
        self.themeManager = themeManager
    }

    // MARK: - 操作

    /// 加载已安装列表（仅在 repository 就绪后生效）
    func loadInstalled() async {
        guard isReady else { return }
        isLoadingInstalled = true
        errorMessage = nil
        do {
            installed = try await repository.installed()
        } catch {
            if !(error is CancellationError) {
                errorMessage = error.localizedDescription
            }
        }
        isLoadingInstalled = false
    }

    /// 加载可更新列表（仅在 repository 就绪后生效）
    func loadOutdated() async {
        guard isReady else { return }
        isLoadingOutdated = true
        do {
            outdated = try await repository.outdated()
        } catch {
            if !(error is CancellationError) {
                errorMessage = error.localizedDescription
            }
        }
        isLoadingOutdated = false
    }

    /// 刷新所有数据
    func refreshAll() async {
        guard isReady else { return }
        await repository.invalidateCache()
        async let a: () = loadInstalled()
        async let b: () = loadOutdated()
        _ = await (a, b)
    }

    func refreshTrustStatus() async {
        do {
            let brewPath = try await BrewPathResolver.resolve()
            trustStatus = try await BrewEnvironmentInspector.inspect(brewPath: brewPath)
        } catch {
            if !(error is CancellationError) {
                errorMessage = error.localizedDescription
            }
        }
    }

    func trustTap(_ tap: String) async {
        guard !isTrustOperationInProgress else { return }
        isTrustOperationInProgress = true
        errorMessage = nil

        do {
            let brewPath = try await BrewPathResolver.resolve()
            try await BrewEnvironmentInspector.trustTap(brewPath: brewPath, tap: tap)
            appendLog("✅ 已信任第三方仓库: \(tap)", false)
            await refreshTrustStatus()
        } catch {
            if !(error is CancellationError) {
                errorMessage = error.localizedDescription
                appendLog("Trust failed: \(error.localizedDescription)", true)
            }
        }

        isTrustOperationInProgress = false
    }

    var shouldShowTrustWarning: Bool {
        guard let trustStatus else { return false }
        return trustStatus.hasWarning && !isTrustBannerDismissed
    }

    /// 记录命令日志
    func appendLog(command: String, content: String, isError: Bool = false) {
        let entry = LogEntry(command: command, content: content, isError: isError)
        commandLog.append(entry)
        // 保留最近 500 条
        if commandLog.count > 500 {
            commandLog.removeFirst(commandLog.count - 500)
        }
    }

    /// 便捷日志方法（content + isError）
    func appendLog(_ content: String, _ isError: Bool = false) {
        appendLog(command: "", content: content, isError: isError)
    }
}

// MARK: - Sidebar 导航项

enum SidebarItem: String, CaseIterable, Identifiable, Sendable {
    case installed
    case explore
    case updates
    case settings

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .installed: return "已安装"
        case .explore: return "探索"
        case .updates: return "更新"
        case .settings: return "设置"
        }
    }

    var icon: String {
        switch self {
        case .installed: return "house.fill"
        case .explore: return "magnifyingglass"
        case .updates: return "arrow.triangle.2.circlepath"
        case .settings: return "gearshape"
        }
    }
}
