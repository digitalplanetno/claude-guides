# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.1.0] - 2025-01-13

### Added

- CI/CD with GitHub Actions (shellcheck, markdownlint, template validation)
- `update-claude.sh` script for updating templates in existing projects
- Dry-run mode (`--dry-run`) for init scripts
- More framework detection (Django, Rails, Go, Rust)
- Makefile for development tasks
- Pre-commit hooks configuration
- GitHub issue and PR templates
- New commands: `/fix`, `/explain`, `/test`, `/refactor`, `/migrate`
- Example configurations for Laravel SaaS, Next.js Dashboard, Monorepo
- LICENSE (MIT)
- SECURITY.md
- CONTRIBUTING.md

### Changed

- Improved init scripts with backup functionality
- Better error handling in shell scripts

## [1.0.0] - 2025-01-13

### Added

- Initial release
- Base templates (framework-agnostic):
  - SECURITY_AUDIT.md
  - PERFORMANCE_AUDIT.md
  - CODE_REVIEW.md
  - DEPLOY_CHECKLIST.md
- Laravel-specific templates
- Next.js-specific templates
- Reusable components:
  - severity-levels.md
  - self-check-section.md
  - report-format.md
  - quick-check-scripts.md
- Slash commands: `/doc`, `/find-script`, `/find-function`, `/audit`
- Init scripts (`init-claude.sh`, `init-local.sh`)
- README with usage instructions
