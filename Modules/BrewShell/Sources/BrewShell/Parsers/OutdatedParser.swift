import Foundation
@preconcurrency import BrewKit

/// 解析 `brew outdated --json=v2` 输出
enum OutdatedParser {

    /// 将 JSON 数据解析为 [OutdatedPackage]
    static func parse(_ data: Data) throws -> [OutdatedPackage] {
        let decoder = JSONDecoder()
        let envelope = try decoder.decode(OutdatedJSON.self, from: data)

        var packages: [OutdatedPackage] = []
        let totalCount = envelope.formulae.count + envelope.casks.count
        packages.reserveCapacity(totalCount)

        for formula in envelope.formulae {
            packages.append(OutdatedPackage(
                name: formula.name,
                type: .formula,
                installedVersion: formula.installed_versions.first ?? "unknown",
                latestVersion: formula.current_version,
                isPinned: formula.pinned
            ))
        }

        for cask in envelope.casks {
            let installedVersion = cask.installed ?? "unknown"
            let latestVersion = cask.version
            packages.append(OutdatedPackage(
                name: cask.token,
                type: .cask,
                installedVersion: installedVersion,
                latestVersion: latestVersion,
                isPinned: false
            ))
        }

        return packages
    }
}
