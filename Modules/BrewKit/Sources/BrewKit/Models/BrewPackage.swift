import Foundation

/// 统一的 Homebrew 包模型（Formula + Cask 共用）
struct BrewPackage: Identifiable, Hashable, Sendable {
    /// 唯一标识：name + type 组合，避免 formula/cask 同名碰撞
    var id: String { "\(type.rawValue)/\(name)" }

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

    // 自定义 Hashable：仅基于身份字段（name + type），避免
    // description / installedVersions 等可变字段影响 SwiftUI diffing
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(type)
    }

    static func == (lhs: BrewPackage, rhs: BrewPackage) -> Bool {
        lhs.name == rhs.name && lhs.type == rhs.type
    }
}
