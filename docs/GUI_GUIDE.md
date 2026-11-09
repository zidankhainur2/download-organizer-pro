# Desktop GUI

Launch `Run-GUI.bat`, `DownloadOrganizerPro.exe`, or `powershell.exe -STA -File .\DownloadOrganizer.ps1 -GUI`. An interactive script invocation with no arguments also opens the GUI.

The folder field expands environment variables. Smart rules, DryRun, recursion, HTML, and CSV checkboxes initialize from configuration; they override settings for that run. Start runs the same pipeline as the CLI in a background STA runspace. Controls that could conflict are disabled until completion; progress and results appear through the UI dispatcher.

KPI cards show scanned files, real moves, failures, and total size. The console summary also shows Skipped, Planned, and duplicate counts. The results grid flags duplicate files and displays at most 500 rows. Exported reports include every result. DryRun rows are Planned and never increment real move/failure statistics.

Start Watcher monitors the selected folder using the loaded configuration path; Stop Watcher removes subscriptions and its timer. Automation uses the configuration file's settings, while the folder selection is passed explicitly. Schedule toggles the current-user DownloadOrganizerPro task using ScheduleIntervalMinutes and the selected folder. Errors are displayed in the console.

Undo restores the latest incomplete transaction, including overwrite backups, and reports source conflicts without replacing existing files. Closing waits for any active GUI transaction to finish, then disposes its runspace. A previously launched watcher worker can finish safely after monitoring stops.

Interactive visual checks remain required before release: resize, keyboard navigation, checkbox defaults, responsiveness with 10,000 files, watcher toggling, closing during a transaction, and conflict/error messages. Automated WPF checks run in STA and do not substitute for these visual checks.
