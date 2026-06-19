import SwiftUI
import BrewKit

/// 探索页面状态管理 — 搜索 + 安装
@Observable @MainActor
final class ExploreViewModel {
    // MARK: - State
    var searchText: String = ""
    var results: [BrewPackage] = []
    var isLoading: Bool = false
    var errorMessage: String?
    var operation: OperationStatus?

    /// debounce Task
    private var searchTask: Task<Void, Never>?
    /// 搜索代次（防止旧搜索覆盖新结果）
    private var searchGeneration: UInt64 = 0

    // MARK: - Computed

    var formulae: [BrewPackage] {
        results.filter { $0.type == .formula }
    }

    var casks: [BrewPackage] {
        results.filter { $0.type == .cask }
    }

    // MARK: - Actions

    /// 搜索（带 debounce 300ms）
    func searchTextChanged(repository: PackageRepository) {
        searchTask?.cancel()
        searchGeneration += 1
        let generation = searchGeneration
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !query.isEmpty else {
            results = []
            return
        }

        searchTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled, let self else { return }
            await self.performSearch(query: query, repository: repository, generation: generation)
        }
    }

    private func performSearch(query: String, repository: PackageRepository, generation: UInt64) async {
        isLoading = true
        errorMessage = nil

        do {
            let results = try await repository.search(query: query, type: nil)
            guard searchGeneration == generation else { return } // 过时的搜索
            self.results = results
        } catch {
            guard searchGeneration == generation else { return }
            if !(error is CancellationError) {
                errorMessage = error.localizedDescription
            }
        }

        isLoading = false
    }

    /// 安装包
    func install(_ package: BrewPackage, repository: PackageRepository, appState: AppState) async {
        let label = "Installing \(package.name)"
        operation = OperationStatus(label: label)

        appState.appendLog("$ brew install \(package.name)", false)

        do {
            let stream = repository.install(name: package.name, type: package.type)
            for try await event in stream {
                switch event {
                case .output(let line):
                    operation?.lastOutput = line
                    appState.appendLog(line, false)
                case .error(let line):
                    appState.appendLog(line, true)
                case .completed(let code):
                    if code != 0 {
                        throw BrewError.commandFailed(command: "install", exitCode: code, stderr: "")
                    }
                case .progress(let pct):
                    operation?.progress = pct
                }
            }

            await repository.invalidateCache()
            await appState.loadInstalled()
            appState.appendLog("✅ \(package.name) 安装完成", false)
        } catch {
            if !(error is CancellationError) {
                errorMessage = error.localizedDescription
                appState.appendLog("Install failed: \(error.localizedDescription)", true)
            }
        }

        operation = nil
    }
}
