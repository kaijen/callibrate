# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.1] - 2026-03-01

### Fixed
- Drift column name conflict (`Questions.text` shadowed inherited `text()`
  method); renamed to `questionText` with `.named('text')`
- Replace `SharePlus.instance`/`ShareParams` with stable `Share.shareXFiles`
  API (share_plus 10.x)
- Bump `compileSdk`/`targetSdk` to 36 (required by path_provider and
  flutter_plugin_android_lifecycle)
- Upgrade Gradle wrapper to 8.10.2, AGP to 8.7.0, Kotlin to 2.1.0

## [0.1.0] - 2026-03-01

### Added
- Core app: probability estimation, resolution, calibration stats, and JSON/YAML import
- Settings screen, tag filter, and clipboard import for question sets
- GitHub Actions release workflow for tag-triggered APK builds

[Unreleased]: https://github.com/kaijen/callibrate/compare/v0.1.1...HEAD
[0.1.1]: https://github.com/kaijen/callibrate/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/kaijen/callibrate/releases/tag/v0.1.0
