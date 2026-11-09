# Product requirements

Target: 2.2.0, Windows portable organizer with a PowerShell CLI and WPF GUI. Version metadata lives in [the manifest](../DownloadOrganizerPro.psd1). Release readiness is tracked in [RELEASE](RELEASE.md).

The core job is to classify downloads, move them safely, and allow users to recover both sides of an overwrite. CLI and GUI must share an effective configuration and pipeline contract. Extension categories precede category-specific filename keyword rules; equal smart scores preserve configuration order. Unknown files and missing category folders obey their respective configuration settings.

Duplicate SHA256 content is flagged and reported, including empty files, with every copy retained. Rename remains the default conflict action, with Skip and backed-up Overwrite available. DryRun reserves the same names as execution, reports Planned, and creates no move/backup/transaction artifacts. Operational logs and requested reports are independent switches.

Recursive organization must repair misplaced files without renaming correctly placed files, follow no directory reparse points, and exclude operational storage. All disk mutations use literal paths, terminating errors, validated components, and target containment. Intent must reach disk before mutation. Undo reverses move order, returns source content before restoring overwritten destinations, preserves conflicts, and records partial progress for retry. Legacy manifests remain readable.

Automation must detect Created and Renamed downloads, apply configured ignores, debounce/stabilize files, and serialize organizer/Undo work per folder. Schedules use the current logged-in user without elevation/password storage. Launcher arguments remain literal and silent workers run independently of the GUI mutex.

The GUI must remain responsive while organizing, update controls through the dispatcher, wait for active transactions on close, and show at most 500 rows while exporting all results. HTML must encode dynamic text. All outcome counts reconcile to the result count. Execution statistics count explicit run-start markers, with no automatic rewrite of ambiguous historic DryRun logs.

Acceptance requires safety regressions, sandbox integration, Windows PowerShell 5.1 and PowerShell 7 test runs, a 10,000-file same-machine benchmark with peak memory and unchanged second-run names, executable package smoke in a folder with spaces, and interactive GUI checks. Timing is measured rather than promised independently of hardware and durable backup costs.
