import Foundation

/// Homebrew 包类型
enum PackageType: String, Codable, Sendable, CaseIterable {
    /// 命令行工具 (brew install)
    case formula
    /// GUI 应用 (brew install --cask)
    case cask

    /// 显示名称
    var displayName: String {
        switch self {
        case .formula: return "Formula"
        case .cask: return "Cask"
        }
    }

    /// brew info JSON 中对应的顶层 key
    var jsonKey: String {
        switch self {
        case .formula: return "formulae"
        case .cask: return "casks"
        }
    }
}
