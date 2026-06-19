import Foundation
@preconcurrency import BrewKit

/// 解析 `brew search` 纯文本输出
/// 每行一个结果，可能混合 formula 和 cask
enum SearchParser {

    /// 将纯文本输出解析为 [BrewPackage]
    /// 注意：search 结果不含版本和安装状态，这些字段使用占位值
    static func parse(_ text: String, type: PackageType?) -> [BrewPackage] {
        let lines = text.split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && !$0.hasPrefix("==>") }

        return lines.map { line in
            // brew search 输出格式：
            // formula: "name" 或 "tap/name"
            // cask:    "name" 或带有 "(cask)" 后缀（老版本）
            // 现代 brew 不带后缀，cask 和 formula 混合输出
            return BrewPackage(
                name: line,
                fullName: line,
                type: type ?? .formula, // 无类型提示时默认 formula
                description: "",
                homepage: nil,
                currentVersion: "",
                installedVersions: [],
                isInstalled: false,
                isOutdated: false
            )
        }
    }
}
