# Release 2.2.0 - ready for publication

The 2.2.0 portable release scope is complete. Local functional verification, user-confirmed GUI observations and **both remote Windows CI jobs have passed**. A clean release download from the successful CI run has also been verified locally against its committed source. The version is ready for publication; no release tag or GitHub Release has been published by this verification task. Further GUI/UI and logo redesign, data-location changes, installer/uninstaller and upgrade tooling are explicitly reserved for later versions, as recorded in [ROADMAP](../ROADMAP.md).

## Release preparation

Build the actual release download with `powershell.exe -NoProfile -File .\package.ps1`. It creates:

- `dist/DownloadOrganizerPro-2.2.0-portable.zip`
- `dist/DownloadOrganizerPro-2.2.0-portable.zip.sha256`
- `dist/DownloadOrganizerPro-2.2.0-release.json`

The ZIP contains 28 allowlisted files, including runtime companions, license, changelog, portable instructions and [consumer release notes](RELEASE_NOTES_2.2.0.md). Existing dist logs, recovery data, development sources, tests and verification fixtures are excluded. Keep the three release files together; the manifest describes the exact payload and source hashes. This is an unsigned portable distribution; checksums establish file integrity, not publisher identity.

The release gate runs **116/116 tests per engine** (Windows PowerShell 5.1 and PowerShell 7), syntax/manifest checks, clean packaging and actual ZIP smoke on both engines. Two added archive regressions reject a corrupt download and a traversal entry even with a matching checksum. ZIP smoke verifies checksum, exact paths, payload/source hashes, extraction, DryRun, silent execution with the GUI mutex held, and Undo. Module coverage remains **83.61%**. The [release preparation record](verification/release.json) records the latest gate, archive hash, byte size and provenance.

Application runtime files match the source that passed the 20-scenario GUI verification below; changes in this phase are packaging, test/CI integration and documentation. Existing functional observations are carried forward without repeating unchanged application behavior. The CI workflow now retains the verified ZIP, checksum and manifest and supports a manual run; it does not tag or publish automatically.

After user approval, the release snapshot was committed and pushed. The first run rejected matrix expressions in step-level `shell` attributes before starting any jobs. Commit `90b164b5a602d66081be1a0c72fb5eb1fa84718d` corrected the workflow by using a fixed shell and invoking each matrix engine explicitly. It changed no application runtime behavior.

### Remote Windows CI

