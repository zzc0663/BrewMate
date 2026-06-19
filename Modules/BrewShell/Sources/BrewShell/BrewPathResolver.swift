import Foundation
import BrewKit

/// 自动检测 Homebrew 安装路径
enum BrewPathResolver: Sendable {

    /// 已知的 brew 默认安装路径（按优先级排序）
    private static let knownPaths = [
        "/opt/homebrew/bin/brew",   // Apple Silicon (默认)
        "/usr/local/bin/brew",      // Intel
    ]

    /// 解析 brew 可执行文件路径
    /// 优先检查已知路径，再 fallback 到 `which brew`
    static func resolve() async throws -> String {
        // 1. 检查已知路径
        for path in knownPaths {
            if FileManager.default.isExecutableFile(atPath: path) {
                return path
            }
        }

        // 2. fallback: which brew
        return try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
            process.arguments = ["brew"]

            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = FileHandle.nullDevice

            process.terminationHandler = { proc in
                if proc.terminationStatus == 0 {
                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    let path = String(data: data, encoding: .utf8)?
                        .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    if !path.isEmpty {
                        continuation.resume(returning: path)
                    } else {
                        continuation.resume(throwing: BrewError.brewNotFound)
                    }
                } else {
                    continuation.resume(throwing: BrewError.brewNotFound)
                }
            }

            do {
                try process.run()
            } catch {
                continuation.resume(throwing: BrewError.brewNotFound)
            }
        }
    }
}
