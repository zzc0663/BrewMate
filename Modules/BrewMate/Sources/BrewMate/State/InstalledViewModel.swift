import SwiftUI
import BrewKit

/// 已安装页面状态管理
@MainActor
final class InstalledViewModel: ObservableObject {
    // MARK: - State
    @Published var packages: [BrewPackage] = []
    @Published var searchText: String = ""
    @Published var selectedType: PackageFilter = .all
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var operation: OperationStatus?
    @Published var selectedIDs: Set<String> = []
    @Published var focusedPackageID: String?
    @Published var listSelectionID: String?
    @Published var batchOperation: OperationStatus?
    @Published var batchErrorSummary: String?
    @Published var pendingBulkUninstallConfirmation: [BrewPackage] = []

    // MARK: - Filter
    enum PackageFilter: String, CaseIterable {
        case all = "All"
        case formula = "Formula"
        case cask = "Cask"
    }

    /// 过滤后的包列表
    var filteredPackages: [BrewPackage] {
        packages.filter { pkg in
            let matchesType: Bool
            switch selectedType {
            case .all:
                matchesType = true
            case .formula:
                matchesType = pkg.type == .formula
            case .cask:
                matchesType = pkg.type == .cask
            }

            let matchesSearch = searchText.isEmpty
                || pkg.name.localizedCaseInsensitiveContains(searchText)
                || pkg.description.localizedCaseInsensitiveContains(searchText)

            return matchesType && matchesSearch
        }
    }

    var focusedPackage: BrewPackage? {
        guard let focusedPackageID else { return nil }
        return packages.first { $0.id == focusedPackageID }
    }

    var selectedPackages: [BrewPackage] {
        packages.filter { selectedIDs.contains($0.id) }
    }

    var selectedPackagesForDisplay: [BrewPackage] {
        filteredPackages.filter { selectedIDs.contains($0.id) }
    }

    var allFilteredSelected: Bool {
        let ids = Set(filteredPackages.map(\.id))
        return !ids.isEmpty && ids.isSubset(of: selectedIDs)
    }

    func selectedPackageCountLabel(_ count: Int) -> String {
        count > 0 ? "(\(count))" : ""
    }

    func updatableSelectionCount(outdated: [OutdatedPackage]) -> Int {
        selectablePackagesForUpgrade(outdated: outdated).count
    }

    // MARK: - Actions

    func load(repository: PackageRepository) async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        do {
            packages = try await repository.installed()
            reconcileSelection(with: packages)
        } catch {
            if !(error is CancellationError) {
                errorMessage = error.localizedDescription
            }
        }

