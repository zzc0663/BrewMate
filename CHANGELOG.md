# Changelog

All notable changes to this project will be documented in this file.

The format is inspired by Keep a Changelog, adapted for this project.

## [1.0.0] - 2026-06-20

### Added

- Initial public release of BrewMate, a native macOS Homebrew GUI built with Swift and SwiftUI
- Installed packages view with search, type filtering, detail panel, and update badge
- Explore view for searching Formula and Cask packages and installing new packages
- Package detail view with description, version, homepage, dependencies, and live operation logs
- Single-package install, uninstall, and upgrade flows
- Batch upgrade and batch uninstall support from the installed packages page
- Homebrew trust state inspection and handling in Settings
- Theme switching with system, light, and dark appearance options
- App icon generation, `.icns` packaging, signing, notarization, versioned release zip generation, and GitHub Actions release automation

### Requirements

- macOS 14 or later
- Homebrew installed locally
