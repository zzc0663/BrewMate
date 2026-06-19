# BrewMate

一个原生 macOS 的 Homebrew 图形化管理工具，使用 Swift + SwiftUI 构建，面向日常包管理场景：查看已安装包、搜索新包、安装/卸载、更新，以及基础环境检查。

## 项目定位

BrewMate 不是 Homebrew 的替代品，而是一个更适合桌面使用的管理界面。当前版本重点覆盖 Homebrew 的核心应用管理流程，并保持架构清晰，方便后续继续扩展：

- 已安装包管理
- 搜索 Formula / Cask
- 单包安装、卸载、更新
- 已安装页批量选择、批量更新、批量卸载
- Homebrew trust 状态检查与处理
- 主题切换

## 当前界面结构

应用当前保留 3 个一级页面：

- `已安装`
  - 搜索、类型筛选
  - 焦点详情面板
  - 单包更新 / 卸载
  - 批量更新 / 批量卸载
- `探索`
  - 搜索 Formula / Cask
  - 查看详情
  - 安装未安装包
- `设置`
  - 主题切换
  - Homebrew trust 提示与“信任”操作

可更新数量会显示在侧边栏 `已安装` 项上。

## 技术结构

项目采用三层 SPM 模块化结构，依赖方向单向：

`BrewMate (UI)` -> `BrewShell (Infrastructure)` -> `BrewKit (Domain)`

### 模块说明

- `Modules/BrewKit`
  - 领域模型
  - 协议定义
  - 命令抽象
- `Modules/BrewShell`
  - `brew` 命令执行
  - JSON / 文本解析
  - Repository 实现
  - 缓存与环境检查
- `Modules/BrewMate`
  - SwiftUI 界面
  - 全局状态
  - 页面 ViewModel
  - 主题与交互逻辑

## 运行环境

- macOS 14+
- Swift 5.9+
- 已安装 Homebrew

默认通过本机 Homebrew 环境运行，应用启动时会自动检测 `brew` 路径。

## 本地开发

### 直接运行

```bash
swift run BrewMate
```

### Release 构建

```bash
swift build -c release
```

### 打包 `.app`

```bash
bash build.sh
```

产物位于：

- `BrewMate.app`

构建脚本会在缺少应用图标时自动生成：

- `Assets/AppIcon-1024.png`
- `Assets/AppIcon.iconset/`
- `Assets/AppIcon.icns`

### 生成应用图标

```bash
node scripts/generate_app_icon.js
```

生成产物位于：

- `Assets/AppIcon-1024.png`
- `Assets/AppIcon.iconset/`
- `Assets/AppIcon.icns`

可直接启动：

```bash
open BrewMate.app
```

## 签名与 Notarization

首发分发给其他 macOS 用户时，建议使用 `Developer ID Application` 证书签名，并通过 Apple notarization。

### 前置条件

- Apple Developer Program 账号
- 钥匙串中已安装 `Developer ID Application` 证书
- `security find-identity -v -p codesigning` 能看到可用 identity
- 已配置 notarytool 凭据

当前机器可用 identity 检查：

```bash
security find-identity -v -p codesigning
```

### 保存 notarization 凭据

首次配置可运行：

```bash
bash scripts/store_notary_credentials.sh
```

默认会在钥匙串里保存一个 `BrewMateNotary` profile，后续提交 notarization 时直接复用。

### 签名并提交 notarization

先构建应用：

```bash
bash build.sh
```

然后执行签名、公证、staple：

```bash
SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
bash scripts/notarize_app.sh
```

可选环境变量：

- `NOTARY_PROFILE`：默认 `BrewMateNotary`
- `APP_BUNDLE`：默认 `BrewMate.app`
- `ZIP_PATH`：默认 `BrewMate.zip`
- `ENTITLEMENTS_PATH`：默认 `entitlements.plist`

### 产物

- 已签名并 stapled 的 `BrewMate.app`
- 提交 notarization 用的 `BrewMate.zip`

## 版本化发布

项目版本号保存在：

- `VERSION`
- `CHANGELOG.md`

修改版本时直接更新这个文件，例如：

```text
1.0.1
```

同时建议在 `CHANGELOG.md` 中新增对应版本段落，GitHub Release 会优先使用该版本的 changelog 内容作为正文。

### 本地生成发布包

生成版本化 zip：

```bash
bash scripts/release.sh
```

默认产物位于：

- `dist/BrewMate-v<version>.zip`
- `dist/release-notes-v<version>.md`

如果同时执行签名和 notarization：

```bash
SIGN_AND_NOTARIZE=1 \
SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
bash scripts/release.sh
```

## GitHub Actions 自动发布

仓库已包含自动发布工作流：

- `.github/workflows/release.yml`
- `.github/release-notes-template.md`

触发方式：

- push `v*` tag，例如 `v1.0.0`
- GitHub Actions 手动触发

### 需要配置的 GitHub Secrets

- `MACOS_KEYCHAIN_PASSWORD`
- `MACOS_DEVELOPER_ID_APP_CERT_BASE64`
- `MACOS_DEVELOPER_ID_APP_CERT_PASSWORD`
- `MACOS_DEVELOPER_ID_APP_IDENTITY`
- `APPLE_API_KEY_ID`
- `APPLE_API_ISSUER_ID`
- `APPLE_API_PRIVATE_KEY_BASE64`

说明：

- `MACOS_DEVELOPER_ID_APP_CERT_BASE64` 是你的 `Developer ID Application` 证书 `.p12` 做 base64 后的内容
- `MACOS_DEVELOPER_ID_APP_CERT_PASSWORD` 是导出这个 `.p12` 时设置的密码
- `MACOS_DEVELOPER_ID_APP_IDENTITY` 形如 `Developer ID Application: Your Name (TEAMID)`
- `APPLE_API_PRIVATE_KEY_BASE64` 是 App Store Connect API 私钥 `.p8` 做 base64 后的内容

### Release 文案模板

GitHub Release 会优先使用模板渲染后的正文：

- 模板：`.github/release-notes-template.md`
- changelog：`CHANGELOG.md`
- 渲染脚本：`scripts/render_release_notes.sh`

渲染优先级：

- 先读取 `CHANGELOG.md` 中当前版本段落
- 如果当前版本未写 changelog，再回退到模板 `.github/release-notes-template.md`

本地也可以单独生成：

```bash
bash scripts/render_release_notes.sh
```

### 推荐发布流程

1. 更新 `VERSION`
2. 提交并推送代码
3. 创建 tag：`git tag -a v<version> -m "BrewMate v<version>"`
4. 推送 tag：`git push origin v<version>`
5. 等待 GitHub Actions 构建、签名、公证并创建 GitHub Release
