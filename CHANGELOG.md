# Changelog

All notable changes to this project will be documented in this file.

The format is based on **Keep a Changelog**.
This project follows **Semantic Versioning (SemVer)**.

---

## [2.1.0] - 2026-07-26

### Added

#### Desktop GUI & Executable Release
- Added `modules/GUI.psm1` providing a native WPF Desktop Graphical User Interface (`Show-OrganizerGUI`, `New-OrganizerWindow`).
- Designed modern dark mode WPF interface (Slate/Sky palette) with directory browser, live KPI summary cards, sortable DataGrid, and scrolling log console.
- Added one-click action buttons for Start Organizing, Real-Time Watcher toggle, Undo last operation, and Statistics Report dashboard dialogs.
- Created `build.ps1` automated compilation script using `PS2EXE` to package `DownloadOrganizer.ps1` into a standalone `dist/DownloadOrganizerPro.exe` binary with `-noConsole` mode.
- Integrated custom application icon from `assets/app.ico`.
- Created `Run-GUI.bat` helper script for seamless double-click launching on Windows File Explorer.
- Created `docs/GUI_GUIDE.md` user guide and `docs/BUILD_GUIDE.md` executable build guide.
- Expanded Pester unit test suite to 49 passing tests across 14 module test files.

---

## [2.0.0] - 2026-07-25

### Added

#### Core & Architecture
- PowerShell entry point (`DownloadOrganizer.ps1`) supporting interactive CLI and script parameters.
- Configuration loader and validation (`modules/Config.psm1`, `modules/Validation.psm1`).
- Strongly typed domain models (`modules/Models.psm1`).
- Utility library and SHA256 checksum calculator (`modules/Utils.psm1`).

#### Scanning & Classification
- File scanner with age, size, and pattern filtering (`modules/Scanner.psm1`).
- Config-driven extension classifier (`modules/Classifier.psm1`).
- Priority-weighted keyword smart classifier (`modules/SmartClassifier.psm1`).
- SHA256 duplicate file detector (`modules/DuplicateDetector.psm1`).

#### File Operations & Safety
- Transaction-logged safe file mover (`modules/Mover.psm1`).
- Transaction manifest undo engine (`modules/Undo.psm1`).
- Real-time `FileSystemWatcher` folder monitor (`modules/Watcher.psm1`).
- Windows Scheduled Task integrator (`modules/Scheduler.psm1`).

#### Reporting & Logging
- File logging system (`modules/Logger.psm1`).
- Execution summary metrics (`modules/Summary.psm1`).
- Standalone HTML dashboard, CSV, and JSON report generator (`modules/ReportGenerator.psm1`).

#### Documentation & Testing
- Full architectural suite (`PRD.md`, `ARCHITECTURE.md`, `CONFIGURATION.md`, `STYLEGUIDE.md`, `TESTING.md`).
- Pester 3.4+ / v5 unit test suite (13 test files) and end-to-end integration runner (`tests/run_test.ps1`).

---

## Planned

### Version 3.0 (Phase 8 — Intelligence & Cloud)
- Local Offline AI classification engine (`modules/AIClassifier.psm1` via Ollama REST API).
- Windows Media OCR image & document text recognition (`modules/OCREngine.psm1`).
- Dynamic Plugin System (`plugins/` module loader).
- Interactive Duplicate Purge & Cleaner Utility.
- Cloud sync folder integration (`OneDrive`, `Google Drive`).

---

## Versioning Policy

Version numbers follow **MAJOR.MINOR.PATCH** (SemVer):
- **MAJOR**: Breaking architectural changes.
- **MINOR**: New features without breaking compatibility.
- **PATCH**: Bug fixes, optimizations, and documentation updates.
