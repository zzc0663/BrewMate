import SwiftUI
import BrewKit

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
            InstalledView()
                .navigationDestination(for: BrewPackage.self) { package in
                    PackageDetailView(package: package)
                }
        case .explore:
            ExploreView()
                .navigationDestination(for: BrewPackage.self) { package in
                    PackageDetailView(package: package)
                }
        case .updates:
            UpdatesView()
                .navigationDestination(for: OutdatedPackage.self) { package in
                    // OutdatedPackage 导航到详情（构造临时 BrewPackage）
                    PackageDetailView(package: BrewPackage(
                        name: package.name,
                        fullName: package.name,
                        type: package.type,
                        description: "",
                        homepage: nil,
                        currentVersion: package.latestVersion,
                        installedVersions: [package.installedVersion],
                        isInstalled: true,
                        isOutdated: true
                    ))
                }
        case .settings:
            SettingsView()
        }
    }
}
