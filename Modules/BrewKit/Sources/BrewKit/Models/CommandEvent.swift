import Foundation

/// brew 命令执行过程中的实时事件
enum CommandEvent: Equatable, Sendable {
    /// 输出一行标准输出
    case output(line: String)
    /// 输出一行标准错误
    case error(line: String)
    /// 命令执行完成（附带退出码）
    case completed(exitCode: Int32)
    /// 进度更新（0.0 ~ 1.0，部分命令不提供）
    case progress(percentage: Double)
}
