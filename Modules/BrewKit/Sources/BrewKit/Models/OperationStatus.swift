import Foundation

/// 正在执行的操作状态
public struct OperationStatus: Identifiable, Hashable, Sendable {
    public let id: UUID
    /// 操作名称（如 "Installing wget"）
    public let label: String
    /// 当前进度（0.0 ~ 1.0，indeterminate 时为 nil）
    public var progress: Double?
    /// 最后一行输出
    public var lastOutput: String?

    public init(id: UUID = UUID(), label: String, progress: Double? = nil, lastOutput: String? = nil) {
        self.id = id
        self.label = label
        self.progress = progress
        self.lastOutput = lastOutput
    }
}
