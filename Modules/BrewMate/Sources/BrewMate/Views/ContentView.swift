import SwiftUI
import BrewKit
import BrewShell

/// 主框架 — NavigationSplitView 三栏布局
struct ContentView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationSplitView {
            SidebarView(
                selection: $appState.selectedSidebar,
                outdatedCount: appState.outdated.count,
                showTrustWarning: appState.shouldShowTrustWarning
            )
            .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 250)
        } content: {
            contentColumn
        } detail: {
            detailColumn
        }
        .navigationSplitViewStyle(.balanced)
        .onChange(of: appState.selectedSidebar) {
            appState.selectedPackage = nil
            appState.selectedExplorePackage = nil
        }
    }

    @ViewBuilder
    private var contentColumn: some View {
        switch appState.selectedSidebar {
        case .installed:
            InstalledView()
        case .explore:
            ExploreView()
        case .settings:
            SettingsView()
        }
    }

    @ViewBuilder
    private var detailColumn: some View {
        switch appState.selectedSidebar {
        case .installed:
            if let package = appState.selectedPackage {
                PackageDetailView(package: package)
                    .id(package.id)
            } else {
                EmptyStateView(
                    icon: "shippingbox",
                    title: "选择一个包",
                    message: "从已安装列表中选择一个包查看详情"
                )
            }

        case .explore:
            if let package = appState.selectedExplorePackage {
                PackageDetailView(package: package)
                    .id(package.id)
            } else {
                EmptyStateView(
                    icon: "magnifyingglass",
                    title: "选择一个结果",
                    message: "从搜索结果中选择一个包查看详情"
                )
            }

        case .settings:
            EmptyStateView(
                icon: "paintpalette",
                title: "设置",
                message: "主题和应用信息显示在中间栏"
            )
        }
    }

}
