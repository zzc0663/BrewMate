import Foundation

/// 统一的 Homebrew 包模型（Formula + Cask 共用）
struct BrewPackage: Identifiable, Hashable, Sendable {
    var id: String { name }

    /// 短名称（formula: name; cask: token）
    let name: String
    /// 全名（formula: full_name; cask: token）
    let fullName: String
    /// 包类型
    let type: PackageType
    /// 描述
    let description: String
    /// 官网
    let homepage: String?
    /// 当前可用最新版本
    let currentVersion: String
    /// 已安装版本列表
    let installedVersions: [String]
    /// 是否已安装
    let isInstalled: Bool
    /// 是否有可用更新
    let isOutdated: Bool
}
