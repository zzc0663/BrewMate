import Foundation

/// 包仓库协议（基础设施层实现，内置缓存）
protocol PackageRepository: Sendable {
    /// 已安装的包列表
    func installed() async throws -> [BrewPackage]

    /// 搜索包（可选类型过滤）
    func search(query: String, type: PackageType?) async throws -> [BrewPackage]

    /// 包详情
    func info(for package: String, type: PackageType) async throws -> BrewPackageDetail

    /// 可更新的包列表
    func outdated() async throws -> [OutdatedPackage]

    /// 清除缓存（安装/卸载/升级后自动调用）
    func invalidateCache() async

    /// 安装包（实时输出）
    func install(name: String, type: PackageType) -> AsyncThrowingStream<CommandEvent, Error>

    /// 卸载包（实时输出）
    func uninstall(name: String, type: PackageType) -> AsyncThrowingStream<CommandEvent, Error>

    /// 升级包（实时输出，nil = 升级全部）
    func upgrade(name: String?, type: PackageType?) -> AsyncThrowingStream<CommandEvent, Error>
}