        isLoading = false
    }

    func syncPackages(_ installed: [BrewPackage]) {
        packages = installed
        reconcileSelection(with: installed)
    }

    func focus(_ package: BrewPackage, appState: AppState) {
        focusedPackageID = package.id
        listSelectionID = package.id
        appState.selectedPackage = package
    }

    func focus(packageID: String?, appState: AppState) {
        listSelectionID = packageID

        guard let packageID,
              let package = packages.first(where: { $0.id == packageID }) else {
            focusedPackageID = nil
            appState.selectedPackage = nil
            return
        }

        focusedPackageID = packageID
        appState.selectedPackage = package
    }

    func updateFocusedPackage(using installed: [BrewPackage], appState: AppState) {
        if let focusedPackageID,
           let refreshed = installed.first(where: { $0.id == focusedPackageID }) {
            listSelectionID = focusedPackageID
            appState.selectedPackage = refreshed
            return
        }

        if let fallback = installed.first(where: { selectedIDs.contains($0.id) }) ?? installed.first {
            focusedPackageID = fallback.id
            listSelectionID = fallback.id
            appState.selectedPackage = fallback
        } else {
            focusedPackageID = nil
            listSelectionID = nil
            appState.selectedPackage = nil
        }
    }

    func reconcileSelection(with installed: [BrewPackage]) {
        let validIDs = Set(installed.map(\.id))
        selectedIDs = selectedIDs.intersection(validIDs)

        if let focusedPackageID, !validIDs.contains(focusedPackageID) {
            self.focusedPackageID = installed.first(where: { selectedIDs.contains($0.id) })?.id
                ?? installed.first?.id
        } else if self.focusedPackageID == nil {
            self.focusedPackageID = installed.first(where: { selectedIDs.contains($0.id) })?.id
        }

        if let listSelectionID, !validIDs.contains(listSelectionID) {
            self.listSelectionID = self.focusedPackageID
        } else if self.listSelectionID == nil {
            self.listSelectionID = self.focusedPackageID
        }
    }

    func syncSelectionToAppState(appState: AppState) {
        if let focusedPackage = focusedPackage {
            appState.selectedPackage = focusedPackage
        } else {
            appState.selectedPackage = nil
        }
    }

    func requestBulkUninstallConfirmation() {
        pendingBulkUninstallConfirmation = selectedPackages
        batchErrorSummary = nil
    }

    func cancelBulkUninstallConfirmation() {
        pendingBulkUninstallConfirmation = []
    }

    func toggleBatchSelection(for package: BrewPackage) {
        if selectedIDs.contains(package.id) {
            selectedIDs.remove(package.id)
        } else {
            selectedIDs.insert(package.id)
        }
    }

    func selectAllFiltered() {
        selectedIDs.formUnion(filteredPackages.map(\.id))
    }

    func clearSelection() {
        selectedIDs.removeAll()
    }

    func uninstall(_ package: BrewPackage, repository: PackageRepository, appState: AppState) async {
        let label = "Uninstalling \(package.name)"
        operation = OperationStatus(label: label)
        errorMessage = nil

        appState.appendLog("$ brew uninstall \(package.name)", false)

        do {
            try await stream(
                repository.uninstall(name: package.name, type: package.type),
                into: \.operation,
                command: "uninstall",
                appState: appState
            )

            try await refreshAfterMutation(repository: repository, appState: appState)
            updateFocusedPackage(using: packages, appState: appState)
        } catch {
            if !(error is CancellationError) {
                errorMessage = error.localizedDescription
                appState.appendLog("Uninstall failed: \(error.localizedDescription)", true)
            }
        }

        operation = nil
    }

    func upgradeSelected(repository: PackageRepository, appState: AppState) async {
        let targets = selectablePackagesForUpgrade(outdated: appState.outdated)
        guard !targets.isEmpty else { return }

        batchOperation = OperationStatus(label: "批量更新 \(targets.count) 个包")
        batchErrorSummary = nil

        let outdatedIDs = Set(appState.outdated.filter { !$0.isPinned }.map { "\($0.type.rawValue)/\($0.name)" })
        let ignored = selectedPackages.filter { !outdatedIDs.contains($0.id) }

        if !ignored.isEmpty {
            let names = ignored.map(\.name).joined(separator: "、")
            appState.appendLog("已跳过不可更新或已固定的包: \(names)", false)
        }

        var failedNames: [String] = []

        for (index, package) in targets.enumerated() {
            batchOperation?.lastOutput = package.name
            batchOperation?.progress = Double(index) / Double(max(targets.count, 1))
            appState.appendLog("$ brew upgrade \(package.name)", false)

            do {
                try await stream(
                    repository.upgrade(name: package.name, type: package.type),
                    into: \.batchOperation,
                    command: "upgrade",
                    appState: appState
                )
                try await refreshAfterMutation(repository: repository, appState: appState)
                updateFocusedPackage(using: packages, appState: appState)
                appState.appendLog("✅ \(package.name) 升级完成", false)
            } catch {
                if error is CancellationError {
                    batchOperation = nil
                    return
                }
                failedNames.append(package.name)
                appState.appendLog("Upgrade failed: \(package.name): \(error.localizedDescription)", true)
            }
        }

        batchOperation?.progress = 1
        finalizeBatchResult(
            successMessage: "批量更新完成，共处理 \(targets.count) 个包",
            failurePrefix: "以下包更新失败",
            failedNames: failedNames,
            appState: appState
        )
        batchOperation = nil
    }

    func uninstallSelected(repository: PackageRepository, appState: AppState) async {
        let targets = pendingBulkUninstallConfirmation.isEmpty ? selectedPackages : pendingBulkUninstallConfirmation
        guard !targets.isEmpty else { return }

        pendingBulkUninstallConfirmation = []
        batchOperation = OperationStatus(label: "批量卸载 \(targets.count) 个包")
        batchErrorSummary = nil

        var failedNames: [String] = []

        for (index, package) in targets.enumerated() {
            batchOperation?.lastOutput = package.name
            batchOperation?.progress = Double(index) / Double(max(targets.count, 1))
            appState.appendLog("$ brew uninstall \(package.name)", false)

            do {
                try await stream(
                    repository.uninstall(name: package.name, type: package.type),
                    into: \.batchOperation,
                    command: "uninstall",
                    appState: appState
                )
                selectedIDs.remove(package.id)
                try await refreshAfterMutation(repository: repository, appState: appState)
                updateFocusedPackage(using: packages, appState: appState)
                appState.appendLog("✅ \(package.name) 卸载完成", false)
            } catch {
                if error is CancellationError {
                    batchOperation = nil
                    return
                }
                failedNames.append(package.name)
                appState.appendLog("Uninstall failed: \(package.name): \(error.localizedDescription)", true)
            }
        }

        batchOperation?.progress = 1
        finalizeBatchResult(
            successMessage: "批量卸载完成，共处理 \(targets.count) 个包",
            failurePrefix: "以下包卸载失败",
            failedNames: failedNames,
            appState: appState
        )
        batchOperation = nil
    }

    // MARK: - Helpers

    private func selectablePackagesForUpgrade(outdated: [OutdatedPackage]) -> [BrewPackage] {
        let updatableIDs = Set(
            outdated
                .filter { !$0.isPinned }
                .map { "\($0.type.rawValue)/\($0.name)" }
        )
        return selectedPackages.filter { updatableIDs.contains($0.id) }
    }

    private func refreshAfterMutation(repository: PackageRepository, appState: AppState) async throws {
        await repository.invalidateCache()
        await appState.loadInstalled()
        await appState.loadOutdated()
        syncPackages(appState.installed)
    }

    private func finalizeBatchResult(
        successMessage: String,
        failurePrefix: String,
        failedNames: [String],
        appState: AppState
    ) {
        if failedNames.isEmpty {
            batchErrorSummary = nil
            appState.appendLog("✅ \(successMessage)", false)
            return
        }

        let summary = "\(failurePrefix): \(failedNames.joined(separator: "、"))"
        batchErrorSummary = summary
        errorMessage = summary
        appState.appendLog(summary, true)
    }

    private func stream(
        _ stream: AsyncThrowingStream<CommandEvent, Error>,
        into keyPath: ReferenceWritableKeyPath<InstalledViewModel, OperationStatus?>,
        command: String,
        appState: AppState
    ) async throws {
        for try await event in stream {
            switch event {
            case .output(let line):
                self[keyPath: keyPath]?.lastOutput = line
                appState.appendLog(line, false)
            case .error(let line):
                appState.appendLog(line, true)
            case .completed(let code):
                if code != 0 {
                    throw BrewError.commandFailed(command: command, exitCode: code, stderr: "")
                }
            case .progress(let pct):
                self[keyPath: keyPath]?.progress = pct
            }
        }
    }
}
