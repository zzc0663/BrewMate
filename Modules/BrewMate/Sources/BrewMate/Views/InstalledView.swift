import SwiftUI
import BrewKit

/// 已安装页面 — 搜索过滤 + 分段控制 + 包列表
struct InstalledView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = InstalledViewModel()

    var body: some View {
        @Bindable var vm = viewModel
        @Bindable var state = appState

        VStack(spacing: 0) {
            // 搜索 + 分段控制
            searchBar(searchText: $vm.searchText)
            filterBar(selected: $vm.selectedType)

            Divider()

            // 包列表
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
                List(viewModel.filteredPackages, selection: $state.selectedPackage) { package in
                    NavigationLink(value: package) {
                        PackageRowView(package)
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
                .disabled(viewModel.isLoading)
                .help("刷新")
            }
        }
        .task {
            // 首次加载：如果 AppState 已有数据，直接用；否则从 AppState 加载
            if !appState.installed.isEmpty && viewModel.packages.isEmpty {
                viewModel.packages = appState.installed
            } else if appState.isReady {
                await viewModel.load(repository: appState.repository)
            }
        }
        .onChange(of: appState.installed) {
            // AppState 数据变化时同步到 ViewModel
            if !appState.installed.isEmpty {
                viewModel.packages = appState.installed
            }
        }
        .onChange(of: appState.isReady) {
            if appState.isReady {
                Task { await viewModel.load(repository: appState.repository) }
            }
        }
    }

    // MARK: - Subviews

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
