import Foundation

/// 包的详细信息（info 页面用）
struct BrewPackageDetail: Sendable {
    /// 基础信息
    let package: BrewPackage
    /// 安装大小（字节数，nil 表示未知）
    let installSize: Int64?
    /// 依赖列表
    let dependencies: [String]
    /// 被哪些包依赖
    let requiredBy: [String]
    /// 安装路径
    let cellarPath: String?
    /// License
    let license: String?
    /// tap 来源（如 homebrew/core）
    let tap: String?
}
