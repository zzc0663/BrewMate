import SwiftUI
import BrewKit

/// 已安装页面状态管理
@Observable @MainActor
final class InstalledViewModel {
    // MARK: - State
    var packages: [BrewPackage] = []
    var searchText: String = ""
    var selectedType: PackageFilter = .all
    var isLoading: Bool = false
    var errorMessage: String?
    var operation: OperationStatus?

    // MARK: - Filter
    enum PackageFilter: String, CaseIterable {
        case all = "All"
        case formula = "Formula"
        case cask = "Cask"

        var packageType: PackageType? {
            switch self {
            case .all: return nil
            case .formula: return .formula
            case .cask: return .cask
            }
        }
    }

    /// 过滤后的包列表
    var filteredPackages: [BrewPackage] {
        packages.filter { pkg in
            let matchesType: Bool
            switch selectedType {
            case .all: matchesType = true
            case .formula: matchesType = pkg.type == .formula
            case .cask: matchesType = pkg.type == .cask
            }

            let matchesSearch = searchText.isEmpty
                || pkg.name.localizedCaseInsensitiveContains(searchText)
                || pkg.description.localizedCaseInsensitiveContains(searchText)

            return matchesType && matchesSearch
        }
    }

    // MARK: - Actions

    func load(repository: PackageRepository) async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        do {
            packages = try await repository.installed()
        } catch {
            if !(error is CancellationError) {
                errorMessage = error.localizedDescription
            }
        }

        isLoading = false
    }

    func uninstall(_ package: BrewPackage, repository: PackageRepository, appState: AppState) async {
        let label = "Uninstalling \(package.name)"
        operation = OperationStatus(label: label)

        appState.appendLog("$ brew uninstall \(package.name)", false)

        do {
            let stream = repository.uninstall(name: package.name, type: package.type)
            for try await event in stream {
                switch event {
                case .output(let line):
                    operation?.lastOutput = line
                    appState.appendLog(line, false)
                case .error(let line):
                    appState.appendLog(line, true)
                case .completed(let code):
                    if code != 0 {
                        throw BrewError.commandFailed(command: "uninstall", exitCode: code, stderr: "")
                    }
                case .progress:
                    break
                }
            }

            await repository.invalidateCache()
            await appState.loadInstalled()
            await load(repository: repository)
        } catch {
            if !(error is CancellationError) {
                errorMessage = error.localizedDescription
                appState.appendLog("Uninstall failed: \(error.localizedDescription)", true)
            }
        }

        operation = nil
    }
}
