import Foundation

/// 统一的 Homebrew 包模型（Formula + Cask 共用）
public struct BrewPackage: Identifiable, Hashable, Sendable {
    /// 唯一标识：name + type 组合，避免 formula/cask 同名碰撞
    public var id: String { "\(type.rawValue)/\(name)" }

    /// 短名称（formula: name; cask: token）
    public let name: String
    /// 全名（formula: full_name; cask: token）
    public let fullName: String
    /// 包类型
    public let type: PackageType
    /// 描述
    public let description: String
    /// 官网
    public let homepage: String?
    /// 当前可用最新版本
    public let currentVersion: String
    /// 已安装版本列表
    public let installedVersions: [String]
    /// 是否已安装
    public let isInstalled: Bool
    /// 是否有可用更新
    public let isOutdated: Bool

    // 自定义 Hashable：仅基于身份字段（name + type），避免
    // description / installedVersions 等可变字段影响 SwiftUI diffing
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(type)
    }

    public static func == (lhs: BrewPackage, rhs: BrewPackage) -> Bool {
        lhs.name == rhs.name && lhs.type == rhs.type
    }

    public init(name: String, fullName: String, type: PackageType, description: String, homepage: String?, currentVersion: String, installedVersions: [String], isInstalled: Bool, isOutdated: Bool) {
        self.name = name
        self.fullName = fullName
        self.type = type
        self.description = description
        self.homepage = homepage
        self.currentVersion = currentVersion
        self.installedVersions = installedVersions
        self.isInstalled = isInstalled
        self.isOutdated = isOutdated
    }
}
