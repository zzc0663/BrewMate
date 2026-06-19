import SwiftUI

/// 应用主题选项
enum AppTheme: String, CaseIterable, Sendable {
    case system = "system"
    case light = "light"
    case dark = "dark"

    var displayName: String {
        switch self {
        case .system: return "跟随系统"
        case .light: return "浅色"
        case .dark: return "深色"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

/// 主题管理器 — 使用 @AppStorage 持久化
@MainActor
final class ThemeManager: ObservableObject {
    @Published var currentTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: "appTheme")
        }
    }

    init() {
        let saved = UserDefaults.standard.string(forKey: "appTheme") ?? ""
        self.currentTheme = AppTheme(rawValue: saved) ?? .system
    }
}
