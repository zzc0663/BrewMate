import Foundation
import BrewKit

public struct BrewTrustStatus: Sendable, Equatable {
    public let tapTrustRequired: Bool
    public let untrustedTaps: [String]

    public var hasWarning: Bool {
        tapTrustRequired && !untrustedTaps.isEmpty
    }

    public init(tapTrustRequired: Bool, untrustedTaps: [String]) {
        self.tapTrustRequired = tapTrustRequired
        self.untrustedTaps = untrustedTaps
    }
}

public enum BrewEnvironmentInspector: Sendable {
    public static func inspect(brewPath: String) async throws -> BrewTrustStatus {
        async let trustRequired = checkTapTrustRequired(brewPath: brewPath)
        async let taps = loadTappedRepos(brewPath: brewPath)
        async let trustedTaps = loadTrustedTaps(brewPath: brewPath)

        let status = try await trustRequired
        let tappedRepos = try await taps
        let trusted = try await trustedTaps

        let untrusted = status ? tappedRepos.filter {
            !$0.hasPrefix("homebrew/") && !trusted.contains($0)
        } : []
        return BrewTrustStatus(tapTrustRequired: status, untrustedTaps: untrusted)
    }

    private static func checkTapTrustRequired(brewPath: String) async throws -> Bool {
        let output = try await run(
            executable: brewPath,
            arguments: ["config"]
        )

        return output
            .split(separator: "\n")
            .contains { $0.contains("HOMEBREW_REQUIRE_TAP_TRUST: set") }
    }

    private static func loadTappedRepos(brewPath: String) async throws -> [String] {
        let output = try await run(
            executable: brewPath,
            arguments: ["tap"]
        )

        return output
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private static func loadTrustedTaps(brewPath: String) async throws -> Set<String> {
        let output = try await run(
            executable: brewPath,
            arguments: ["trust", "--json=v1"]
        )

        let data = Data(output.utf8)
        let payload = try JSONDecoder().decode(TrustJSON.self, from: data)
        return Set(payload.taps)
    }

    private static func run(executable: String, arguments: [String]) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: executable)
            process.arguments = arguments

            let stdout = Pipe()
            let stderr = Pipe()
            process.standardOutput = stdout
            process.standardError = stderr

            process.terminationHandler = { proc in
                let outData = stdout.fileHandleForReading.readDataToEndOfFile()
                let errData = stderr.fileHandleForReading.readDataToEndOfFile()
                let output = String(decoding: outData, as: UTF8.self)
                let errorOutput = String(decoding: errData, as: UTF8.self)

                if proc.terminationStatus == 0 {
                    continuation.resume(returning: output)
                } else {
                    continuation.resume(throwing: BrewError.commandFailed(
                        command: ([executable] + arguments).joined(separator: " "),
                        exitCode: proc.terminationStatus,
                        stderr: errorOutput
                    ))
                }
            }

            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    public static func trustTap(brewPath: String, tap: String) async throws {
        _ = try await run(
            executable: brewPath,
            arguments: ["trust", "--tap", tap]
        )
    }
}

private struct TrustJSON: Decodable {
    let taps: [String]
}
