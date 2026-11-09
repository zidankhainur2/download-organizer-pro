# Development

Target Windows PowerShell 5.1 and PowerShell 7 on Windows. Preserve exported functions and the aggregate manifest contract. Import modules without -Force; each module declares its own internal imports. Read [ARCHITECTURE](ARCHITECTURE.md), [CONFIGURATION](CONFIGURATION.md), and [STYLEGUIDE](STYLEGUIDE.md) before changes. Function/module length guidance is a recommendation; split by responsibility when that improves readability.

Keep orchestration in Invoke-Organizer and presentation in entrypoints/GUI. File mutation must retain literal paths, containment and reparse checks, non-overwriting operations, durable intent, and recoverable overwrite backups. Organizer and Undo must share the folder lock. Treat configuration and transaction paths as trust boundaries.

Use Pester **5.7.1**. Place imports/setup in BeforeAll, isolate tests in TestDrive, and mock all ScheduledTasks registration, removal, and lookup in unit tests. Run `powershell.exe -STA -File .\tests\Invoke-Tests.ps1` and the corresponding pwsh command. Discovery/container errors and zero executed tests fail the runner. `tests/run_test.ps1` remains an integration-suite entrypoint.

Run build and package smoke checks after launcher changes. Use tests/Measure-Organizer.ps1 for 10,000-file timing and peak process memory; compare separate fresh processes on the same machine. Include safety overhead and second-run result counts in the report. See [TESTING](TESTING.md) for evidence and [RELEASE](RELEASE.md) for outstanding checks.

Text files use UTF-8 and LF via .editorconfig/.gitattributes. Do not normalize binary icons or overwrite user logs to reconstruct ambiguous historic statistics.
