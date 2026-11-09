# Roadmap

The 2.2.0 implementation adds a shared CLI/GUI pipeline, recoverable overwrite transactions, partial Undo, literal path and category validation, accurate DryRun/duplicate outcomes, working automation controls, background GUI execution, and a portable launcher that forwards CLI arguments.

Release gates and measured verification are recorded in [RELEASE](docs/RELEASE.md) and [TESTING](docs/TESTING.md). A passing test count is not a coverage percentage. Earlier 2.0/2.1 milestones remain in [CHANGELOG](CHANGELOG.md).

## 2.2.0: scope frozen

Complete the current portable GUI and CLI functionality, recovery safety, automation, documentation and release packaging. The user-confirmed GUI checklist and 10,000-file recovery/second-run checks are complete. Local tests, clean ZIP verification and remaining publication gates are recorded in [RELEASE](docs/RELEASE.md).

Before publication, both Windows engine CI jobs must pass on the final source commit. CI retains the verified ZIP, SHA256 sidecar and payload manifest. Do not publish the standalone executable or archive a previously used dist folder containing logs.

## Following versions

These changes are explicitly outside 2.2.0, in this order:

1. Visual identity, logo, GUI and UI redesign.
2. Data location, access permissions and application lifecycle.
3. Installer/uninstaller, upgrades and recovery-data retention.
4. Distribution testing and limited beta for the new installation experience.

Version numbers and detailed designs will be decided separately. They do not block completion of the current portable release.
