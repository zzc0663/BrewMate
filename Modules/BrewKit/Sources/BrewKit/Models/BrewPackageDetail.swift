import Foundation

/// 包的详细信息（info 页面用）
public struct BrewPackageDetail: Hashable, Sendable {
    /// 基础信息
    public let package: BrewPackage
    /// 安装大小（字节数，nil 表示未知）
    public let installSize: Int64?
    /// 依赖列表
    public let dependencies: [String]
    /// 被哪些包依赖
    public let requiredBy: [String]
    /// 安装路径
    public let cellarPath: String?
    /// License
    public let license: String?
    /// tap 来源（如 homebrew/core）
    public let tap: String?

    public init(package: BrewPackage, installSize: Int64?, dependencies: [String], requiredBy: [String], cellarPath: String?, license: String?, tap: String?) {
        self.package = package
        self.installSize = installSize
        self.dependencies = dependencies
        self.requiredBy = requiredBy
        self.cellarPath = cellarPath
        self.license = license
        self.tap = tap
    }
}
