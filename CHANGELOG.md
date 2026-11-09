# Changelog

All notable changes to this project will be documented in this file.

The format is based on **Keep a Changelog**.
This project follows **Semantic Versioning (SemVer)**.

---

## [2.2.0]

The portable release scope is complete. GUI/UI redesign and installation tooling belong to a later version. Publication status and verification evidence are recorded in docs/RELEASE.md.

- Added shared CLI/GUI orchestration, category-scoped smart rules, retained duplicate flags, and consistent Planned/Moved/Skipped/Failed outcomes.
- Added validated literal paths, per-folder locking, durable transaction intent/progress, backed-up overwrite, and retryable partial Undo with legacy manifest support.
- Repaired Created/Renamed watcher context and cleanup; replaced expression-based scheduling with current-user ScheduledTasks and CLI/GUI controls.
- Moved GUI execution to a background STA runspace and extracted its XAML. Portable C# launcher now forwards arguments, isolates the GUI mutex, and checks fresh compiler output.
- Pinned Pester 5.7.1, isolated fixtures and scheduler mocks, and added safety/integration/package/benchmark verification. See docs/RELEASE.md for remaining gates.
- Fixed watcher workers remaining active after Stop, PowerShell 7 module paths breaking Windows PowerShell workers, clipped action buttons on resize, and missing locked-file reasons in the GUI console.
- Added a clean versioned portable ZIP, SHA256 sidecar, payload/source manifest, bundled license/release notes, and archive smoke checks. Existing logs, transactions, backups, tests and local verification fixtures are excluded from the download.

## [2.1.1] - 2026-07-27

### Fixed
- **GUI Stability**: Removed `Write-Progress` UI rendering calls from the Mover module to prevent catastrophic console host crashes when processing thousands of files in background/hidden WindowStyle.
- **WPF Performance**: Implemented a hard limit of 500 maximum rendering items on the GUI Results DataGrid. This prevents WPF `OutOfMemoryException` and extreme UI freezing when binding massive collections of moved files synchronously.
- **Classification Engine**: Fixed a parameter binding bug that crashed the application when attempting to classify files that have no extension (empty string error). Added `[AllowEmptyString()]` attribute to `Find-CategoryByExtension`.
- **CI/CD Pipeline**: Updated GitHub Actions `.github/workflows/ci.yml` Pester execution parameters to be position-based (`-Script` to `-Path` equivalent) to guarantee cross-compatibility between Pester v4 (Local) and Pester v5 (GitHub Actions windows-latest).
- **Git Ignore Rules**: Fixed `.gitignore` to completely exclude the compiled output directory (`dist/`) and all log files (`logs/`) from version control tracking.

---

## [2.1.0] - 2026-07-26

### Added

#### Desktop GUI & Executable Release
- Added `modules/GUI.psm1` providing a native WPF Desktop Graphical User Interface (`Show-OrganizerGUI`, `New-OrganizerWindow`).
- Designed modern dark mode WPF interface (Slate/Sky palette) with directory browser, live KPI summary cards, sortable DataGrid, and scrolling log console.
- Added one-click action buttons for Start Organizing, Real-Time Watcher toggle, Undo last operation, and Statistics Report dashboard dialogs.
- Created native `build.ps1` automated compilation pipeline using Windows C# compiler (`csc.exe`) to package `DownloadOrganizer.ps1` into a clean, single-instance `dist/DownloadOrganizerPro.exe` Win32 binary (`/target:winexe`).
- Embedded custom Win32 application icon from `assets/app.ico` into executable binary headers.
- Implemented Global Win32 Single-Instance Mutex (`DownloadOrganizerPro_SingleInstance_Mutex`) in launcher C# binary to eliminate duplicate process queuing.
- Resolved WPF window teardown loop by allowing natural `ShowDialog()` exit without forced process termination.
- Created `Run-GUI.bat` helper script for seamless double-click launching on Windows File Explorer.
- Created `docs/GUI_GUIDE.md` user guide and updated `docs/BUILD_GUIDE.md` executable build guide.
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

### After 2.2.0

- GUI/UI and logo redesign.
- Data-location, permissions and application lifecycle work.
- Installer/uninstaller, upgrade handling and retention of recovery data.
- Distribution testing and limited beta for those changes. Version numbers will be decided separately.

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
