import Foundation

/// brew 命令执行器协议（基础设施层实现）
public protocol BrewExecutor: Sendable {
    /// 执行 brew 命令，返回实时事件流
    func execute(_ command: BrewCommand) -> AsyncThrowingStream<CommandEvent, Error>
}
