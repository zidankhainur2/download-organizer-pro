# Download Organizer Pro

> A professional PowerShell-based Downloads folder organizer with WPF Desktop GUI, standalone executable build pipeline, smart classification, duplicate detection, undo operations, real-time automation, HTML reporting, and modular architecture.

![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue)
![Platform](https://img.shields.io/badge/Platform-Windows-blue)
![License](https://img.shields.io/badge/License-MIT-green)
![Status](https://img.shields.io/badge/Status-v2.1.0%20Desktop-success)
![Tests](https://img.shields.io/badge/Tests-49%20Passing-brightgreen)

---

## Features

- **Native WPF Desktop GUI**: Sleek Dark Mode interface (`Show-OrganizerGUI`) with target folder browser, one-click action buttons, live KPI summary cards, sortable DataGrid, and live console stream.
- **Standalone Executable Build Pipeline (`build.ps1`)**: Compile into a single `dist/DownloadOrganizerPro.exe` binary with custom application icon (`assets/app.ico`) and zero console window overhead (`-noConsole`).
- **Categorized Organization**: Automatically organize files by extension into dedicated category folders (`Documents`, `Images`, `Archives`, `Code`, `Applications`, etc.).
- **Smart Keyword Classification**: Subcategory sorting based on priority-weighted file keyword rules (e.g. `Resume.pdf` -> `Documents/CV`).
- **SHA256 Duplicate Detection**: Pre-filters by file size and compares SHA256 checksums to flag duplicate downloads.
- **Undo Operation**: Transaction-logged move operations allow instant file restoration back to original directories.
- **Dry Run Simulation Mode**: Test classification and destination rules without altering disk content (`-DryRun`).
- **Real-Time Folder Watcher**: Automated `FileSystemWatcher` folder monitoring with file write debouncing (`-Watcher`).
- **Task Scheduler Support**: Native Windows Scheduled Task registration for automated background runs.
- **Rich HTML Dashboard Reports**: Self-contained dark mode HTML reports with KPI cards, category breakdown tables, and operation status.
- **Multi-Format Export**: Export results to CSV, JSON, or interactive HTML dashboards (`-ExportCSV`, `-ExportJSON`, `-ExportHTML`).
- **Config-Driven Architecture**: Fully customizable via `config.json` with strict schema validation.
- **100% Modular PowerShell 5.1 Codebase**: Strongly typed domain models, zero external dependencies, strict mode compliant.

---

## Quick Launch & Usage

### Option 1: Double-Click Desktop GUI (Windows Users)
Double-click `Run-GUI.bat` or run `dist/DownloadOrganizerPro.exe`.

### Option 2: PowerShell Terminal GUI
```powershell
.\DownloadOrganizer.ps1 -GUI
```

### Option 3: Command Line (CLI) Mode
```powershell
# Basic Organization Run
.\DownloadOrganizer.ps1

# Dry-Run Simulation
.\DownloadOrganizer.ps1 -DryRun

# Recursive Folder Scanning
.\DownloadOrganizer.ps1 -Recurse

# Undo Last Move Operation
.\DownloadOrganizer.ps1 -Undo

# Real-Time Folder Watcher
.\DownloadOrganizer.ps1 -Watcher

# Export HTML & CSV Reports
.\DownloadOrganizer.ps1 -ExportHTML -ExportCSV
```

### Option 4: Compile Standalone Executable
```powershell
.\build.ps1
```

---

## Folder Structure Example

**Before:**
```text
Downloads/
├── Resume_2026.pdf
├── setup_installer.exe
├── vacation_photo.jpg
├── project_backup.zip
└── financial_report.xlsx
```

**After:**
```text
Downloads/
├── Documents/
│   ├── CV/
│   │   └── Resume_2026.pdf
│   └── financial_report.xlsx
├── Applications/
│   └── setup_installer.exe
├── Images/
│   └── vacation_photo.jpg
└── Archives/
    └── project_backup.zip
```

---

## Repository Layout

```text
DownloadOrganizerPro/
├── DownloadOrganizer.ps1    # Main Entry Point (CLI & GUI Auto-Launcher)
├── Run-GUI.bat              # One-Click Windows Batch Launcher
├── build.ps1                # Automated PS2EXE Executable Compiler
├── config.json              # Application Configuration
├── assets/                  # Project Branding & App Icon (app.ico)
├── modules/                 # Modular Domain Engine (15 Modules)
│   ├── Models.psm1          # Domain Entities (OrganizerFile, OrganizerSummary)
│   ├── Utils.psm1           # Helper Functions & Hash Calculator
│   ├── Validation.psm1      # Schema & Path Validation
│   ├── Config.psm1          # Config Parser
│   ├── Scanner.psm1         # Directory Scanner & Filter
│   ├── Classifier.psm1       # Extension Classifier
│   ├── SmartClassifier.psm1  # Keyword Rule Classifier
│   ├── DuplicateDetector.psm1 # SHA256 Duplicate Detector
│   ├── Mover.psm1           # File Mover & Transaction Logger
│   ├── Logger.psm1          # Logger
│   ├── Summary.psm1         # Execution Summary Calculator
│   ├── Undo.psm1            # Transaction Manifest Undo Engine
│   ├── Watcher.psm1         # FileSystemWatcher Real-Time Monitor
│   ├── Scheduler.psm1       # Windows Task Scheduler Integrator
│   ├── ReportGenerator.psm1 # CSV, JSON & HTML Report Engine
│   └── GUI.psm1             # Native WPF Desktop GUI Module
├── tests/                   # Pester Unit & Integration Suite
│   ├── Unit/                # 14 Dedicated Unit Test Files (49 Test Cases)
│   └── run_test.ps1         # Integration Test Runner
├── docs/                    # Architectural & Design Documentation
│   ├── GUI_GUIDE.md         # Desktop GUI User Guide
│   └── BUILD_GUIDE.md       # Executable Build & Compilation Guide
├── dist/                    # Release Binary Distribution Package
└── README.md
```

---

## Requirements

- Windows 10 / 11 / Server
- PowerShell 5.1 or newer (PowerShell Core 7+ compatible)

---

## Installation & Setup

1. **Clone the repository**:
   ```powershell
   git clone https://github.com/zidankhainur2/DownloadOrganizerPro.git
   cd DownloadOrganizerPro
   ```

2. **Run Unit & Integration Tests**:
   ```powershell
   Invoke-Pester .\tests\Unit
   .\tests\run_test.ps1
   ```

3. **Launch GUI / Compile Executable**:
   ```powershell
   .\Run-GUI.bat
   .\build.ps1
   ```

---

## Documentation

Full architectural design and user guides are available in the [docs/](file:///c:/Users/zidan/Desktop/Coding/PROJEK/DownloadOrganizerPro/docs/) directory:

- [Desktop GUI User Guide (GUI_GUIDE.md)](file:///c:/Users/zidan/Desktop/Coding/PROJEK/DownloadOrganizerPro/docs/GUI_GUIDE.md)
- [Executable Build Guide (BUILD_GUIDE.md)](file:///c:/Users/zidan/Desktop/Coding/PROJEK/DownloadOrganizerPro/docs/BUILD_GUIDE.md)
- [Product Requirements Document (PRD.md)](file:///c:/Users/zidan/Desktop/Coding/PROJEK/DownloadOrganizerPro/docs/PRD.md)
- [Architecture Document (ARCHITECTURE.md)](file:///c:/Users/zidan/Desktop/Coding/PROJEK/DownloadOrganizerPro/docs/ARCHITECTURE.md)
- [Configuration Guide (CONFIGURATION.md)](file:///c:/Users/zidan/Desktop/Coding/PROJEK/DownloadOrganizerPro/docs/CONFIGURATION.md)
- [Style & Coding Standards (STYLEGUIDE.md)](file:///c:/Users/zidan/Desktop/Coding/PROJEK/DownloadOrganizerPro/docs/STYLEGUIDE.md)
- [Testing Guide (TESTING.md)](file:///c:/Users/zidan/Desktop/Coding/PROJEK/DownloadOrganizerPro/docs/TESTING.md)

---

## Contributing

Contributions are welcome! Please review [CONTRIBUTING.md](file:///c:/Users/zidan/Desktop/Coding/PROJEK/DownloadOrganizerPro/CONTRIBUTING.md) and [CODE_OF_CONDUCT.md](file:///c:/Users/zidan/Desktop/Coding/PROJEK/DownloadOrganizerPro/CODE_OF_CONDUCT.md) before opening pull requests.

---

## License

This project is licensed under the [MIT License](file:///c:/Users/zidan/Desktop/Coding/PROJEK/DownloadOrganizerPro/LICENSE) - Copyright (c) 2026 zidankhainur.
