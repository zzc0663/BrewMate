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
    let desc: String?
    let homepage: String?
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

    private enum CodingKeys: String, CodingKey {
        case name, full_name, desc, homepage, versions, installed, dependencies
        case build_dependencies, requirements, tap, license, keg_only, pinned
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        full_name = try container.decode(String.self, forKey: .full_name)
        desc = try container.decodeIfPresent(String.self, forKey: .desc)
        homepage = try container.decodeIfPresent(String.self, forKey: .homepage)
        versions = try container.decode(VersionsJSON.self, forKey: .versions)
        installed = try container.decodeIfPresent([InstalledJSON].self, forKey: .installed) ?? []
        dependencies = try container.decodeIfPresent([String].self, forKey: .dependencies) ?? []
        build_dependencies = try container.decodeIfPresent([String].self, forKey: .build_dependencies) ?? []
        requirements = try container.decodeIfPresent([RequirementJSON].self, forKey: .requirements) ?? []
        tap = try container.decodeIfPresent(String.self, forKey: .tap) ?? "homebrew/core"
        license = try container.decodeIfPresent(String.self, forKey: .license)
        keg_only = try container.decodeIfPresent(Bool.self, forKey: .keg_only) ?? false
        pinned = try container.decodeIfPresent(Bool.self, forKey: .pinned) ?? false
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

        init(cask: [String], formula: [String]) {
            self.cask = cask
            self.formula = formula
        }

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

    private enum CodingKeys: String, CodingKey {
        case token, full_token, desc, homepage, version, installed, tap, depends_on
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        token = try container.decode(String.self, forKey: .token)
        full_token = try container.decodeIfPresent(String.self, forKey: .full_token) ?? token
        desc = try container.decodeIfPresent(String.self, forKey: .desc)
        homepage = try container.decodeIfPresent(String.self, forKey: .homepage)
        version = try container.decodeIfPresent(String.self, forKey: .version)
        installed = try container.decodeIfPresent(String.self, forKey: .installed)
        tap = try container.decodeIfPresent(String.self, forKey: .tap) ?? "homebrew/cask"
        depends_on = (try? container.decode(DependsOnJSON.self, forKey: .depends_on))
            ?? DependsOnJSON(cask: [], formula: [])
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
