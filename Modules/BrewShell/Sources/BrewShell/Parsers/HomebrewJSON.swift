import Foundation

// MARK: - brew info / brew list --json=v2 输出结构

/// JSON 顶层信封：`brew info --installed --json=v2` 或 `brew info --json=v2 <name>`
struct HomebrewJSON: Decodable {
    let formulae: [FormulaJSON]
    let casks: [CaskJSON]
}

/// Formula JSON 条目
struct FormulaJSON: Decodable {
    let name: String
    let full_name: String
    let desc: String
    let homepage: [String]
    let versions: VersionsJSON
    let installed: [InstalledJSON]
    let dependencies: [String]
    let build_dependencies: [String]
    let requirements: [RequirementJSON]
    let tap: String
    let license: String?
    let keg_only: Bool
    let pinned: Bool

    struct VersionsJSON: Decodable {
        let stable: String?
        let head: String?
    }

    struct InstalledJSON: Decodable {
        let version: String
        let time: Int64?
        let installed_on_request: Bool
        let cellar: String?
    }

    struct RequirementJSON: Decodable {
        let name: String
    }
}

/// Cask JSON 条目
struct CaskJSON: Decodable {
    let token: String
    let full_token: String
    let desc: String?
    let homepage: String?
    let version: String?
    let installed: String?
    let tap: String
    let depends_on: DependsOnJSON

    struct DependsOnJSON: Decodable {
        let cask: [String]
        let formula: [String]

        var keys: [String] { cask + formula }

        // 自定义解码：depends_on 可能缺失某些键
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            cask = (try? container.decode([String].self, forKey: .cask)) ?? []
            formula = (try? container.decode([String].self, forKey: .formula)) ?? []
        }

        private enum CodingKeys: String, CodingKey {
            case cask, formula
        }
    }
}

// MARK: - brew outdated --json=v2 输出结构

/// outdated JSON 顶层信封
struct OutdatedJSON: Decodable {
    let formulae: [OutdatedFormulaJSON]
    let casks: [OutdatedCaskJSON]
}

/// outdated Formula 条目
struct OutdatedFormulaJSON: Decodable {
    let name: String
    let installed_versions: [String]
    let current_version: String
    let pinned: Bool
}

/// outdated Cask 条目
struct OutdatedCaskJSON: Decodable {
    let token: String
    let installed: String?
    let version: String
}
