# Configuration

`config.json` has three sections: `Settings`, `Categories`, and `SmartRules`. Paths expand Windows environment variables before validation. `-DownloadsPath` overrides the configured folder before it is checked, so a nonexistent default Downloads folder does not prevent using another folder.

The following is a complete example. Replace the path with an existing directory (tests substitute their sandbox).

```json
{
  "Settings": {
    "DownloadsPath": "%USERPROFILE%\\Downloads",
    "CreateLogs": true,
    "MoveUnknownFiles": true,
    "Overwrite": false,
    "ConflictAction": "Rename",
    "EnableSmartRules": true,
    "EnableDuplicateDetection": true,
    "CreateCategoryFolders": true,
    "Verbose": false,
    "DryRun": false,
    "Recursive": false,
    "IgnorePatterns": ["*.tmp", "*.crdownload", "*.part"],
    "MinAgeDays": 0,
    "MaxAgeDays": 0,
    "MinSizeBytes": 0,
    "MaxSizeBytes": 0,
    "WatcherDebounceSeconds": 3,
    "ScheduleIntervalMinutes": 60,
    "ExportCSV": false,
    "ExportJSON": false,
    "ExportHTML": false
  },
  "Categories": {"Documents": ["pdf", "txt"], "Images": ["png"], "Others": []},
  "SmartRules": {
    "Documents": {"Finance": {"Priority": 90, "Keywords": ["invoice", "annual report"]}}
  }
}
```

| Setting | Behavior |
|---|---|
| DownloadsPath | Existing directory to organize. |
| CreateLogs | Write daily operational logs. Safety transactions and requested reports are independent. |
| MoveUnknownFiles | When false, skip unmatched extensions instead of moving them to Others. |
| CreateCategoryFolders | When false, skip destinations whose folder does not exist. |
| ConflictAction | Optional Rename, Skip, or Overwrite. Explicit CLI parameter takes precedence, then this setting, then legacy Overwrite=true, otherwise Rename. |
| Overwrite | Legacy boolean fallback. Overwrite always retains a recoverable backup. |
| EnableSmartRules | Enable category-scoped keyword subfolders. |
| EnableDuplicateDetection | Default true; flag extra SHA256 copies, including empty files. Hash failures never prove duplication. |
| DryRun | Compute destinations and report Planned without file moves or safety artifacts. |
| Recursive | Scan descendants without following reparse points or operational folders. |
| IgnorePatterns | Filename wildcard patterns; ignored downloads can become eligible when renamed. |
| MinAgeDays / MaxAgeDays | Last-write age bounds; zero disables each bound. |
| MinSizeBytes / MaxSizeBytes | File length bounds; zero disables each bound. |
| Verbose | Verbose diagnostics; explicit -Verbose or -Verbose:$false wins. |
| WatcherDebounceSeconds | Positive integer quiet/stability interval. |
| ScheduleIntervalMinutes | Positive integer repetition interval for current-user task registration. |
| ExportCSV / ExportJSON / ExportHTML | Write complete result reports, including duplicate flags and hashes when available. |

CLI switches explicitly supplied to a script invocation override the corresponding configuration boolean. In a PowerShell session, `-DryRun:$false` can disable a configured DryRun. Windows PowerShell 5.1 `powershell.exe -File` does not support every explicit switch boolean form; edit the configuration or invoke the script within a session for that case.

Categories and subcategories must be single Windows directory components: no traversal, separators, absolute paths, illegal characters, device names, or trailing dots/spaces. Extensions are simple extension strings, without filename wildcards. Smart rules match words in the filename stem after separator normalization. Score is matching keyword count multiplied by Priority; equal scores preserve declaration order. A rule under Documents cannot classify an Images file.

Application data lives beside the entrypoint in `logs/`; module callers choose `OperationalPath` explicitly. Do not place ordinary downloads inside operational directories. Logs contain original filenames and destination paths.
