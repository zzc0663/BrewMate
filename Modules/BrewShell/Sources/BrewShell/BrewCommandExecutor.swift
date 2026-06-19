import Foundation
@preconcurrency import BrewKit

/// BrewExecutor 协议实现
/// 委托 ProcessRunner 执行 brew CLI 命令
public final class BrewCommandExecutor: BrewExecutor, @unchecked Sendable {

    private let runner: ProcessRunner

    public init(runner: ProcessRunner) {
        self.runner = runner
    }

    /// 便捷初始化：自动检测 brew 路径
    public convenience init() async throws {
        let brewPath = try await BrewPathResolver.resolve()
        self.init(runner: ProcessRunner(brewPath: brewPath))
    }

    public func execute(_ command: BrewCommand) -> AsyncThrowingStream<CommandEvent, Error> {
        runner.execute(command)
    }
}
