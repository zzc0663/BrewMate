import Foundation

/// Homebrew CLI 命令枚举
/// 新增功能只加 case，不改现有代码
enum BrewCommand: Sendable {
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
    var description: String {
        switch self {
        case .listInstalled:
            return "brew list --installed"
        case .search(let query, _):
            return "brew search \(query)"
        case .info(let name, _):
            return "brew info \(name)"
        case .install(let name, _):
            return "brew install \(name)"
        case .uninstall(let name, _):
            return "brew uninstall \(name)"
        case .upgrade(let name, _):
            return name != nil ? "brew upgrade \(name!)" : "brew upgrade"
        case .update:
            return "brew update"
        case .outdated:
            return "brew outdated"
        }
    }

    /// 转换为 brew CLI 参数列表
    var arguments: [String] {
        switch self {
        case .listInstalled:
            return ["list", "--installed"]

        case .search(let query, let type):
            var args = ["search", query]
            if let type {
                args += type == .cask ? ["--cask"] : ["--formula"]
            }
            return args

        case .info(let name, let type):
            let prefix = type == .cask ? "--cask" : "--formula"
            return ["info", prefix, "--json=v2", name]

        case .install(let name, let type):
            let prefix = type == .cask ? "--cask" : "--formula"
            return ["install", prefix, name]

        case .uninstall(let name, let type):
            let prefix = type == .cask ? "--cask" : "--formula"
            return ["uninstall", prefix, name]

        case .upgrade(let name, let type):
            var args = ["upgrade"]
            if let type {
                args += type == .cask ? ["--cask"] : ["--formula"]
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