[Run 42576494007](https://github.com/zidankhainur2/download-organizer-pro/actions/runs/42576494007), triggered by that exact source commit, completed successfully on Windows Server 2025:

| Job | Pester results | Portable build / ZIP smoke |
|---|---|---|
| test (powershell) | 116 passed, 0 failed, 0 skipped | lulus |
| test (pwsh) | 116 passed, 0 failed, 0 skipped | lulus |

The [verified portable artifact](https://github.com/zidankhainur2/download-organizer-pro/actions/runs/42576494007/artifacts/13655930752) contains the versioned ZIP, checksum sidecar and release manifest. Its artifact digest was checked after download; the inner ZIP passed smoke again under local PowerShell 5.1 and 7 against a materialized copy of the exact committed source. The three files in local dist were replaced with this CI artifact. [Remote CI evidence](verification/remote-ci.json) preserves the run, jobs, test counts, source commit and archive checksum. Text files in the commit use Git's LF normalization; the historical local gate hashes remain evidence of their original pre-commit bytes.

The source commit and package above remain the verified release inputs when later commits only update verification documentation. Publishing is a separate action: tag the reviewed source and attach the verified ZIP, checksum and manifest. GitHub emitted non-blocking Node.js 20 compatibility notices for the existing v4 actions, which ran successfully under Node.js 24; no application test failed.

## Functional verification pass on 2026-11-09

This pass started by reproducing the previous **104/104** result on both local engines, then added the isolated [GUI verification harness and checklist](GUI_VERIFICATION.md). Every session has its own runtime, configuration, downloads fixture, logs, reports, recovery journals and GUID task name. No personal Downloads or production scheduled task is a test target.

Final automated gate: **114/114** on Windows PowerShell **5.1.26100.9711** and PowerShell **7.6.9**, Pester **5.7.1**, Windows, STA. Measured module command coverage is **83.61%** (1,153/1,379 commands), excluding child processes, launcher C# and human visual behavior. Source identity includes file hashes for the uncommitted working tree; HEAD alone does not identify this tested snapshot. The checked-in [automated gate record](verification/automated.json) contains the source manifest, exact source ID and evidence directory. Parsing, manifest validation, fresh portable build and portable smoke on both engines are included in this gate.

Reproduce with `powershell.exe -NoProfile -STA -File tests/Invoke-Verification.ps1`. The runner rejects an empty discovery, failed containers/tests, or a source change during verification. Earlier development attempts that failed environment metadata collection or detected a changing source tree are retained locally and are superseded by the final record.

### Reproduced findings and fixes

| Finding | Reproduction / actual result | Fix and regression |
|---|---|---|
| Watcher stop left a worker alive | Stop reported inactive while the session's worker was still writing. | Stop waits for its owned worker to finish; integration test verifies the worker exited and completed its write. Stop may wait as long as that worker's transaction. |
| Action buttons were clipped on resize | At 800 px window width, an action extended to x=892 and Schedule was outside the client area. | The existing action panel wraps onto another line; a WPF layout regression checks all action bounds at 800 px. No redesign. |
| Windows PowerShell workers inherited incompatible PowerShell 7 modules | A real watcher started under PS7 produced a Failed report because `Get-FileHash` could not autoload. | Watcher, Background and the C# launcher remove PSModulePath from their child environment so Windows PowerShell constructs compatible defaults. Real watcher/Background tests and PS7 portable smoke cover the paths. Parent environment and public CLI/config/transaction contracts are preserved. |
| Locked-file reason was hidden in the GUI | The GUI showed Failed: 1, but the actionable reason was only in reports. | Console shows the first failed filename and reason, with reports for the full list; a real locked-file GUI regression verifies the reason and recovered controls. |
| Portable smoke released a mutex it might not own | The previous probe assumed ownership when another process already owned the GUI mutex. | Probe tracks WaitOne/abandoned ownership and releases only when owned. Portable smoke also passed while a separate public GUI launcher owned the mutex. |

The private window's TaskName now defaults to the unchanged production name and is passed through status/register/remove. The harness supplies a GUID name. Public GUI and CLI parameters remain unchanged.

### GUI scenario status

The [GUI evidence index](verification/gui.json) distinguishes filesystem assertions from human observations and links local raw evidence. A visually smooth run does not override a failed filesystem assertion. Initial manual attempts that organized an Undo fixture again, used the watcher decoy folder, omitted the feed, or closed before removing the scheduled task remain recorded as failed verification attempts, rather than application failures or passes.

| Scenario | Filesystem / automatic interaction | Human visual status |
|---|---|---|
| Empty, Single, SmartOff, UnknownOff | lulus | lulus; Single also confirms Browse, environment path and keyboard controls |
| Mixed, configuration, reports, duplicate preservation | lulus | lulus; user confirmed version, seven results, KPI, duplicate, resize and keyboard navigation |
| Rename, Skip | lulus | lulus |
| DryRun, Overwrite | lulus | lulus |
| Undo, UndoConflict, UndoRetry | lulus | lulus; repeated conflict/retry sessions used Undo directly |
| Watcher, Scheduler | lulus, including real workers and sandbox task removal | lulus; user observed successful helper sessions after earlier procedure failures |
| Unavailable, Locked, WorkerError | lulus; locked-file message regression added | lulus |
| Scale, CloseDuringWork | lulus | lulus; user explicitly identified observation of the automatic test windows |
| Public launcher, second GUI, Silent with GUI open | lulus, including second script GUI and portable smoke with another mutex owner | lulus; user confirmed the public GUI was visible and closed normally |

All **20 scenarios** now have successful filesystem evidence and explicit user observations. Helpers automate fixture feeding and button actions for several observations; Single and the recovery cases include direct user interaction. A final [read-only resource check](verification/resources.json) found **zero active session tasks and zero active verification/runtime processes** across the retained session markers. Session files remain available locally as recovery and audit evidence.

### GUI scale evidence

Fixture: 10,000 small invoice files, 1,000 repeated names across ten batches; recursive scanning, smart rules, durable transactions, operational logging and CSV/JSON/HTML reports enabled. Both sessions preserved the complete content hash multiset and filenames on the second execution; every report accounts for all 10,000 inputs and the GUI contains 500 rows.

| Measurement | Scale | Close during active worker |
|---|---:|---:|
| First organize duration (report) | 405.52 s | 407.33 s |
| Second organize duration | 108.86 s | 69.74 s |
| Second-run moved files | 0 | 0 |
| Peak host process working set | 408.15 MB | 377.00 MB |
| Estimated first feedback after sampled busy state | 630 ms | 1,112 ms |
| Maximum dispatcher sample gap, including startup | 1,944 ms | 2,243 ms |

The close session logged that it waited for the active transaction, then closed after the results were complete. Measurements are development observations with other verification work on the same machine, not a controlled benchmark or a claim of uninterrupted responsiveness. The 250 ms timer gives sampled estimates; session wall time includes GUI startup/user waiting and differs from operation duration. The older CLI benchmark below disables logging/reports, so it is not directly comparable. Runtime source hashes are recorded per GUI session; affected error and child-process paths were rerun after fixes.

Version remains **2.2.0**, pending publication. No commit, push or remote CI execution was performed during functional verification. CI must run the final source snapshot before publication. Visual identity, data-location migration, installation and uninstallation remain separate follow-up work.

## Earlier local verification on 2026-11-09

- Pester 5.7.1: **104/104 passing** on Windows PowerShell 5.1.26100.9711 and PowerShell 7.6.9 (Windows, STA), including sandbox integration.
- Measured command coverage: **79.15%**, 1,082 of 1,367 commands across 18 implementation modules. This excludes child-process execution, launcher C#, and interactive UI behavior. It is not a 100% coverage claim.
- Syntax parsing and aggregate manifest validation pass on Windows PowerShell 5.1.
- Portable launcher build and package smoke pass in a folder containing spaces, brackets, and ampersands. Smoke includes Planned DryRun results, path overrides, silent execution while the GUI mutex is held, and content restoration through Undo.
- A GUID-named real Scheduled Task was registered for the current user with Interactive/Limited settings, queried successfully, and immediately removed. Unit tests still mock every scheduler operation.

## Same-machine 10,000-file benchmark

The final Before and After runs were executed sequentially in fresh Windows PowerShell 5.1 processes on the same machine. Fixture: 10,000 small invoice files, 1,000 repeated names across ten source folders, recursion and smart rules enabled, operational logs/reports disabled. Before uses the original HEAD modules and lacks the new safety journal and integrated duplicate detection. Other development checks occurred on the machine, so these are development measurements rather than laboratory timings.

| Measurement | Before | After |
|---|---:|---:|
| First run | 100.75 s | 349.73 s |
| Second run | 81.47 s | 65.51 s |
| Files moved again on second run | 10,000 | **0** |
| Peak process working set | 262.98 MB | 332.91 MB |
| Inputs accounted for | 10,000 | 10,000 |

Raw records: [Before.json](benchmarks/Before.json), [After.json](benchmarks/After.json). The safe first run costs substantially more time and memory, including content fingerprints and per-file durable progress. Do not describe this as an overall speedup. The second run preserves every organized filename. Later path-resolution, text-encoding and presentation fixes do not change the benchmark fixture's behavior.

## Publication status

- [x] Local GUI verification: resize and keyboard navigation, progress with a large folder, close during active moves, watcher and scheduler controls, and error/conflict presentation; successful session assertions paired with user observations.
- [x] Clean release ZIP, checksum, payload manifest and release notes prepared; archive safety and extracted runtime verified locally on both engines.
- [x] Remote Windows CI: both engine jobs passed for source commit 90b164b, including 116 tests per engine, build, ZIP smoke and artifact upload; downloaded artifact reverified locally against that commit.
- [ ] Create the release tag and publish the GitHub Release with the verified files. Publication was not part of the commit/push approval.

Keep overwrite backups and transaction/progress files until recovery is no longer needed; retained destination files consume storage. Ambiguous historic DryRun logs cannot reconstruct trustworthy historical failure/run counts and are not rewritten automatically. Legacy manifests lack content fingerprints, so their recovery is necessarily more conservative.

Publish the clean versioned ZIP with its checksum and release manifest. The user extracts the entire portable folder with its C# launcher, PowerShell scripts, manifest, modules, assets and configuration. Do not publish the executable alone or an archive of a previously used dist folder.
