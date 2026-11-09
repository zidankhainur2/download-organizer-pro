# Download Organizer Pro 2.2.0

This release completes the current GUI and CLI functionality: shared organization results, category-specific smart rules, duplicate flags that retain every copy, accurate DryRun previews, watcher automation, scheduled runs, and CSV/JSON/HTML reports.

Moves now use a folder lock and durable recovery journals. Overwrite retains the previous destination as a backup. Undo supports partial recovery and retry without overwriting an occupied source. Recursive runs leave correctly organized names unchanged.

The GUI runs work in a background STA runspace, limits the results table to 500 rows while reports contain all results, keeps action buttons reachable when resized, and displays a failed file's reason. Closing waits for an active transaction. Watcher Stop also waits for its current worker to finish. Launcher and background workers use compatible Windows PowerShell module paths when started from PowerShell 7.

## Portable use and upgrade

Extract the whole portable folder to a writable location and run DownloadOrganizerPro.exe. The launcher requires Windows PowerShell 5.1 and WPF; the scripts also support PowerShell 7 on Windows. Keep the executable, scripts, modules, assets and config.json together. No installer or uninstaller is included.

Before upgrading, stop the watcher and scheduled runs, then wait for active operations. Retain your configuration and the entire logs folder, including transactions, progress journals and backups. Unpack the new version separately before replacing runtime files in your existing portable folder. The package contains no user logs or recovery data and does not migrate their location.

Use DryRun first when checking a custom configuration. Free a conflicting source path before retrying Undo. Keep overwrite backups until recovery is no longer needed; they consume additional disk space. Legacy transactions without content hashes require more conservative recovery. Historical logs are not rewritten to infer missing statistics.

## Verification and scope

Windows PowerShell 5.1 and PowerShell 7 are tested with Pester 5.7.1. Functional verification includes 20 GUI scenarios observed by the user, content checks for recovery, and 10,000-file GUI runs with stable second-run filenames. Package verification checks the ZIP, checksum, payload manifest, DryRun, silent execution while GUI is open, and Undo on an extracted copy.

The SHA256 sidecar detects changed download contents; it is not a publisher signature. The executable is not Authenticode-signed.

Further GUI/UI and logo redesign, data-location and lifecycle changes, and installer/uninstaller/upgrade tooling are reserved for a later version. They are outside the 2.2.0 release scope.
