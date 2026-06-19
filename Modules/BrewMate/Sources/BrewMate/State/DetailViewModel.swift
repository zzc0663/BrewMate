import SwiftUI
import BrewKit

/// 包操作类型（避免 raw string 拼写错误）
enum PackageOperation: String {
    case install, uninstall, upgrade
}

/// 包详情页面状态管理
@Observable @MainActor
final class DetailViewModel {
    // MARK: - State
    var detail: BrewPackageDetail?
    var isLoading: Bool = false
    var errorMessage: String?
    var operation: OperationStatus?

    // MARK: - Actions

    /// 加载包详情
    func loadDetail(for package: BrewPackage, repository: PackageRepository) async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        do {
            detail = try await repository.info(for: package.name, type: package.type)
        } catch {
            if !(error is CancellationError) {
                errorMessage = error.localizedDescription
            }
        }

        isLoading = false
    }

    /// 执行操作（install / uninstall / upgrade）
    func performOperation(
        _ op: PackageOperation,
        package: BrewPackage,
        repository: PackageRepository,
        appState: AppState
    ) async {
        let label: String
        let stream: AsyncThrowingStream<CommandEvent, Error>

        switch op {
        case .install:
            label = "Installing \(package.name)"
            stream = repository.install(name: package.name, type: package.type)
        case .uninstall:
            label = "Uninstalling \(package.name)"
            stream = repository.uninstall(name: package.name, type: package.type)
        case .upgrade:
            label = "Upgrading \(package.name)"
            stream = repository.upgrade(name: package.name, type: package.type)
        }

        operation = OperationStatus(label: label)
        appState.appendLog("$ brew \(op.rawValue) \(package.name)", false)

        do {
            for try await event in stream {
                switch event {
                case .output(let line):
                    operation?.lastOutput = line
                    appState.appendLog(line, false)
                case .error(let line):
                    appState.appendLog(line, true)
                case .completed(let code):
                    if code != 0 {
                        throw BrewError.commandFailed(command: op.rawValue, exitCode: code, stderr: "")
                    }
                case .progress(let pct):
                    operation?.progress = pct
                }
            }

            await repository.invalidateCache()
            await appState.loadInstalled()
            await appState.loadOutdated()
            await loadDetail(for: package, repository: repository)
        } catch {
            if !(error is CancellationError) {
                errorMessage = error.localizedDescription
                appState.appendLog("\(op.rawValue) failed: \(error.localizedDescription)", true)
            }
        }

        operation = nil
    }
}
