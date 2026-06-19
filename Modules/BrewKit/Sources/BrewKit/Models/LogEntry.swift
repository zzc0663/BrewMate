import Foundation

/// 命令日志条目
public struct LogEntry: Identifiable, Hashable, Sendable {
    public let id: UUID
    /// 时间戳
    public let timestamp: Date
    /// 关联的命令描述
    public let command: String
    /// 输出内容
    public let content: String
    /// 是否为错误输出
    public let isError: Bool

    public init(id: UUID = UUID(), timestamp: Date = Date(), command: String, content: String, isError: Bool = false) {
        self.id = id
        self.timestamp = timestamp
        self.command = command
        self.content = content
        self.isError = isError
    }
}
