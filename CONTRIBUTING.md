# Contributing Guide

First of all, thank you for your interest in contributing to Download Organizer Pro.

Please read this guide before opening an Issue or Pull Request.

---

# Development Principles

The project follows these principles:

- Documentation First
- Clean Architecture
- Modular Design
- Config-Driven Development
- Backward Compatibility
- Readability over Cleverness

---

# Repository Structure

```text
DownloadOrganizerPro/

├── modules/
├── tests/
├── docs/
├── logs/
├── examples/
├── DownloadOrganizer.ps1
└── config.json
```

---

# Coding Standards

All code must follow the project style guide.

Requirements:

- PowerShell 5.1+
- Set-StrictMode enabled
- CmdletBinding()
- PascalCase function names
- camelCase variable names
- Comment-Based Help for public functions
- Export-ModuleMember for public functions
- No Write-Host inside modules
- Use approved PowerShell verbs
- Prefer pipeline support where appropriate

---

# Branch Naming

Use the following naming convention:

```text
feature/<feature-name>

bugfix/<issue-name>

docs/<document-name>

refactor/<module-name>

test/<module-name>
```

Examples:

```text
feature/smart-classifier

bugfix/mover-duplicate

docs/readme-update

refactor/scanner

test/config
```

---

# Commit Message Convention

Use clear and descriptive commit messages.

Examples:

```text
feat: add smart classification engine

fix: resolve duplicate filename issue

docs: update architecture documentation

refactor: simplify scanner module

test: add config validation tests
```

---

# Pull Request Checklist

Before submitting a Pull Request, ensure:

- [ ] Project builds successfully
- [ ] Tests pass
- [ ] Documentation updated
- [ ] Changelog updated
- [ ] No breaking changes
- [ ] Coding standards followed
- [ ] No unnecessary dependencies added

---

# Documentation

Every new feature must include documentation updates.

Update when necessary:

- README.md
- CHANGELOG.md
- PRD.md
- ARCHITECTURE.md
- CONFIGURATION.md
- DEVELOPMENT.md

---

# Testing

All new features should include tests whenever practical.

Minimum expectations:

- Happy path
- Invalid input
- Error handling
- Edge cases

---

# Reporting Bugs

Include:

- PowerShell version
- Windows version
- Configuration used
- Expected behavior
- Actual behavior
- Error message
- Steps to reproduce

---

# Feature Requests

Please describe:

- Problem
- Proposed solution
- Alternative solutions
- Expected benefits

---

# Code Review

Pull requests should prioritize:

- Simplicity
- Readability
- Maintainability
- Performance
- Backward compatibility

---

# Architecture Rules

Do not:

- Mix responsibilities between modules
- Hardcode configuration values
- Duplicate logic
- Introduce unnecessary complexity

Always:

- Keep modules focused
- Prefer reusable functions
- Preserve existing APIs
- Follow project architecture

---

# Questions

If you're unsure about a design decision, open an Issue before implementing large changes.

Architecture discussions are always welcome.
