import Foundation

/// 可更新的包信息
public struct OutdatedPackage: Identifiable, Hashable, Sendable {
    /// 唯一标识：name + type 组合
    public var id: String { "\(type.rawValue)/\(name)" }

    /// 包名
    public let name: String
    /// 包类型
    public let type: PackageType
    /// 当前已安装版本
    public let installedVersion: String
    /// 可用的最新版本
    public let latestVersion: String
    /// 是否被固定（pinned）
    public let isPinned: Bool

    public init(name: String, type: PackageType, installedVersion: String, latestVersion: String, isPinned: Bool) {
        self.name = name
        self.type = type
        self.installedVersion = installedVersion
        self.latestVersion = latestVersion
        self.isPinned = isPinned
    }
}
