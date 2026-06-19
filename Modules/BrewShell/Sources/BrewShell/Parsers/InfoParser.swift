import Foundation
@preconcurrency import BrewKit

/// 解析 `brew info --json=v2 <name>` 输出
/// 返回单个包的详细信息
enum InfoParser {

    /// 将 JSON 数据解析为 BrewPackageDetail
    /// - Parameters:
    ///   - data: brew info --json=v2 输出的原始数据
    ///   - packageType: 指定解析为 formula 还是 cask
    static func parse(_ data: Data, type packageType: PackageType) throws -> BrewPackageDetail {
        let decoder = JSONDecoder()
        let envelope = try decoder.decode(HomebrewJSON.self, from: data)

        switch packageType {
        case .formula:
            guard let formula = envelope.formulae.first else {
                throw BrewError.parsingFailed(detail: "formulae 数组为空")
            }
            return parseFormulaDetail(formula)

        case .cask:
            guard let cask = envelope.casks.first else {
                throw BrewError.parsingFailed(detail: "casks 数组为空")
            }
            return parseCaskDetail(cask)
        }
    }

    // MARK: - Formula Detail

    private static func parseFormulaDetail(_ f: FormulaJSON) -> BrewPackageDetail {
        let installedVersions = f.installed.map(\.version)
        let currentVersion = f.versions.stable ?? installedVersions.first ?? "unknown"

        let package = BrewPackage(
            name: f.name,
            fullName: f.full_name,
            type: .formula,
            description: f.desc,
            homepage: f.homepage.first,
            currentVersion: currentVersion,
            installedVersions: installedVersions,
            isInstalled: !f.installed.isEmpty,
            isOutdated: false
        )

        // brew JSON 不提供安装大小，需 stat cellar 路径计算（暂不实现）
        // requiredBy: brew info 不包含反向依赖信息，需单独查询

        return BrewPackageDetail(
            package: package,
            installSize: nil,
            dependencies: f.dependencies,
            requiredBy: [],
            cellarPath: f.installed.first?.cellar,
            license: f.license,
            tap: f.tap
        )
    }

    // MARK: - Cask Detail

    private static func parseCaskDetail(_ c: CaskJSON) -> BrewPackageDetail {
        let currentVersion = c.version ?? "latest"
        let installedVersions: [String] = c.installed != nil ? [c.installed!] : []

        let package = BrewPackage(
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

        return BrewPackageDetail(
            package: package,
            installSize: nil,
            dependencies: c.depends_on.keys,
            requiredBy: [],
            cellarPath: nil,
            license: nil,
            tap: c.tap
        )
    }
}
