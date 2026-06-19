# Changelog

All notable changes to this project will be documented in this file.

The format is inspired by Keep a Changelog, adapted for this project.

## [1.0.0] - 2026-06-20

### 新增

- BrewMate 首个公开版本发布，一个使用 Swift 和 SwiftUI 构建的原生 macOS Homebrew 图形管理工具
- 已安装页面，支持搜索、类型筛选、详情面板和更新数量提示
- 探索页面，支持搜索 Formula 和 Cask 并安装新包
- 包详情页面，支持查看描述、版本、主页、依赖和实时操作日志
- 单包安装、卸载、更新流程
- 已安装页面批量更新、批量卸载
- 设置页中的 Homebrew trust 状态检查与处理
- 跟随系统、浅色、深色三种主题切换
- 应用图标生成、`.icns` 打包、签名、公证、版本化发布 zip，以及 GitHub Actions 自动发布流程

### 运行要求

- macOS 14 或更高版本
- 本机已安装 Homebrew
