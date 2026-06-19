import Foundation
@preconcurrency import BrewKit

/// 解析 `brew info --installed --json=v2` 输出
/// 同时处理 formulae 和 casks 两个数组
enum InstalledParser {

    /// 将 JSON 数据解析为 [BrewPackage]（已安装列表）
    static func parse(_ data: Data) throws -> [BrewPackage] {
        let decoder = JSONDecoder()
        let envelope = try decoder.decode(HomebrewJSON.self, from: data)

        var packages: [BrewPackage] = []
        packages.reserveCapacity(envelope.formulae.count + envelope.casks.count)

        for formula in envelope.formulae {
            packages.append(parseFormula(formula))
        }
        for cask in envelope.casks {
            packages.append(parseCask(cask))
        }

        return packages
    }

    // MARK: - Formula

    private static func parseFormula(_ f: FormulaJSON) -> BrewPackage {
        let installedVersions = f.installed.map(\.version)
        let currentVersion: String
        if let stable = f.versions.stable {
            currentVersion = stable
        } else {
            currentVersion = installedVersions.first ?? "unknown"
        }

        return BrewPackage(
            name: f.name,
            fullName: f.full_name,
            type: .formula,
            description: f.desc,
            homepage: f.homepage.first,
            currentVersion: currentVersion,
            installedVersions: installedVersions,
            isInstalled: !f.installed.isEmpty,
            isOutdated: false // outdated 信息由 OutdatedParser 补充
        )
    }

    // MARK: - Cask

    private static func parseCask(_ c: CaskJSON) -> BrewPackage {
        let currentVersion = c.version ?? "latest"
        let installedVersions: [String] = c.installed != nil ? [c.installed!] : []

        return BrewPackage(
            name: c.token,
            fullName: c.full_token,
            type: .cask,
            description: c.desc ?? "",
            homepage: c.homepage,
            currentVersion: currentVersion,
            installedVersions: installedVersions,
            isInstalled: c.installed != nil,
            isOutdated: false
        )
    }
}
