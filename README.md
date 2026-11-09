# Download Organizer Pro

A portable Windows download organizer with a WPF interface and a PowerShell CLI. Version **2.2.0** is defined in [the module manifest](DownloadOrganizerPro.psd1). Its functionality and portable package are verified locally and in [Windows CI](https://github.com/zidankhainur2/download-organizer-pro/actions/runs/42576494007), with 116 tests passing on each engine. See [release readiness](docs/RELEASE.md) for the verified download and publication status. GUI/UI redesign and installer work are reserved for later versions.

Classifies extensions and category-specific filename keywords, flags SHA256 duplicates while retaining every file, and supports recoverable moves, DryRun, watcher automation, scheduled runs, and CSV/JSON/HTML reports.

## Run

```powershell
# No arguments opens the GUI in an interactive session.
.\DownloadOrganizer.ps1 -GUI
# Organize, preview, or recover.
.\DownloadOrganizer.ps1 -Silent -DownloadsPath 'C:\My Downloads'
.\DownloadOrganizer.ps1 -DryRun -Recurse -ExportHTML
.\DownloadOrganizer.ps1 -ConfigPath '.\config.json' -ConflictAction Overwrite
.\DownloadOrganizer.ps1 -Undo
# Automation uses the selected folder and configuration.
.\DownloadOrganizer.ps1 -Watcher
.\DownloadOrganizer.ps1 -Schedule
.\DownloadOrganizer.ps1 -ScheduleStatus
.\DownloadOrganizer.ps1 -Unschedule
```

Use one mode at a time: GUI, Undo, Watcher, Report, Schedule, Unschedule, ScheduleStatus, or Background. `-Silent` organizes once without console summaries; `-Background` starts a hidden worker. `-ExportCSV`, `-ExportJSON`, and `-ExportHTML` request reports.

## File safety

The default conflict action is `Rename`; `Skip` leaves an occupied destination alone. `Overwrite` first moves the previous destination into a transaction backup. Keep `logs/transactions/` and its `backups/` intact until recovery is no longer needed. Backups need enough free space for the replaced files.

Undo returns the newly organized file to its source before restoring any overwritten destination. An occupied source or changed destination remains a reported conflict; free the conflicting path and retry. Completed manifests become `.json.undone`. Legacy JSON manifests remain readable. Recursive scanning repairs misplaced files and skips files already at their destination, operational directories, and reparse points.

DryRun reports `Planned` and uses the same destination reservations as real execution. It creates no category folders, backups, or Undo transactions. Operational logs and explicitly requested reports remain independent. Duplicate flags count additional copies after the first matching file; no duplicate is removed.

## Requirements and portable build

The launcher requires Windows PowerShell 5.1; scripts also support PowerShell 7 on Windows. WPF uses STA. Build a release download with `powershell.exe -NoProfile -File .\package.ps1`. The native .NET Framework C# compiler must be present for building.

Distribute **`dist/DownloadOrganizerPro-2.2.0-portable.zip`** with its `.sha256` sidecar and `DownloadOrganizerPro-2.2.0-release.json` manifest. The ZIP is assembled from a clean allowlist and excludes existing logs, transactions and backups. Extract the whole portable folder to a writable location. Double-click `DownloadOrganizerPro.exe` for the GUI or pass CLI arguments; its companion files must stay together. GUI instances use a local mutex; silent workers use a separate folder operation lock.

Before upgrading, stop automation and wait for active transactions. Preserve your configuration and the entire logs folder, including recovery journals and overwrite backups. Extract the new version separately before replacing runtime files. See the bundled [release notes](docs/RELEASE_NOTES_2.2.0.md). No installer or data-location migration is part of 2.2.0.

## Development and verification

```powershell
Install-Module Pester -RequiredVersion 5.7.1 -Scope CurrentUser -Force -SkipPublisherCheck
powershell.exe -NoProfile -STA -File .\tests\Invoke-Tests.ps1
pwsh.exe -NoProfile -STA -File .\tests\Invoke-Tests.ps1
.\package.ps1
.\tests\Smoke-Package.ps1 -PackagePath .\dist\DownloadOrganizerPro-2.2.0-portable.zip
```

Tests use temporary directories and mock ScheduledTasks. The separately invoked scheduler smoke test uses a unique temporary task. Archive smoke verifies the checksum, exact allowed contents and extracted file hashes before testing real execution and Undo. Current measured results and remaining release checks are in [TESTING](docs/TESTING.md) and [RELEASE](docs/RELEASE.md); test count is not code coverage.

See [configuration](docs/CONFIGURATION.md), [architecture](docs/ARCHITECTURE.md), [GUI](docs/GUI_GUIDE.md), [build](docs/BUILD_GUIDE.md), [development](docs/DEVELOPMENT.md), [requirements](docs/PRD.md), [roadmap](ROADMAP.md), and [changelog](CHANGELOG.md).
