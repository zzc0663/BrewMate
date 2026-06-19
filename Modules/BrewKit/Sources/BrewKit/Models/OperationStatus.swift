import Foundation

/// 正在执行的操作状态
struct OperationStatus: Identifiable, Hashable, Sendable {
    let id: UUID
    /// 操作名称（如 "Installing wget"）
    let label: String
    /// 当前进度（0.0 ~ 1.0，indeterminate 时为 nil）
    var progress: Double?
    /// 最后一行输出
    var lastOutput: String?

    init(id: UUID = UUID(), label: String, progress: Double? = nil, lastOutput: String? = nil) {
        self.id = id
        self.label = label
        self.progress = progress
        self.lastOutput = lastOutput
    }
}
