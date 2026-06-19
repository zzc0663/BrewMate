import SwiftUI
import BrewKit

/// 全局共享状态 — @Observable 驱动 UI 更新
/// 所有 View 读取同一个 AppState，Explore 安装包 → Installed 自动看到更新
@Observable @MainActor
final class AppState {

    // MARK: - 数据

    var installed: [BrewPackage] = []
    var outdated: [OutdatedPackage] = []
    var activeOperations: [String: OperationStatus] = [:]
    var commandLog: [LogEntry] = []

    // MARK: - 导航

    var selectedSidebar: SidebarItem = .installed
    var selectedPackage: BrewPackage?

    // MARK: - 加载状态

    var isLoadingInstalled = false
    var isLoadingOutdated = false
    var errorMessage: String?

    // MARK: - 依赖

    var repository: PackageRepository
    let themeManager: ThemeManager

    /// 是否已用真实 repository 替换 placeholder
    var isReady = false

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
            errorMessage = error.localizedDescription
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
            errorMessage = error.localizedDescription
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

    /// 记录命令日志
    func appendLog(command: String, content: String, isError: Bool = false) {
        let entry = LogEntry(command: command, content: content, isError: isError)
        commandLog.append(entry)
        // 保留最近 500 条
        if commandLog.count > 500 {
            commandLog.removeFirst(commandLog.count - 500)
        }
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
