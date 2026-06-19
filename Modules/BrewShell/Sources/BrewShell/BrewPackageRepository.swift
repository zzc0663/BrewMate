import Foundation
@preconcurrency import BrewKit

/// PackageRepository 协议实现
/// Actor 保证线程安全，内置 30 秒 TTL 缓存
public actor BrewPackageRepository: @preconcurrency PackageRepository {

    private let executor: BrewCommandExecutor

    // MARK: - TTL 缓存

    private let cacheTTL: TimeInterval = 30

    private var installedCache: [BrewPackage]?
    private var installedCacheTime: Date = .distantPast

    private var outdatedCache: [OutdatedPackage]?
    private var outdatedCacheTime: Date = .distantPast

    public init(executor: BrewCommandExecutor) {
        self.executor = executor
    }

    // MARK: - 读操作（带缓存）

    public func installed() async throws -> [BrewPackage] {
        if let cached = installedCache, Date().timeIntervalSince(installedCacheTime) < cacheTTL {
            return cached
        }

        let packages = try await streamInstalled()
        installedCache = packages
        installedCacheTime = Date()
        return packages
    }

    public func outdated() async throws -> [OutdatedPackage] {
        if let cached = outdatedCache, Date().timeIntervalSince(outdatedCacheTime) < cacheTTL {
            return cached
        }

        let packages = try await streamOutdated()
        outdatedCache = packages
        outdatedCacheTime = Date()
        return packages
    }

    public func search(query: String, type: PackageType?) async throws -> [BrewPackage] {
        // search 不缓存（结果依赖查询词）
        let text = try await collectOutput(.search(query: query, type: type))
        return SearchParser.parse(text, type: type)
    }

    public func info(for package: String, type: PackageType) async throws -> BrewPackageDetail {
        // info 不缓存（按需查询单个包）
        let data = try await collectJSON(.info(name: package, type: type))
        return try InfoParser.parse(data, type: type)
    }

    public func invalidateCache() {
        installedCache = nil
        outdatedCache = nil
        installedCacheTime = .distantPast
        outdatedCacheTime = .distantPast
    }

    // MARK: - 写操作（自动清缓存）

    public func install(name: String, type: PackageType) -> AsyncThrowingStream<CommandEvent, Error> {
        wrapWriteStream(.install(name: name, type: type))
    }

    public func uninstall(name: String, type: PackageType) -> AsyncThrowingStream<CommandEvent, Error> {
        wrapWriteStream(.uninstall(name: name, type: type))
    }

    public func upgrade(name: String?, type: PackageType?) -> AsyncThrowingStream<CommandEvent, Error> {
        wrapWriteStream(.upgrade(name: name, type: type))
    }

    // MARK: - 内部实现

    /// 包装写操作流：透传所有事件，在 completed 时自动清缓存
    private func wrapWriteStream(_ command: BrewCommand) -> AsyncThrowingStream<CommandEvent, Error> {
        let upstream = executor.execute(command)

        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    for try await event in upstream {
                        try Task.checkCancellation()
                        if case .completed = event {
                            self.invalidateCache()
                        }
                        continuation.yield(event)
                    }
                    continuation.finish()
                } catch is CancellationError {
                    // 取消时也清缓存（操作可能已部分完成）
                    self.invalidateCache()
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }

            continuation.onTermination = { @Sendable _ in
                task.cancel()
            }
        }
    }

    /// 收集命令输出的 JSON 数据
    private func collectJSON(_ command: BrewCommand) async throws -> Data {
        var output = Data()
        let stream = executor.execute(command)

        for try await event in stream {
            switch event {
            case .output(let line):
                if let data = line.data(using: .utf8) {
                    output.append(data)
                }
            case .error:
                break // stderr 忽略（brew 的进度输出走 stderr）
            case .completed(let code):
                if code != 0 {
                    throw BrewError.commandFailed(
                        command: command.commandLine,
                        exitCode: code,
                        stderr: ""
                    )
                }
            case .progress:
                break
            }
        }

        return output
    }

    /// 收集命令输出的纯文本
    private func collectOutput(_ command: BrewCommand) async throws -> String {
        var lines: [String] = []
        let stream = executor.execute(command)

        for try await event in stream {
            switch event {
            case .output(let line):
                lines.append(line)
            case .error:
                break
            case .completed(let code):
                if code != 0 {
                    throw BrewError.commandFailed(
                        command: command.commandLine,
                        exitCode: code,
                        stderr: ""
                    )
                }
            case .progress:
                break
            }
        }

        return lines.joined(separator: "\n")
    }

    /// 刷新 installed 缓存
    private func streamInstalled() async throws -> [BrewPackage] {
        let data = try await collectJSON(.listInstalled)
        return try InstalledParser.parse(data)
    }

    /// 刷新 outdated 缓存
    private func streamOutdated() async throws -> [OutdatedPackage] {
        let data = try await collectJSON(.outdated)
        return try OutdatedParser.parse(data)
    }
}
