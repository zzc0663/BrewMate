import SwiftUI

/// 设置页面 — 主题切换
struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        Form {
            Section("外观") {
                Picker("主题", selection: $themeManager.currentTheme) {
                    ForEach(AppTheme.allCases, id: \.self) { theme in
                        Text(theme.displayName).tag(theme)
                    }
                }
                .pickerStyle(.segmented)
            }

            if let trustStatus = appState.trustStatus, trustStatus.hasWarning {
                Section("Homebrew 环境") {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                            .padding(.top, 2)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("有第三方 Homebrew 仓库需要处理")
                                .font(.headline)

                            Text("检测到一个第三方 Homebrew 仓库还没有被信任，安装或卸载某些包时可能失败。")
                                .font(.callout)
                                .foregroundStyle(.secondary)

                            ForEach(trustStatus.untrustedTaps, id: \.self) { tap in
                                HStack {
                                    Text(tap)
                                        .font(.system(.caption, design: .monospaced))
                                        .textSelection(.enabled)

                                    Spacer()

                                    Button {
                                        Task { await appState.trustTap(tap) }
                                    } label: {
                                        if appState.isTrustOperationInProgress {
                                            ProgressView()
                                                .controlSize(.small)
                                        } else {
                                            Text("信任")
                                        }
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .controlSize(.small)
                                    .disabled(appState.isTrustOperationInProgress)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
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
