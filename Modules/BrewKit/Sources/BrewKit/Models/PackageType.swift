import Foundation

/// Homebrew 包类型
public enum PackageType: String, Codable, Sendable, CaseIterable {
    /// 命令行工具 (brew install)
    case formula
    /// GUI 应用 (brew install --cask)
    case cask

    /// 显示名称
    public var displayName: String {
        switch self {
        case .formula: return "Formula"
        case .cask: return "Cask"
        }
    }

    /// brew info JSON 中对应的顶层 key
    public var jsonKey: String {
        switch self {
        case .formula: return "formulae"
        case .cask: return "casks"
        }
    }

    /// brew CLI 类型标志（--formula / --cask）
    public var cliFlag: String {
        switch self {
        case .formula: return "--formula"
        case .cask: return "--cask"
        }
    }
}
