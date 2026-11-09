# Testing and measured evidence

Use Pester **5.7.1**, Windows, and STA. CI runs both Windows PowerShell 5.1 and PowerShell 7. Imports and configuration fixtures belong in BeforeAll; tests use isolated directories and never require the user's Downloads folder.

```powershell
Install-Module Pester -RequiredVersion 5.7.1 -Scope CurrentUser -Force -SkipPublisherCheck
powershell.exe -NoProfile -STA -File .\tests\Invoke-Tests.ps1
pwsh.exe -NoProfile -STA -File .\tests\Invoke-Tests.ps1
.\tests\Invoke-Tests.ps1 -Coverage
.\tests\run_test.ps1
```

The runner rejects failed discovery/containers, failed tests, and zero discovered/executed tests. Coverage is optional and measures commands in the 18 implementation modules; it excludes child processes, launcher C#, and interactive GUI actions. Reports go to `.tools/coverage.xml` and `.tools/coverage-summary.txt`. A test count does not imply a coverage percentage.

Safety regressions compare actual contents for rename, overwrite, backup failure, journal failure, torn progress, crash recovery, source conflicts, changed destinations, partial retry, reverse-order overwrites, and legacy manifests. Classification tests cover category boundaries, words/phrases, extension exclusion, declaration ties, and pipeline input. Configuration tests exercise disabled behavior, legacy precedence, explicit Verbose overrides, and documented JSON examples.

Sandbox integration uses real Created/Renamed events with burst debounce, bracket/metacharacter paths, junction rejection, cross-process folder locks, and a background GUI worker. Unit scheduler tests mock all ScheduledTasks operations. The optional real smoke test is explicitly invoked with `.\tests\Integration\ScheduledTask.Manual.ps1`: it registers a GUID-named task with an empty temporary target, checks status, and immediately unregisters it. It must run as a normal current user with Task Scheduler access.

Run `.\package.ps1` and `.\tests\Smoke-Package.ps1 -PackagePath .\dist\DownloadOrganizerPro-2.2.0-portable.zip` to verify the actual download: SHA256 sidecar, exact allowed archive paths, manifest/source hashes and payload hashes, followed by execution in a directory with spaces/metacharacters, DryRun, argument forwarding, silent execution while the GUI mutex is held, and content restoration through Undo. Archive regressions reject a changed download and a traversal entry even with a matching checksum. Build checks a new compiler output and exit code. The original folder-mode smoke is still available for development.

For scale, run `.\tests\Measure-Organizer.ps1` in a fresh process. It creates 10,000 sandbox files with 1,000 repeating invoice names, enables recursive scanning and smart rules, records wall time and peak process working set, and asserts every file is counted and the second run changes no organized names. The Before option accepts an original modules directory for the same-machine comparison. Raw measurements are in [benchmarks](benchmarks/).

Run `powershell.exe -NoProfile -STA -File .\tests\Invoke-Verification.ps1` for both engine suites, syntax/manifest checks, clean release packaging and ZIP smoke on each engine, with source hashes and JSON evidence. The source snapshot also covers packaging inputs and the CI workflow.

Measured results and outstanding release checks are recorded in [RELEASE](RELEASE.md). Twenty GUI scenarios have successful filesystem assertions and user-confirmed observations, including resizing/keyboard navigation, large-folder progress, close during active moves, watcher/scheduler controls and error/conflict presentation. Reuse [GUI_VERIFICATION](GUI_VERIFICATION.md) when runtime changes affect those paths; automated STA parsing/worker checks alone cannot establish visual behavior.

Legacy logs may contain DryRun failures recorded as real failures. Statistics do not rewrite or infer missing historical run-start markers.
