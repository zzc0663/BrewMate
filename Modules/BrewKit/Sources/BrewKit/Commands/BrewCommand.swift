import Foundation

/// Homebrew CLI 命令枚举
/// 新增功能只加 case，不改现有代码
public enum BrewCommand: Equatable, Sendable {
    /// 列出已安装的包（JSON 格式）
    case listInstalled
    /// 搜索包
    case search(query: String, type: PackageType?)
    /// 获取包详情
    case info(name: String, type: PackageType)
    /// 安装包
    case install(name: String, type: PackageType)
    /// 卸载包
    case uninstall(name: String, type: PackageType)
    /// 升级包（nil = 升级全部）
    case upgrade(name: String?, type: PackageType?)
    /// 更新 Homebrew 仓库
    case update
    /// 列出可更新的包
    case outdated

    /// 命令描述（用于日志和 UI 展示）
    public var commandLine: String {
        "brew " + arguments.joined(separator: " ")
    }

    /// 转换为 brew CLI 参数列表
    public var arguments: [String] {
        switch self {
        case .listInstalled:
            return ["info", "--installed", "--json=v2"]

        case .search(let query, let type):
            var args = ["search", query]
            if let type {
                args.append(type.cliFlag)
            }
            return args

        case .info(let name, let type):
            return ["info", type.cliFlag, "--json=v2", name]

        case .install(let name, let type):
            return ["install", type.cliFlag, name]

        case .uninstall(let name, let type):
            return ["uninstall", type.cliFlag, name]

        case .upgrade(let name, let type):
            var args = ["upgrade"]
            if let type {
                args.append(type.cliFlag)
            }
            if let name {
                args.append(name)
            }
            return args

        case .update:
            return ["update"]

        case .outdated:
            return ["outdated", "--json=v2"]
        }
    }
}
