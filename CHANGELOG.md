# Changelog

All notable changes to this project will be documented in this file.

The format is based on **Keep a Changelog**.
This project follows **Semantic Versioning (SemVer)**.

---

## [Unreleased]

### Added

- Documentation-first development workflow
- Professional repository structure
- Modular PowerShell architecture
- AI-assisted development support

### Changed

- Project architecture refactored for maintainability
- Standardized module interfaces

---

## [2.0.0] - In Development

### Added

#### Reports Features (Completed Phase 6)

- Added `modules/ReportGenerator.psm1` for CSV, JSON, and standalone HTML dashboard report generation (`Export-OrganizerCSV`, `Export-OrganizerJSON`, `Export-OrganizerHTMLReport`, `Get-OrganizerStatistics`).
- Generated modern dark mode HTML execution dashboard with metric cards, category breakdown tables, and operation details.
- Added `-ExportCSV`, `-ExportJSON`, `-ExportHTML`, and `-Report` CLI switch parameters to `DownloadOrganizer.ps1`.
- Expanded Pester unit test suite to 47 tests covering all Phase 6 report generation functions.

#### Core

- PowerShell entry point
- Configuration loader
- Configuration validation
- Utility library
- Domain models
- Modular architecture

#### Scanner

- Downloads directory scanner
- Strongly typed `OrganizerFile` model
- Pipeline-friendly design

#### Classification

- Extension-based file classification
- Config-driven category mapping

#### Smart Classification

- Keyword-based classification
- Subcategory support
- Smart score calculation

#### File Operations

- Safe file moving
- Automatic directory creation
- Duplicate filename resolution

#### Logging

- Execution logging
- Error logging
- Move history

#### Summary

- Execution summary
- Statistics
- Duration reporting

#### Documentation

- README
- PRD
- Architecture
- Development Guide
- Style Guide
- Testing Guide
- Configuration Guide

---

## Planned

### Version 2.1

#### Added

- Duplicate detection
- Undo operation
- Hash comparison
- Duplicate reporting

---

### Version 2.2

#### Added

- Real-time folder watcher
- Automatic organization
- Background execution

---

### Version 3.0

#### Added

- Desktop GUI
- AI-powered classification
- Plugin system
- Scheduler
- Multi-folder support
- Rule editor

---

## Versioning Policy

Version numbers follow:

MAJOR.MINOR.PATCH

Example:

- 2.0.0
- 2.1.0
- 2.1.1

### MAJOR

Breaking architectural changes.

### MINOR

New features without breaking compatibility.

### PATCH

Bug fixes, optimizations, and documentation updates.
