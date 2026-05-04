# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.0] - 2026-05-04

### Added
- `plugin.json` for all-in-one plugin installation via `copilot plugin install sujithq/skills`
- GitHub Actions workflow for automated publishing on tag push
- Support for future marketplace-based installations

### Changed
- Modernized installation instructions (from `npx skills add` to `gh skill install` and `copilot plugin`)
- Updated README with multiple installation options

## [1.1.0] - 2026-05-04

### Added
- Initial GitHub Skills release
- Migrated skills to `skills/` folder structure for discoverability

### Fixed
- Skills now discoverable via `gh skill install`

## [1.0.0] - 2026-05-04

### Added
- `commit-message-writer` skill: Generate conventional commit messages
- `pdf-to-markdown` skill: Convert PDF and Office files to Markdown
- MIT License
- Initial repository setup
