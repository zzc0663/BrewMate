import SwiftUI

/// 设置页面 — 主题切换
struct SettingsView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var themeManager = appState.themeManager

        Form {
            Section("外观") {
                Picker("主题", selection: $themeManager.currentTheme) {
                    ForEach(AppTheme.allCases, id: \.self) { theme in
                        Text(theme.displayName).tag(theme)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("关于") {
                HStack {
                    Text("BrewMate")
                        .font(.headline)
                    Spacer()
                    Text("v1.0.0")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Homebrew")
                        .font(.headline)
                    Spacer()
                    Text("macOS 包管理器 GUI")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("设置")
    }
}
