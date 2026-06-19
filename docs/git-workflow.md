# BrewMate — Git 工作流规范

> 最后更新: 2026-06-19

## 分支策略（Git Flow 简化版）

### 分支结构

| 分支 | 用途 | 生命周期 |
|------|------|---------|
| `main` | 生产稳定版本，只接受 merge，永远可部署 | 永久 |
| `develop` | 开发集成分支，日常开发的基准 | 永久 |
| `feature/{任务编号}-{简述}` | 每个任务一个 feature 分支 | 完成后合并到 develop 并删除 |

### 分支命名规范

```
feature/T1.1-package-structure
feature/T1.2-build-script
feature/T2.1-brewkit-models
feature/T3.1-brewshell-core
feature/T4.1-ui-skeleton
feature/T5.1-installed-view
feature/T5.2-detail-view
feature/T5.3-explore-view
feature/T5.4-updates-view
feature/T5.5-settings-view
feature/T6.1-compile-verify
feature/T6.2-regression-test
```

---

## 工作流程

### 每个任务的标准流程

```bash
# 1. 确保在 develop 分支且是最新的
git checkout develop
git pull origin develop

# 2. 创建 feature 分支
git checkout -b feature/T1.1-package-structure

# 3. 开发...
# ... 编写代码 ...

# 4. 完成后暂存并提交
git add .
git commit -m "T1.1: feat(scaffold): 初始化 Package.swift + 目录结构"

# 5. 切回 develop 并合并
git checkout develop
git merge feature/T1.1-package-structure --no-ff

# 6. 推送到远程
git push origin develop

# 7. 删除本地 feature 分支
git branch -d feature/T1.1-package-structure

# 8. 删除远程 feature 分支（如果已推送过）
git push origin --delete feature/T1.1-package-structure
```

### `--no-ff` 说明

使用 `--no-ff`（no fast-forward）合并，确保每次合并都创建一个 merge commit，保留完整的分支历史。

---

## Commit Message 规范

### 格式

```
T{编号}: {type}({scope}): {简短描述}

{可选的详细说明}
```

### Type 类型

| type | 用途 |
|------|------|
| `feat` | 新功能 |
| `fix` | 修复 bug |
| `docs` | 文档变更 |
| `refactor` | 重构（不改变功能） |
| `test` | 测试相关 |
| `chore` | 构建、工具等杂项 |

### Scope 范围

| scope | 说明 |
|-------|------|
| `scaffold` | 项目骨架、构建配置 |
| `brewkit` | 领域层 |
| `brewshell` | 基础设施层 |
| `ui` | UI 骨架、通用组件 |
| `installed` | 已安装页面 |
| `detail` | 详情页面 |
| `explore` | 搜索/探索页面 |
| `settings` | 设置页面 |
| `docs` | 文档 |

### 示例

```
T1.1: feat(scaffold): 初始化 Package.swift + 目录结构
T2.1: feat(brewkit): 添加模型、协议、命令枚举
T3.1: feat(brewshell): 实现 ProcessRunner + Parsers + Repository
T4.1: feat(ui): App 骨架 + AppState + Sidebar + Theme
T5.1: feat(installed): 已安装列表视图
T5.2: feat(detail): 包详情面板
T5.3: feat(explore): 搜索 + 安装视图
T5.4: feat(updates): 更新管理视图
T5.5: feat(settings): 主题切换设置页
T6.1: chore(verify): 全量编译验证
T6.2: test(regression): 功能回归测试
```

---

## 远程推送策略

| 操作 | 时机 |
|------|------|
| `push develop` | 每完成一个任务 |
| `merge develop → main` | Phase 完成时（里程碑） |
| `push main` | 里程碑推送 |

---

## 远程仓库

```
origin: git@github.com:zzc0663/new-brew.git
```

---

## 初始化流程（项目开始前执行一次）

```bash
# 1. 初始化 git
git init

# 2. 创建 main 分支并做初始提交
git checkout -b main
git add docs/
git commit -m "chore(init): 项目初始化，添加规划文档"

# 3. 关联远程
git remote add origin git@github.com:zzc0663/new-brew.git
git push -u origin main

# 4. 创建 develop 分支
git checkout -b develop
git push -u origin develop
```

完成初始化后，即可按上述任务流程开始开发。
