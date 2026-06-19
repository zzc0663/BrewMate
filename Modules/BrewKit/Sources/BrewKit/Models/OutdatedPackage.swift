import Foundation

/// 可更新的包信息
struct OutdatedPackage: Identifiable, Sendable {
    /// 唯一标识：name + type 组合
    var id: String { "\(type.rawValue)/\(name)" }

    /// 包名
    let name: String
    /// 包类型
    let type: PackageType
    /// 当前已安装版本
    let installedVersion: String
    /// 可用的最新版本
    let latestVersion: String
    /// 是否被固定（pinned）
    let isPinned: Bool
}
