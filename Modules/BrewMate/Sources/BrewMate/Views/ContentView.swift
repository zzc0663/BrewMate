import SwiftUI

/// 主框架 — NavigationSplitView 三栏布局
struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var state = appState

        NavigationSplitView {
            SidebarView(
                selection: $state.selectedSidebar,
                outdatedCount: appState.outdated.count
            )
            .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 250)
        } detail: {
            detailView
        }
        .navigationSplitViewStyle(.balanced)
    }

    @ViewBuilder
    private var detailView: some View {
        switch appState.selectedSidebar {
        case .installed:
            installedPlaceholder
        case .explore:
            explorePlaceholder
        case .updates:
            updatesPlaceholder
        case .settings:
            settingsPlaceholder
        }
    }

    // MARK: - 占位视图（Phase 5 替换为真实页面）

    private var installedPlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "house.fill")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("已安装")
                .font(.title2)
            Text("共 \(appState.installed.count) 个包")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task { await appState.loadInstalled() }
    }

    private var explorePlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("探索")
                .font(.title2)
            Text("搜索并安装新的包")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var updatesPlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("更新")
                .font(.title2)
            Text("检查可用更新")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task { await appState.loadOutdated() }
    }

    private var settingsPlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "gearshape")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("设置")
                .font(.title2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
