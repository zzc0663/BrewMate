import Foundation
@preconcurrency import BrewKit

/// BrewExecutor 协议实现
/// 委托 ProcessRunner 执行 brew CLI 命令
final class BrewCommandExecutor: BrewExecutor, @unchecked Sendable {

    private let runner: ProcessRunner

    init(runner: ProcessRunner) {
        self.runner = runner
    }

    /// 便捷初始化：自动检测 brew 路径
    convenience init() async throws {
        let brewPath = try await BrewPathResolver.resolve()
        self.init(runner: ProcessRunner(brewPath: brewPath))
    }

    func execute(_ command: BrewCommand) -> AsyncThrowingStream<CommandEvent, Error> {
        runner.execute(command)
    }
}
