import Foundation

/// 命令日志条目
struct LogEntry: Identifiable, Hashable, Sendable {
    let id: UUID
    /// 时间戳
    let timestamp: Date
    /// 关联的命令描述
    let command: String
    /// 输出内容
    let content: String
    /// 是否为错误输出
    let isError: Bool

    init(id: UUID = UUID(), timestamp: Date = Date(), command: String, content: String, isError: Bool = false) {
        self.id = id
        self.timestamp = timestamp
        self.command = command
        self.content = content
        self.isError = isError
    }
}
