import SwiftUI
import BrewKit

/// 探索页面 — 搜索框 + Formula/Cask 分区结果
struct ExploreView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = ExploreViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // 搜索框
            searchBar(searchText: $viewModel.searchText)

            Divider()

            // 结果列表
            if viewModel.isLoading && viewModel.results.isEmpty {
                LoadingOverlay("正在搜索...")
            } else if let error = viewModel.errorMessage, viewModel.results.isEmpty {
                EmptyStateView(
                    icon: "exclamationmark.triangle",
                    title: "搜索失败",
                    message: error
                )
            } else if viewModel.searchText.isEmpty {
                EmptyStateView(
                    icon: "magnifyingglass",
                    title: "探索 Homebrew",
                    message: "搜索 Formula 或 Cask 包"
                )
            } else if viewModel.results.isEmpty {
                EmptyStateView(
                    icon: "questionmark.folder",
                    title: "没有结果",
                    message: "没有找到 \"\(viewModel.searchText)\" 相关的包"
                )
            } else {
                List(selection: $appState.selectedExplorePackage) {
                    // Formula 分区
                    if !viewModel.formulae.isEmpty {
                        Section("Formula (\(viewModel.formulae.count))") {
                            ForEach(viewModel.formulae) { package in
                                PackageRowView(package)
                                    .tag(package)
                            }
                        }
                    }

                    // Cask 分区
                    if !viewModel.casks.isEmpty {
                        Section("Cask (\(viewModel.casks.count))") {
                            ForEach(viewModel.casks) { package in
                                PackageRowView(package)
                                    .tag(package)
                            }
                        }
                    }
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }
        }
        .navigationTitle("探索")
        .onChange(of: viewModel.searchText) {
            viewModel.searchTextChanged(repository: appState.repository)
        }
    }

    // MARK: - Subviews

    private func searchBar(searchText: Binding<String>) -> some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("搜索 Formula 或 Cask...", text: searchText)
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
        .padding(.vertical, 8)
    }
}
