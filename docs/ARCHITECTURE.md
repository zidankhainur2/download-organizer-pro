# Architecture

**Project:** Download Organizer Pro  
**Version:** 2.0.0

---

# 1. Overview

Download Organizer Pro is designed using a modular architecture.

Each module has a single responsibility and communicates through well-defined interfaces.

Core principles:

- Single Responsibility Principle
- Separation of Concerns
- Config-Driven Design
- Pipeline-Friendly PowerShell
- Fail Fast
- Strong Typing
- Low Coupling
- High Cohesion

---

# 2. High-Level Architecture

```text
                 config.json
                      │
                      ▼
              Config Module
                      │
                      ▼
           Validation Module
                      │
                      ▼
             Scanner Module
                      │
                      ▼
            OrganizerFile[]
                      │
          ┌───────────┴───────────┐
          ▼                       ▼
  Classifier Module      Smart Classifier
          │                       │
          └───────────┬───────────┘
                      ▼
             Destination Resolver
                      │
                      ▼
              Mover Module
                      │
          ┌───────────┴───────────┐
          ▼                       ▼
      Logger Module         Summary Module
```

---

# 3. Project Structure

```text
DownloadOrganizerPro/

├── DownloadOrganizer.ps1
├── config.json
│
├── modules/
│   ├── Models.psm1
│   ├── Utils.psm1
│   ├── Validation.psm1
│   ├── Config.psm1
│   ├── Scanner.psm1
│   ├── Classifier.psm1
│   ├── SmartClassifier.psm1
│   ├── DuplicateDetector.psm1
│   ├── Mover.psm1
│   ├── Logger.psm1
│   ├── Summary.psm1
│   ├── Undo.psm1
│   ├── Watcher.psm1
│   ├── Scheduler.psm1
│   └── ReportGenerator.psm1
│
├── tests/
├── docs/
└── logs/
```

---

# 4. Execution Flow

```text
Application Start

↓

Load Configuration

↓

Validate Configuration

↓

Scan Downloads

↓

Create OrganizerFile Objects

↓

Extension Classification

↓

Smart Classification

↓

Resolve Destination

↓

Move Files

↓

Write Log

↓

Display Summary

↓

Exit
```

---

# 5. Module Responsibilities

## DownloadOrganizer.ps1

Responsibilities:

- Application entry point
- Load modules
- Execute workflow
- Display output

Must not contain business logic.

---

## Config.psm1

Responsibilities:

- Load configuration
- Parse JSON
- Resolve environment variables
- Provide configuration API

---

## Validation.psm1

Responsibilities:

Validate:

- Settings
- Categories
- Smart Rules
- Download path

---

## Scanner.psm1

Responsibilities:

- Enumerate files
- Convert FileInfo to OrganizerFile

No classification logic.

---

## Classifier.psm1

Responsibilities:

- Categorize files by extension

No Smart Rule logic.

---

## SmartClassifier.psm1

Responsibilities:

- Keyword matching
- Priority evaluation
- Subcategory selection
- Smart score calculation

---

## Mover.psm1

Responsibilities:

- Create directories
- Resolve duplicate names
- Move files
- Update file status

---

## Logger.psm1

Responsibilities:

- Create log files
- Record operations
- Record errors

---

## Summary.psm1

Responsibilities:

- Calculate statistics
- Display execution summary

---

## Utils.psm1

Shared helper functions.

Examples:

- Ensure directory
- Resolve path
- Normalize filename
- SHA256
- Duration formatting

---

## Models.psm1

Contains:

- OrganizerFile
- OrganizerSummary
- MoveStatus

---

# 6. Data Model

## OrganizerFile

```text
Name

Extension

FullPath

Directory

SizeBytes

Category

SubCategory

DestinationPath

SmartScore

Status

Destination

ErrorMessage
```

Methods:

```text
SetCategory()

SetSubCategory()

MarkMoved()

MarkFailed()

MarkSkipped()
```

---

## OrganizerSummary

```text
TotalFiles

Moved

Skipped

Failed

TotalSize

Duration

Categories
```

---

# 7. Data Flow

```text
FileInfo

↓

OrganizerFile

↓

Category Assigned

↓

SubCategory Assigned

↓

Destination Calculated

↓

Moved

↓

Logged

↓

Summarized
```

---

# 8. Configuration Flow

```text
config.json

↓

Read File

↓

ConvertFrom-Json

↓

Resolve Variables

↓

Validate

↓

Configuration Object

↓

Application
```

---

# 9. Error Handling

Fatal errors:

- Missing configuration
- Invalid JSON
- Invalid settings
- Missing Downloads folder

Execution stops immediately.

---

Recoverable errors:

- Access denied
- Locked file
- Duplicate filename
- Move failure

Execution continues.

---

# 10. Logging Strategy

Each execution creates one log file.

Recorded information:

- Timestamp
- File name
- Category
- Destination
- Status
- Error message
- Duration

---

# 11. Performance Goals

Design targets:

- Support 10,000+ files
- Avoid unnecessary object allocations
- Minimize repeated lookups
- Use Generic Lists where appropriate
- Avoid duplicate file enumeration

---

# 12. Coding Standards

Required for all modules:

- PowerShell 5.1+
- Set-StrictMode
- CmdletBinding
- Comment-Based Help
- Approved verbs
- PascalCase functions
- camelCase variables
- Export-ModuleMember
- Pipeline support where appropriate

Forbidden:

- Business logic in entry point
- Write-Host inside modules
- Hardcoded configuration values
- Duplicate logic across modules

---

# 13. Extensibility

Future modules should integrate without modifying existing modules.

Potential modules:

```text
DuplicateDetector.psm1

Watcher.psm1

Undo.psm1

Scheduler.psm1

AIClassifier.psm1

ReportGenerator.psm1
```

---

# 14. Design Principles

Every module should:

- Have one responsibility
- Be independently testable
- Minimize dependencies
- Prefer composition over duplication
- Keep public APIs stable

---

# 15. Architecture Stability

Version 2.0 establishes the project's architectural baseline.

Future versions should extend the architecture without introducing breaking changes unless required for a major release.
