# Contributing to Claude Guides

Thank you for your interest in contributing! This document provides guidelines and instructions.

## How to Contribute

### Reporting Issues

- Check if the issue already exists
- Use the appropriate issue template
- Provide as much detail as possible

### Suggesting Templates

1. Open an issue with the "Template Request" label
2. Describe the framework/use case
3. Share example prompts if you have them

### Submitting Changes

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Make your changes
4. Run tests: `make lint && make test`
5. Commit with a descriptive message
6. Push and create a Pull Request

## Development Setup

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/claude-guides.git
cd claude-guides

# Install dependencies
make install

# Run linters
make lint

# Run tests
make test

# Validate templates
make validate
```

## Template Guidelines

### Required Sections

Every audit template MUST include:

1. **QUICK CHECK** - 5-minute rapid assessment
2. **PROJECT SPECIFICS** - Customizable section
3. **SEVERITY LEVELS** - Consistent severity definitions
4. **САМОПРОВЕРКА (Self-Check)** - False positive filter
5. **ФОРМАТ ОТЧЁТА (Report Format)** - Output template
6. **ДЕЙСТВИЯ (Actions)** - Step-by-step instructions

### Style Guide

- Use Russian for main content (English versions in `locales/en/`)
- Use emoji for severity: 🔴 CRITICAL, 🟠 HIGH, 🟡 MEDIUM, 🔵 LOW, ⚪ INFO
- Include code examples with clear "bad" vs "good" patterns
- Keep bash scripts shellcheck-compliant

### Testing Your Changes

```bash
# Test init script with your changes
cd /tmp && mkdir test-project && cd test-project
touch artisan  # or next.config.js for Next.js
bash /path/to/claude-guides/scripts/init-local.sh

# Verify templates work
cat .claude/prompts/SECURITY_AUDIT.md
```

## Code of Conduct

- Be respectful and constructive
- Focus on the technical merits
- Help others learn

## Questions?

Open an issue with the "Question" label or start a discussion.

---

Thank you for contributing!
