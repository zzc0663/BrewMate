import SwiftUI
import BrewKit
import BrewShell

/// BrewMate — macOS Homebrew 图形化管理工具
@main
struct BrewMateApp: App {
    @StateObject private var appState: AppState
    @StateObject private var themeManager: ThemeManager

    init() {
        let themeManager = ThemeManager()
        let tm = themeManager
        self._themeManager = StateObject(wrappedValue: tm)
        self._appState = StateObject(wrappedValue: AppState(
            repository: PlaceholderRepository(),
            themeManager: tm
        ))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.currentTheme.colorScheme)
                .frame(minWidth: 900, minHeight: 600)
                .task {
                    await initializeRepository()
                }
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 1100, height: 700)
    }

    /// 异步初始化 repository（检测 brew 路径）
    /// 替换 placeholder 后设置 isReady，ContentView 的 .task 会自动加载数据
    @MainActor
    private func initializeRepository() async {
        do {
            let executor = try await BrewCommandExecutor()
            let repository = BrewPackageRepository(executor: executor)
            // 原地替换 repository，保留已有的 UI 状态
            appState.repository = repository
            appState.isReady = true
            await appState.refreshTrustStatus()
            await appState.refreshAll()
        } catch {
            appState.errorMessage = "无法找到 Homebrew: \(error.localizedDescription)"
        }
    }
}

// MARK: - Placeholder Repository（启动前占位）

/// 空实现，仅用于 AppState 初始化占位
private struct PlaceholderRepository: PackageRepository {
    func installed() async throws -> [BrewPackage] { [] }
    func search(query: String, type: PackageType?) async throws -> [BrewPackage] { [] }
    func info(for package: String, type: PackageType) async throws -> BrewPackageDetail {
        throw BrewError.brewNotFound
    }
    func outdated() async throws -> [OutdatedPackage] { [] }
    func invalidateCache() async {}
    func install(name: String, type: PackageType) -> AsyncThrowingStream<CommandEvent, Error> {
        AsyncThrowingStream { $0.finish() }
    }
    func uninstall(name: String, type: PackageType) -> AsyncThrowingStream<CommandEvent, Error> {
        AsyncThrowingStream { $0.finish() }
    }
    func upgrade(name: String?, type: PackageType?) -> AsyncThrowingStream<CommandEvent, Error> {
        AsyncThrowingStream { $0.finish() }
    }
}
