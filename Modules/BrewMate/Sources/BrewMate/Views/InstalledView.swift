import SwiftUI
import BrewKit

/// 已安装页面 — 搜索过滤 + 批量操作 + 多选包列表
struct InstalledView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = InstalledViewModel()

    var body: some View {
        VStack(spacing: 0) {
            searchBar(searchText: $viewModel.searchText)
            filterBar(selected: $viewModel.selectedType)
            batchActionBar

            Divider()

            if viewModel.isLoading && viewModel.packages.isEmpty {
                LoadingOverlay("正在加载已安装列表...")
            } else if let error = viewModel.errorMessage, viewModel.packages.isEmpty {
                EmptyStateView(
                    icon: "exclamationmark.triangle",
                    title: "加载失败",
                    message: error
                )
            } else if viewModel.filteredPackages.isEmpty {
                EmptyStateView(
                    icon: "magnifyingglass",
                    title: "没有找到包",
                    message: viewModel.searchText.isEmpty
                        ? "暂无已安装的包"
                        : "没有匹配 \"\(viewModel.searchText)\" 的包"
                )
            } else {
                List(selection: $viewModel.listSelectionID) {
                    ForEach(viewModel.filteredPackages) { package in
                        PackageRowView(
                            package,
                            isUpgradable: package.isOutdated,
                            isSelectedForBatch: viewModel.selectedIDs.contains(package.id),
                            onToggleBatchSelection: {
                                viewModel.toggleBatchSelection(for: package)
                            }
                        )
                            .tag(package.id)
                            .contextMenu {
                                Button("查看详情") {
                                    viewModel.focus(package, appState: appState)
                                }
                                if package.isOutdated {
                                    Button("更新") {
                                        viewModel.selectedIDs = [package.id]
                                        viewModel.focus(package, appState: appState)
                                        Task { await viewModel.upgradeSelected(repository: appState.repository, appState: appState) }
                                    }
                                }
                                Button("加入批量选择") {
                                    viewModel.selectedIDs.insert(package.id)
                                    viewModel.focus(package, appState: appState)
                                }
                                Button("卸载", role: .destructive) {
                                    viewModel.selectedIDs = [package.id]
                                    viewModel.focus(package, appState: appState)
                                    viewModel.requestBulkUninstallConfirmation()
                                }
                            }
                    }
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }
        }
        .navigationTitle("已安装")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task { await viewModel.load(repository: appState.repository) }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(viewModel.isLoading || viewModel.batchOperation != nil)
                .help("刷新")
            }
        }
        .confirmationDialog(
            "确认批量卸载",
            isPresented: bulkUninstallConfirmationBinding,
            titleVisibility: .visible
        ) {
            Button("卸载 \(viewModel.pendingBulkUninstallConfirmation.count) 个包", role: .destructive) {
                Task { await viewModel.uninstallSelected(repository: appState.repository, appState: appState) }
            }
            Button("取消", role: .cancel) {
                viewModel.cancelBulkUninstallConfirmation()
            }
        } message: {
            Text("即将卸载: \(viewModel.pendingBulkUninstallConfirmation.map(\.name).joined(separator: "、"))")
        }
        .task {
            if !appState.installed.isEmpty && viewModel.packages.isEmpty {
                viewModel.syncPackages(appState.installed)
                viewModel.updateFocusedPackage(using: appState.installed, appState: appState)
            } else if appState.isReady {
                if appState.outdated.isEmpty && !appState.isLoadingOutdated {
                    await appState.loadOutdated()
                }
                await viewModel.load(repository: appState.repository)
                viewModel.updateFocusedPackage(using: viewModel.packages, appState: appState)
            }
        }
        .onChange(of: appState.installed) {
            viewModel.syncPackages(appState.installed)
            viewModel.updateFocusedPackage(using: appState.installed, appState: appState)
        }
        .onChange(of: appState.isReady) {
            if appState.isReady {
                Task {
                    if appState.outdated.isEmpty && !appState.isLoadingOutdated {
                        await appState.loadOutdated()
                    }
                    await viewModel.load(repository: appState.repository)
                    viewModel.updateFocusedPackage(using: viewModel.packages, appState: appState)
                }
            }
        }
        .onChange(of: viewModel.focusedPackageID) {
            viewModel.syncSelectionToAppState(appState: appState)
        }
        .onChange(of: viewModel.listSelectionID) {
            viewModel.focus(packageID: viewModel.listSelectionID, appState: appState)
        }
    }

    // MARK: - Subviews

    private var batchActionBar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                let selectedCount = viewModel.selectedPackages.count
                let updatableCount = viewModel.updatableSelectionCount(outdated: appState.outdated)

                Text(selectedCount == 0 ? "未选择项目" : "已选择 \(selectedCount) 个包")
                    .font(.callout)
                    .foregroundStyle(.secondary)

                Button {
                    if viewModel.allFilteredSelected {
                        viewModel.clearSelection()
                    } else {
                        viewModel.selectAllFiltered()
                    }
                } label: {
                    Label(viewModel.allFilteredSelected ? "清空选择" : "全选当前结果", systemImage: viewModel.allFilteredSelected ? "xmark.circle" : "checkmark.circle")
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.filteredPackages.isEmpty || viewModel.batchOperation != nil || viewModel.operation != nil)

                Spacer()

                Button {
                    Task { await viewModel.upgradeSelected(repository: appState.repository, appState: appState) }
                } label: {
                    Label("批量更新 \(viewModel.selectedPackageCountLabel(updatableCount))", systemImage: "arrow.up.circle")
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .disabled(updatableCount == 0 || viewModel.batchOperation != nil || viewModel.operation != nil)

                Button(role: .destructive) {
                    viewModel.requestBulkUninstallConfirmation()
                } label: {
                    Label("批量卸载 \(viewModel.selectedPackageCountLabel(selectedCount))", systemImage: "trash")
                }
                .buttonStyle(.bordered)
                .disabled(selectedCount == 0 || viewModel.batchOperation != nil || viewModel.operation != nil)

                Button {
                    Task { await viewModel.load(repository: appState.repository) }
                } label: {
                    Label("刷新", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.isLoading || viewModel.batchOperation != nil)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)

            if let batchOperation = viewModel.batchOperation {
                HStack(spacing: 8) {
                    ProgressView(value: batchOperation.progress)
                        .frame(width: 120)
                    Text(batchOperation.label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let lastOutput = batchOperation.lastOutput, !lastOutput.isEmpty {
                        Text(lastOutput)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            } else if let batchErrorSummary = viewModel.batchErrorSummary {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text(batchErrorSummary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("关闭") {
                        viewModel.batchErrorSummary = nil
                    }
                    .buttonStyle(.plain)
                    .font(.caption)
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
        }
    }

    private var bulkUninstallConfirmationBinding: Binding<Bool> {
        Binding(
            get: { !viewModel.pendingBulkUninstallConfirmation.isEmpty },
            set: { isPresented in
                if !isPresented {
                    viewModel.cancelBulkUninstallConfirmation()
                }
            }
        )
    }

    private func searchBar(searchText: Binding<String>) -> some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("搜索已安装的包...", text: searchText)
                .textFieldStyle(.plain)
            if !searchText.wrappedValue.isEmpty {
                Button {
                    searchText.wrappedValue = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private func filterBar(selected: Binding<InstalledViewModel.PackageFilter>) -> some View {
        Picker("类型", selection: selected) {
            ForEach(InstalledViewModel.PackageFilter.allCases, id: \.self) { filter in
                Text(filter.rawValue).tag(filter)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .padding(.vertical, 6)
    }
}
