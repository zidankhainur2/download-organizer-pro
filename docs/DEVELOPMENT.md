# Development Guide

**Project:** Download Organizer Pro

---

# Development Philosophy

This project follows a **Documentation First Development** workflow.

The expected order of work is:

```text
Requirements

↓

Architecture

↓

Documentation

↓

Implementation

↓

Testing

↓

Review

↓

Release
```

Code should implement documented behavior, not define it.

---

# Development Workflow

Every feature should follow the same lifecycle.

```text
Create Issue

↓

Update Documentation

↓

Design Solution

↓

Implement

↓

Write Tests

↓

Run Validation

↓

Review

↓

Merge
```

---

# Repository Structure

```text
DownloadOrganizerPro/

├── .github/
├── docs/
├── examples/
├── logs/
├── modules/
├── tests/
│
├── config.json
├── DownloadOrganizer.ps1
│
├── README.md
├── CHANGELOG.md
├── CONTRIBUTING.md
├── ROADMAP.md
└── LICENSE
```

---

# Module Responsibilities

Each module has exactly one responsibility.

| Module          | Responsibility           |
| --------------- | ------------------------ |
| Config          | Load configuration       |
| Validation      | Validate configuration   |
| Scanner         | Enumerate files          |
| Classifier      | Extension classification |
| SmartClassifier | Keyword classification   |
| Mover           | Move files               |
| Logger          | Logging                  |
| Summary         | Statistics               |
| Models          | Domain models            |
| Utils           | Shared helpers           |

---

# Coding Rules

Every module must:

- Enable `Set-StrictMode`
- Use `CmdletBinding()`
- Export only public functions
- Avoid global variables
- Avoid duplicated logic
- Be independently testable

---

# Function Guidelines

Functions should:

- Have one responsibility
- Be easy to test
- Return objects
- Throw meaningful exceptions
- Use approved PowerShell verbs

Avoid large functions.

Recommended maximum length:

```text
80 lines
```

---

# Variable Naming

Use:

```text
camelCase
```

Example:

```powershell
$config
$fileList
$downloadPath
$logFile
```

Avoid abbreviations.

---

# Function Naming

Use:

```text
Verb-Noun
```

Examples:

```powershell
Get-DownloadFiles

Set-FileCategory

Move-OrganizerFiles

Write-OrganizerLog

Show-OrganizerSummary
```

---

# Public Modules

Public functions must include:

- Comment-Based Help
- Parameter validation
- Error handling
- Pipeline support where appropriate

---

# Private Functions

Private functions:

- Do not require Comment-Based Help
- Should remain internal to the module

---

# Error Handling

Fatal errors:

```text
throw
```

Recoverable errors:

```text
Log

↓

Continue
```

Never silently ignore errors.

---

# Logging

Modules must not write directly to the console.

Instead:

```text
Return objects

↓

Logger handles persistence

↓

Entry point handles display
```

---

# Pipeline Design

Whenever practical, functions should support pipeline input.

Example:

```powershell
Get-DownloadFiles |
Set-FileCategory |
Move-OrganizerFiles
```

---

# Object-Oriented Design

Business data should use strongly typed models.

Avoid:

```powershell
PSCustomObject
```

Prefer:

```powershell
OrganizerFile

OrganizerSummary
```

---

# Configuration

Never hardcode:

- Paths
- Categories
- Extensions
- Smart Rules

Everything belongs in:

```text
config.json
```

---

# Dependencies

Preferred order:

1. Native PowerShell
2. .NET Runtime
3. Standard Modules

Avoid external executables.

---

# Performance Guidelines

Prefer:

- Generic Lists
- Streaming pipelines
- Single-pass processing
- Cached lookups

Avoid:

- Nested loops when unnecessary
- Repeated file enumeration
- Repeated JSON parsing

---

# Documentation Rules

Every feature must update documentation if behavior changes.

Possible files:

```text
README.md

CHANGELOG.md

PRD.md

ARCHITECTURE.md

CONFIGURATION.md

DEVELOPMENT.md

STYLEGUIDE.md
```

---

# Testing Workflow

Before committing:

```text
Run Tests

↓

Run Organizer

↓

Review Log

↓

Review Summary

↓

Commit
```

---

# Pull Request Checklist

Before opening a Pull Request:

- [ ] Documentation updated
- [ ] Tests pass
- [ ] No breaking changes
- [ ] No duplicated code
- [ ] Functions follow naming rules
- [ ] Modules remain focused
- [ ] Configuration unchanged unless required
- [ ] Changelog updated

---

# Review Principles

Reviews should prioritize:

- Correctness
- Simplicity
- Readability
- Maintainability
- Performance

Do not optimize prematurely.

---

# Backward Compatibility

Public APIs should remain stable.

Breaking changes are only allowed in major releases.

---

# Architecture Rule

When adding a new feature:

1. Prefer extending an existing module only if it matches that module's responsibility.
2. Otherwise, create a new module.
3. Do not mix unrelated responsibilities.

---

# Definition of Done

A feature is complete when:

- Documentation is finished.
- Code is implemented.
- Tests pass.
- Logging works.
- Summary is correct.
- Configuration is supported.
- Code review is complete.
- Changelog is updated.

Only then is the feature considered complete.
