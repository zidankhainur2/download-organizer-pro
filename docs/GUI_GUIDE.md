# Desktop GUI Guide

**Download Organizer Pro v2.1.0** includes a high-performance, native Windows Presentation Framework (WPF) Desktop Graphical User Interface.

---

## Overview

The Desktop GUI provides complete visual control over file organization, real-time folder watching, undo operations, report exports, and statistics dashboards with 0ms startup overhead and zero external dependencies.

---

## How to Launch

### Option 1: Double-Click Helper (Recommended for Windows Users)
Double-click `Run-GUI.bat` in File Explorer.

### Option 2: PowerShell Terminal
Run in PowerShell terminal:
```powershell
.\DownloadOrganizer.ps1
```
Or explicitly specify the GUI flag:
```powershell
.\DownloadOrganizer.ps1 -GUI
```

---

## Interface Layout & Controls

1. **Target Folder Bar**: Displays and allows browsing (`Browse...`) for any target directory on your machine.
2. **Options Checkboxes**:
   - `Enable Smart Rules`: Applies keyword-based subcategory rules (e.g. `Resume.pdf` -> `Documents/CV`).
   - `Dry-Run Mode`: Simulates file moves without modifying files on disk.
   - `Recurse Subfolders`: Scans nested folders recursively.
   - `Export HTML Dashboard`: Generates a dark-mode interactive HTML report.
   - `Export CSV Report`: Generates structured CSV data output.
3. **One-Click Action Buttons**:
   - `▶ START ORGANIZING`: Runs full scanning, classification, and movement pipeline.
   - `⚡ START WATCHER` / `⏹ STOP WATCHER`: Toggles background real-time folder monitoring.
   - `↺ UNDO LAST MOVE`: Restores files moved during the last execution using transaction logs.
   - `📊 STATS REPORT`: Displays cumulative historical metrics dialog.
4. **KPI Summary Cards**: Live counters for **SCANNED**, **MOVED**, **FAILED**, and **TOTAL SIZE (MB)**.
5. **Results DataGrid**: Sortable table displaying file names, assigned categories, subcategories, move status, and target paths.
6. **Log Output Console**: Live scrolling log stream.
