import Foundation

/// 结构化错误 —— 每个 case 提供可直接展示的 errorDescription
enum BrewError: LocalizedError {
    /// brew 命令执行失败
    case commandFailed(command: String, exitCode: Int32, stderr: String)
    /// 包未找到
    case notFound(package: String)
    /// 包已安装
    case alreadyInstalled(package: String)
    /// brew 未安装
    case brewNotFound
    /// JSON 解析失败
    case parsingFailed(detail: String)
    /// 网络错误
    case networkError(underlying: String)
    /// 操作被取消
    case cancelled

    var errorDescription: String? {
        switch self {
        case .commandFailed(let command, let exitCode, let stderr):
            return "命令失败: \(command) (exit \(exitCode))\n\(stderr)"
        case .notFound(let package):
            return "未找到包: \(package)"
        case .alreadyInstalled(let package):
            return "包已安装: \(package)"
        case .brewNotFound:
            return "未安装 Homebrew。请先安装: https://brew.sh"
        case .parsingFailed(let detail):
            return "解析数据失败: \(detail)"
        case .networkError(let underlying):
            return "网络错误: \(underlying)"
        case .cancelled:
            return "操作已取消"
        }
    }
}
