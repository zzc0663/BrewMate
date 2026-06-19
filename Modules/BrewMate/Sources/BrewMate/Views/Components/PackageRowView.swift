import SwiftUI
import BrewKit

/// 包列表行视图 — 图标 + 名称 + 版本 + 类型标签
struct PackageRowView: View {
    let package: BrewPackage
    let isUpgradable: Bool

    init(_ package: BrewPackage, isUpgradable: Bool = false) {
        self.package = package
        self.isUpgradable = isUpgradable
    }

    var body: some View {
        HStack(spacing: 12) {
            // 图标
            Image(systemName: package.type == .cask ? "app.fill" : "terminal.fill")
                .font(.system(size: 20))
                .foregroundStyle(package.type == .cask ? .purple : .blue)
                .frame(width: 32, height: 32)

            // 名称 + 描述
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(package.name)
                        .font(.headline)
                        .lineLimit(1)

                    Text(package.type.displayName)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(package.type == .cask ? .purple : .blue)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(
                            (package.type == .cask ? Color.purple : .blue).opacity(0.12),
                            in: Capsule()
                        )

                    if isUpgradable && package.isOutdated {
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundStyle(.orange)
                            .font(.caption)
                    }
                }

                Text(package.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // 版本
            VStack(alignment: .trailing, spacing: 2) {
                if let installed = package.installedVersions.first {
                    Text(installed)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
    }
}
