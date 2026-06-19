import SwiftUI
import BrewKit

/// 更新页面 — outdated 列表 + 全部更新 + 单个更新
struct UpdatesView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = UpdatesViewModel()

    var body: some View {
        @Bindable var state = appState

        VStack(spacing: 0) {
            if appState.isLoadingOutdated && appState.outdated.isEmpty {
                LoadingOverlay("正在检查更新...")
            } else if appState.outdated.isEmpty {
                EmptyStateView(
                    icon: "checkmark.circle",
                    title: "全部最新",
                    message: "所有包已是最新版本"
                )
            } else {
                // 顶部操作栏
                HStack {
                    Text("发现 \(appState.outdated.count) 个可更新的包")
                        .font(.headline)
                    Spacer()
                    Button {
                        Task { await viewModel.upgradeAll(repository: appState.repository, appState: appState) }
                    } label: {
                        Label("全部更新", systemImage: "arrow.up.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.upgradingAll || viewModel.operation != nil)
                }
                .padding(.horizontal)
                .padding(.vertical, 10)

                Divider()

                // 列表
                List(appState.outdated, selection: $state.selectedOutdated) { package in
                    outdatedRow(package)
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }
        }
        .navigationTitle("更新")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task { await appState.loadOutdated() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(appState.isLoadingOutdated)
                .help("刷新")
            }
        }
        .task {
            if appState.isReady {
                await appState.loadOutdated()
            }
        }
        .onChange(of: appState.isReady) {
            if appState.isReady {
                Task { await appState.loadOutdated() }
            }
        }
    }

    // MARK: - Subviews

    private func outdatedRow(_ package: OutdatedPackage) -> some View {
        HStack(spacing: 12) {
            // 图标
            Image(systemName: package.type == .cask ? "app.fill" : "terminal.fill")
                .font(.system(size: 20))
                .foregroundStyle(package.type == .cask ? .purple : .blue)
                .frame(width: 32, height: 32)

            // 名称 + 版本变化
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(package.name)
                        .font(.headline)

                    Text(package.type.displayName)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(package.type == .cask ? .purple : .blue)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(
                            (package.type == .cask ? Color.purple : .blue).opacity(0.12),
                            in: Capsule()
                        )

                    if package.isPinned {
                        Text("已固定")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                }

                HStack(spacing: 4) {
                    Text(package.installedVersion)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Image(systemName: "arrow.right")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(package.latestVersion)
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }

            Spacer()

            // 升级按钮
            Button {
                Task { await viewModel.upgrade(package, repository: appState.repository, appState: appState) }
            } label: {
                Label("升级", systemImage: "arrow.up.circle")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .disabled(viewModel.operation != nil || package.isPinned)
        }
        .padding(.vertical, 2)
    }
}
