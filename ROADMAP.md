# Roadmap

This document outlines the development plan and completed milestones for Download Organizer Pro.

---

# Vision

Build a professional, modular, and extensible PowerShell file organizer that is fast, safe, configurable, maintainable, well documented, and AI-assisted development friendly.

---

# Current Status

**Current Version**: `2.1.0 (Desktop Edition & Executable Build Pipeline)`  
**Test Suite Coverage**: 100% Core Engine & GUI Modules (49 Pester unit tests passing).

---

# Version 2.0.0 (Completed)

## Core Engine & Architecture (Phase 1 - Phase 3)
- [x] Project architecture & documentation design
- [x] Configuration system & strict JSON schema validation
- [x] Domain models (`OrganizerFile`, `OrganizerSummary`)
- [x] Directory scanner engine (`Scanner.psm1`)
- [x] Extension classification engine (`Classifier.psm1`)
- [x] Keyword smart rules engine (`SmartClassifier.psm1`)
- [x] File mover with duplicate renaming (`Mover.psm1`)
- [x] Logger (`Logger.psm1`)
- [x] Summary metrics calculator (`Summary.psm1`)
- [x] 100% Pester unit test suite & integration runner

## Advanced Features (Phase 4)
- [x] Duplicate detection pre-filtering by file size
- [x] SHA256 checksum comparison (`DuplicateDetector.psm1`)
- [x] Undo operation with JSON transaction log manifests (`Undo.psm1`)
- [x] Dry Run simulation mode (`-DryRun`)
- [x] Wildcard ignore pattern filtering (`*.tmp`, `*.crdownload`, `desktop.ini`, `.DS_Store`)
- [x] Recursive folder scanning (`-Recurse`)
- [x] File age (`MinAgeDays`/`MaxAgeDays`) & size (`MinSizeBytes`/`MaxSizeBytes`) filtering rules

## Automation (Phase 5)
- [x] Real-time folder watcher with debouncing (`Watcher.psm1`)
- [x] Windows Scheduled Task support (`Scheduler.psm1`)
- [x] Silent mode (`-Silent`) & hidden background execution (`-Background`)

## Reports & Statistics (Phase 6)
- [x] CSV report export (`Export-OrganizerCSV`)
- [x] JSON report export (`Export-OrganizerJSON`)
- [x] Modern dark mode HTML dashboard report (`Export-OrganizerHTMLReport`)
- [x] Historical statistics aggregation (`Get-OrganizerStatistics`)

---

# Version 2.1.0 (Completed — Phase 7)

## WPF Desktop GUI & Standalone Executable Pipeline
- [x] Native WPF XAML Interface Layout (`modules/GUI.psm1`) with Slate/Sky dark mode palette
- [x] Target Folder Browser & Options Checkboxes
- [x] One-Click Action Buttons (Start, Watcher, Undo, Stats Report)
- [x] Live KPI Summary Cards & Sortable Results DataGrid
- [x] Real-Time Log Console Output Window
- [x] Automatic GUI launcher (`.\DownloadOrganizer.ps1 -GUI`)
- [x] One-Click Windows Batch Launcher (`Run-GUI.bat`)
- [x] Automated PS2EXE Executable Compiler script (`build.ps1`) with `-noConsole` mode
- [x] Custom Application Icon integration (`assets/app.ico`)
- [x] Standalone distribution package (`dist/DownloadOrganizerPro.exe`)
- [x] Desktop GUI & Build Guides (`docs/GUI_GUIDE.md`, `docs/BUILD_GUIDE.md`)

---

# Version 3.0.0 (Phase 8 — Future)

## Goals
Transform Download Organizer Pro into an AI-assisted, offline-first intelligent file platform.

### Planned Features
- [ ] Offline Local AI classification engine (Ollama REST API integration at `http://localhost:11434`)
- [ ] Windows Media OCR text extraction for scanned images & documents (`Windows.Media.Ocr`)
- [ ] Dynamic Plugin Engine (`plugins/` module loader)
- [ ] Interactive Duplicate Purge & Cleaner Utility
- [ ] Cloud sync folder integration (OneDrive, Google Drive)

---

# Documentation & Quality Checklist

- [x] Complete README with usage examples & badges
- [x] Complete Architecture Guide (`docs/ARCHITECTURE.md`)
- [x] Complete Configuration Guide (`docs/CONFIGURATION.md`)
- [x] Complete Development Guide (`docs/DEVELOPMENT.md`)
- [x] Complete Style Guide (`docs/STYLEGUIDE.md`)
- [x] Complete Testing Guide (`docs/TESTING.md`)
- [x] Complete GUI User Guide (`docs/GUI_GUIDE.md`)
- [x] Complete Build Guide (`docs/BUILD_GUIDE.md`)
- [x] Continuous Integration workflow (`.github/workflows/ci.yml`)
- [x] Repository issue and pull request templates
