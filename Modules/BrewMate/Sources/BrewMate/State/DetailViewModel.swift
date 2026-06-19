import SwiftUI
import BrewKit

/// 包操作类型（避免 raw string 拼写错误）
enum PackageOperation: String {
    case install, uninstall, upgrade
}

/// 包详情页面状态管理
@MainActor
final class DetailViewModel: ObservableObject {
    // MARK: - State
    @Published var detail: BrewPackageDetail?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var operation: OperationStatus?

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
        errorMessage = nil

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

            let refreshedPackage = appState.installed.first {
                $0.name == package.name && $0.type == package.type
            }

            switch op {
            case .install:
                guard let refreshedPackage, refreshedPackage.isInstalled else {
                    throw BrewError.commandFailed(
                        command: op.rawValue,
                        exitCode: 1,
                        stderr: "brew 命令结束后未在已安装列表中找到 \(package.name)"
                    )
                }
                await loadDetail(for: refreshedPackage, repository: repository)

            case .uninstall:
                if let refreshedPackage, refreshedPackage.isInstalled {
                    throw BrewError.commandFailed(
                        command: op.rawValue,
                        exitCode: 1,
                        stderr: "brew 命令结束后 \(package.name) 仍然存在于已安装列表"
                    )
                }
                detail = nil

            case .upgrade:
                await loadDetail(for: refreshedPackage ?? package, repository: repository)
            }
        } catch {
            if !(error is CancellationError) {
                errorMessage = error.localizedDescription
                appState.appendLog("\(op.rawValue) failed: \(error.localizedDescription)", true)
            }
        }

        operation = nil
    }
}
