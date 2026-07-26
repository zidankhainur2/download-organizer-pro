# Architectural Decision Records (ADR)

**Project:** Download Organizer Pro

This document records the major architectural decisions made throughout the project.

Once accepted, an ADR should not be modified except to clarify wording or record a superseding decision.

---

# ADR-0001

## Title

Use PowerShell as the Primary Language

### Status

Accepted

### Date

2026-07-26

### Context

The application is intended primarily for Windows users who want to organize their Downloads folder without installing additional runtimes.

### Decision

Implement the project using PowerShell 5.1+.

### Consequences

Advantages:

- Available by default on Windows
- Native file system support
- Easy automation
- Strong .NET integration

Disadvantages:

- Limited cross-platform focus
- Smaller ecosystem than general-purpose languages

---

# ADR-0002

## Title

Configuration-Driven Architecture

### Status

Accepted

### Date

2026-07-26

### Context

Users should be able to customize behavior without modifying source code.

### Decision

Store application behavior in `config.json`.

Configuration includes:

- Settings
- Categories
- Smart Rules

### Consequences

Advantages:

- Easy customization
- No recompilation
- Easier maintenance

Disadvantages:

- Configuration validation becomes mandatory

---

# ADR-0003

## Title

Modular Architecture

### Status

Accepted

### Date

2026-07-26

### Context

The project is expected to grow over time.

### Decision

Split functionality into independent PowerShell modules.

Examples:

- Config
- Validation
- Scanner
- Classifier
- SmartClassifier
- Mover
- Logger
- Summary

### Consequences

Advantages:

- Easier testing
- Better maintainability
- Lower coupling

---

# ADR-0004

## Title

Strongly Typed Domain Models

### Status

Accepted

### Date

2026-07-26

### Context

Business data should remain consistent across modules.

### Decision

Use PowerShell classes instead of PSCustomObject for domain entities.

Primary models:

- OrganizerFile
- OrganizerSummary

### Consequences

Advantages:

- Better readability
- Type safety
- Easier refactoring

---

# ADR-0005

## Title

Pipeline-Friendly Design

### Status

Accepted

### Date

2026-07-26

### Context

PowerShell applications should integrate naturally with the pipeline.

### Decision

Public commands should support pipeline input whenever appropriate.

Example:

```powershell
Get-DownloadFiles |
Set-FileCategory |
Move-OrganizerFiles
```

### Consequences

Advantages:

- More idiomatic PowerShell
- Easier composition
- Better reuse

---

# ADR-0006

## Title

Single Responsibility Principle

### Status

Accepted

### Date

2026-07-26

### Context

Large modules become difficult to test and maintain.

### Decision

Each module should have exactly one responsibility.

Example:

Scanner

- Enumerate files

Classifier

- Assign category

Mover

- Move files

Logger

- Persist logs

### Consequences

Advantages:

- Smaller modules
- Easier testing
- Lower maintenance cost

---

# ADR-0007

## Title

Documentation-First Development

### Status

Accepted

### Date

2026-07-26

### Context

The project is intended to support both human contributors and AI-assisted development.

### Decision

Documentation is written before implementation.

Required order:

Requirements

↓

Architecture

↓

Documentation

↓

Implementation

↓

Testing

### Consequences

Advantages:

- Stable architecture
- Better planning
- Improved AI coding results
- Reduced refactoring

---

# ADR-0008

## Title

Fail Fast Configuration Validation

### Status

Accepted

### Date

2026-07-26

### Context

Invalid configuration can cause unpredictable behavior.

### Decision

Validate configuration before any file operations.

Execution stops immediately on validation failure.

### Consequences

Advantages:

- Prevents accidental file operations
- Clear error reporting
- Predictable execution

---

# ADR-0009

## Title

Configuration over Hardcoded Values

### Status

Accepted

### Date

2026-07-26

### Context

Hardcoded values reduce flexibility.

### Decision

Do not hardcode:

- Categories
- Extensions
- Keywords
- Paths

Everything belongs in configuration.

### Consequences

Advantages:

- Easier customization
- Better scalability
- Simpler maintenance

---

# ADR-0010

## Title

Stable Public APIs

### Status

Accepted

### Date

2026-07-26

### Context

Future versions should avoid unnecessary breaking changes.

### Decision

Public module interfaces should remain stable throughout a major version.

Breaking changes require a new major release.

### Consequences

Advantages:

- Easier upgrades
- Better compatibility
- Predictable integrations

---

# Future ADRs

Future architectural decisions should be added as new records rather than modifying existing ones.

Examples:

- AI Classification
- Plugin System
- GUI Architecture
- File Watcher
- Scheduler
- Cloud Integration
- Cross-Platform Support

---

# ADR Template

```markdown
# ADR-XXXX

## Title

...

### Status

Proposed | Accepted | Superseded | Deprecated

### Date

YYYY-MM-DD

### Context

...

### Decision

...

### Consequences

Advantages

Disadvantages
```
