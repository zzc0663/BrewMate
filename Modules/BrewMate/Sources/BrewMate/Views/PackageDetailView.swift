import SwiftUI
import BrewKit

/// 包详情页面 — 基本信息 + 依赖 + 操作按钮 + 日志
struct PackageDetailView: View {
    let package: BrewPackage
    @Environment(AppState.self) private var appState
    @State private var viewModel = DetailViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 头部：名称 + 类型 + 版本
                headerSection

                Divider()

                if viewModel.isLoading {
                    HStack {
                        Spacer()
                        LoadingOverlay("加载详情...")
                        Spacer()
                    }
                } else if let error = viewModel.errorMessage {
                    EmptyStateView(
                        icon: "exclamationmark.triangle",
                        title: "加载失败",
                        message: error
                    )
                } else if let detail = viewModel.detail {
                    // 基本信息
                    infoSection(detail)

                    Divider()

                    // 依赖
                    dependencySection(detail)

                    Divider()

                    // 操作按钮
                    actionSection(detail)

                    Divider()

                    // 日志
                    logSection
                }
            }
            .padding()
        }
        .navigationTitle(package.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task { await viewModel.loadDetail(for: package, repository: appState.repository) }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(viewModel.isLoading)
                .help("刷新详情")
            }
        }
        .task {
            await viewModel.loadDetail(for: package, repository: appState.repository)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(spacing: 16) {
            Image(systemName: package.type == .cask ? "app.fill" : "terminal.fill")
                .font(.system(size: 40))
                .foregroundStyle(package.type == .cask ? .purple : .blue)
                .frame(width: 56, height: 56)
                .background(
                    (package.type == .cask ? Color.purple : .blue).opacity(0.1),
                    in: RoundedRectangle(cornerRadius: 12)
                )

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(package.name)
                        .font(.title)
                        .fontWeight(.bold)

                    Text(package.type.displayName)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(package.type == .cask ? .purple : .blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            (package.type == .cask ? Color.purple : .blue).opacity(0.12),
                            in: Capsule()
                        )
                }

                Text(package.description)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    // MARK: - Info

    private func infoSection(_ detail: BrewPackageDetail) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("信息")
                .font(.headline)

            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
                infoRow("当前版本", package.currentVersion)
                if let installed = package.installedVersions.first {
                    infoRow("已安装", installed)
                }
                if let license = detail.license {
                    infoRow("许可证", license)
                }
                if let tap = detail.tap {
                    infoRow("来源", tap)
                }
                if let path = detail.cellarPath {
                    infoRow("路径", path)
                }
            }

            if let homepage = package.homepage, let url = URL(string: homepage) {
                Link("🌐 官网", destination: url)
                    .font(.callout)
                    .padding(.top, 4)
            }
        }
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        GridRow {
            Text(label)
                .foregroundStyle(.secondary)
                .frame(width: 80, alignment: .trailing)
            Text(value)
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
        }
    }

    // MARK: - Dependencies

    private func dependencySection(_ detail: BrewPackageDetail) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("依赖")
                .font(.headline)

            if detail.dependencies.isEmpty && detail.requiredBy.isEmpty {
                Text("无依赖")
                    .foregroundStyle(.secondary)
                    .font(.callout)
            } else {
                if !detail.dependencies.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("依赖于 (\(detail.dependencies.count))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        FlowLayout(spacing: 6) {
                            ForEach(detail.dependencies, id: \.self) { dep in
                                Text(dep)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(.blue.opacity(0.1), in: Capsule())
                            }
                        }
                    }
                }

                if !detail.requiredBy.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("被依赖 (\(detail.requiredBy.count))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        FlowLayout(spacing: 6) {
                            ForEach(detail.requiredBy, id: \.self) { dep in
                                Text(dep)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(.orange.opacity(0.1), in: Capsule())
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func actionSection(_ detail: BrewPackageDetail) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("操作")
                .font(.headline)

            HStack(spacing: 12) {
                if package.isInstalled {
                    if package.isOutdated {
                        Button {
                            Task {
                                await viewModel.performOperation(
                                    .upgrade,
                                    package: package,
                                    repository: appState.repository,
                                    appState: appState
                                )
                            }
                        } label: {
                            Label("升级", systemImage: "arrow.up.circle")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.orange)
                        .disabled(viewModel.operation != nil)
                    }

                    Button(role: .destructive) {
                        Task {
                            await viewModel.performOperation(
                                .uninstall,
                                package: package,
                                repository: appState.repository,
                                appState: appState
                            )
                        }
                    } label: {
                        Label("卸载", systemImage: "trash")
                    }
                    .buttonStyle(.bordered)
                    .disabled(viewModel.operation != nil)
                } else {
                    Button {
                        Task {
                            await viewModel.performOperation(
                                .install,
                                package: package,
                                repository: appState.repository,
                                appState: appState
                            )
                        }
                    } label: {
                        Label("安装", systemImage: "arrow.down.circle")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.operation != nil)
                }

                if let op = viewModel.operation {
                    Spacer()
                    ProgressView()
                        .scaleEffect(0.8)
                    Text(op.label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Log

    private var logSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("操作日志")
                .font(.headline)

            if appState.commandLog.isEmpty {
                Text("暂无操作日志")
                    .foregroundStyle(.secondary)
                    .font(.callout)
            } else {
                LogConsoleView(entries: Array(appState.commandLog.suffix(50)))
                    .frame(height: 200)
            }
        }
    }
}

// MARK: - FlowLayout

/// 简单的流式布局（横向自动换行）
struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, origin) in result.origins.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + origin.x, y: bounds.minY + origin.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, origins: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var origins: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            origins.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxX = max(maxX, x)
        }

        return (CGSize(width: maxX, height: y + rowHeight), origins)
    }
}
