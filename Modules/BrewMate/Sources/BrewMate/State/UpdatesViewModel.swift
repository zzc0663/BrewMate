import SwiftUI
import BrewKit

/// 更新页面状态管理
@Observable @MainActor
final class UpdatesViewModel {
    // MARK: - State
    var isLoading: Bool = false
    var errorMessage: String?
    var upgradingAll: Bool = false
    var operation: OperationStatus?

    // MARK: - Actions

    /// 升级单个包
    func upgrade(_ package: OutdatedPackage, repository: PackageRepository, appState: AppState) async {
        let label = "Upgrading \(package.name)"
        operation = OperationStatus(label: label)

        appState.appendLog("$ brew upgrade \(package.name)", false)

        do {
            let stream = repository.upgrade(name: package.name, type: package.type)
            for try await event in stream {
                switch event {
                case .output(let line):
                    operation?.lastOutput = line
                    appState.appendLog(line, false)
                case .error(let line):
                    appState.appendLog(line, true)
                case .completed(let code):
                    if code != 0 {
                        throw BrewError.commandFailed(command: "upgrade", exitCode: code, stderr: "")
                    }
                case .progress(let pct):
                    operation?.progress = pct
                }
            }

            await repository.invalidateCache()
            await appState.loadOutdated()
            await appState.loadInstalled()
            appState.appendLog("✅ \(package.name) 升级完成", false)
        } catch {
            if !(error is CancellationError) {
                errorMessage = error.localizedDescription
                appState.appendLog("Upgrade failed: \(error.localizedDescription)", true)
            }
        }

        operation = nil
    }

    /// 升级全部
    func upgradeAll(repository: PackageRepository, appState: AppState) async {
        guard !upgradingAll else { return }
        upgradingAll = true
        errorMessage = nil

        appState.appendLog("$ brew upgrade", false)
        operation = OperationStatus(label: "Upgrading all packages")

        do {
            let stream = repository.upgrade(name: nil, type: nil)
            for try await event in stream {
                switch event {
                case .output(let line):
                    operation?.lastOutput = line
                    appState.appendLog(line, false)
                case .error(let line):
                    appState.appendLog(line, true)
                case .completed(let code):
                    if code != 0 {
                        throw BrewError.commandFailed(command: "upgrade", exitCode: code, stderr: "")
                    }
                case .progress(let pct):
                    operation?.progress = pct
                }
            }

            await repository.invalidateCache()
            await appState.loadOutdated()
            await appState.loadInstalled()
            appState.appendLog("✅ 全部升级完成", false)
        } catch {
            if !(error is CancellationError) {
                errorMessage = error.localizedDescription
                appState.appendLog("Upgrade failed: \(error.localizedDescription)", true)
            }
        }

        operation = nil
        upgradingAll = false
    }
}
