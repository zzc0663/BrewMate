import Foundation
import BrewKit

/// 封装 Foundation Process 为 AsyncThrowingStream
/// 每次调用 execute() 创建新的子进程，逐行输出 stdout/stderr
final class ProcessRunner: @unchecked Sendable {

    private let brewPath: String

    init(brewPath: String) {
        self.brewPath = brewPath
    }

    /// 执行 brew 命令，返回实时事件流
    func execute(_ command: BrewCommand) -> AsyncThrowingStream<CommandEvent, Error> {
        execute(executable: brewPath, arguments: command.arguments)
    }

    /// 执行任意可执行文件，返回实时事件流
    /// - Parameters:
    ///   - executable: 可执行文件路径
    ///   - arguments: 命令行参数
    func execute(executable: String, arguments: [String]) -> AsyncThrowingStream<CommandEvent, Error> {
        let pipeQueue = DispatchQueue(label: "com.brewmate.processrunner.pipe")

        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        return AsyncThrowingStream { continuation in
            continuation.onTermination = { @Sendable _ in
                if process.isRunning {
                    process.terminate()
                }
            }

            // 线程安全地累积 stderr 内容，用于错误报告
            let stderrAccumulator = LineAccumulator()

            // 未处理的尾部数据（跨 read 的不完整行）
            var stdoutRemainder = Data()
            var stderrRemainder = Data()

            /// 处理 pipe 数据：累积尾部数据，按行拆分并 yield
            func handleStreamData(
                _ data: Data,
                remainder: inout Data,
                eventBuilder: (String) -> CommandEvent,
                accumulateTo: LineAccumulator? = nil
            ) {
                // 追加到上次的尾部数据
                var combined = remainder
                combined.append(data)

                // 使用 UTF-8 安全解码（无效字节替换为 U+FFFD）
                let str = String(decoding: combined, as: Unicode.UTF8.self)
                let lines = str.split(separator: "\n", omittingEmptySubsequences: false)

                guard !lines.isEmpty else { return }

                // 最后一个元素可能是不完整的行（没有 \n 结尾），保留为尾部
                let lastLine = String(lines.last!)
                let completeLines = lines.dropLast()

                for line in completeLines {
                    let lineStr = String(line)
                    accumulateTo?.append(lineStr)
                    continuation.yield(eventBuilder(lineStr))
                }

                // 保留未完成的尾部字节（下次 read 时追加）
                remainder = Data(lastLine.utf8)
            }

            stdoutPipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                if data.isEmpty {
                    // EOF: 输出剩余的尾部数据
                    if !stdoutRemainder.isEmpty {
                        let str = String(decoding: stdoutRemainder, as: Unicode.UTF8.self)
                        if !str.isEmpty {
                            continuation.yield(.output(line: str))
                        }
                        stdoutRemainder = Data()
                    }
                    stdoutPipe.fileHandleForReading.readabilityHandler = nil
                    return
                }
                handleStreamData(
                    data,
                    remainder: &stdoutRemainder,
                    eventBuilder: { .output(line: $0) }
                )
            }

            stderrPipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                if data.isEmpty {
                    // EOF: 输出剩余的尾部数据
                    if !stderrRemainder.isEmpty {
                        let str = String(decoding: stderrRemainder, as: Unicode.UTF8.self)
                        if !str.isEmpty {
                            stderrAccumulator.append(str)
                            continuation.yield(.error(line: str))
                        }
                        stderrRemainder = Data()
                    }
                    stderrPipe.fileHandleForReading.readabilityHandler = nil
                    return
                }
                handleStreamData(
                    data,
                    remainder: &stderrRemainder,
                    eventBuilder: { .error(line: $0) },
                    accumulateTo: stderrAccumulator
                )
            }

            process.terminationHandler = { proc in
                // 短暂延迟确保 pipe readabilityHandler 的 EOF 回调已完成
                pipeQueue.asyncAfter(deadline: .now() + .milliseconds(10)) {
                    let exitCode = proc.terminationStatus

                    stdoutPipe.fileHandleForReading.readabilityHandler = nil
                    stderrPipe.fileHandleForReading.readabilityHandler = nil

                    if exitCode == 0 {
                        continuation.yield(.completed(exitCode: exitCode))
                        continuation.finish()
                    } else {
                        continuation.finish(throwing: BrewError.commandFailed(
                            command: "\(executable) \(arguments.joined(separator: " "))",
                            exitCode: exitCode,
                            stderr: stderrAccumulator.joined()
                        ))
                    }
                }
            }

            do {
                try process.run()
            } catch {
                continuation.finish(throwing: error)
            }
        }
    }
}

// MARK: - Thread-safe Line Accumulator

/// 线程安全的行累积器，用于收集 stderr 输出
private final class LineAccumulator: @unchecked Sendable {
    private let lock = NSLock()
    private var lines: [String] = []

    func append(_ line: String) {
        lock.lock()
        lines.append(line)
        lock.unlock()
    }

    func joined() -> String {
        lock.lock()
        defer { lock.unlock() }
        return lines.joined(separator: "\n")
    }
}
