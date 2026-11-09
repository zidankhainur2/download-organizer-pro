# Portable build

Run `powershell.exe -NoProfile -File .\build.ps1` on Windows with the .NET Framework C# compiler installed. Build reads the version from DownloadOrganizerPro.psd1, compiles assets/Launcher.cs to a new unique executable, checks the compiler exit code and nonempty output, then replaces the previous launcher. A failed compile cannot pass by finding an old executable.

For a release, run `powershell.exe -NoProfile -File .\package.ps1`. It builds the launcher, then stages only runtime scripts, modules, XAML, configuration, license, changelog and release notes in a GUID directory under `.tools/release-build/`. The existing dist folder and its logs/recovery data are preserved. Staging is checked and removed after creating:

```text
dist/DownloadOrganizerPro-2.2.0-portable.zip
dist/DownloadOrganizerPro-2.2.0-portable.zip.sha256
dist/DownloadOrganizerPro-2.2.0-release.json
```

Distribute those three files. Do not ZIP an existing dist folder: it can contain logs or recovery data from previous use. The archive extracts to:

```text
DownloadOrganizerPro-2.2.0-portable/
  DownloadOrganizerPro.exe
  DownloadOrganizer.ps1
  DownloadOrganizerPro.psd1
  DownloadOrganizerPro.psm1
  config.json
  modules/
  assets/OrganizerWindow.xaml
  LICENSE
  CHANGELOG.md
  RELEASE_NOTES.md
  README.txt
```

This is a portable package with a C# launcher. It still requires Windows PowerShell and the companion files. Double-clicking opens the GUI; arguments are forwarded to the script. The GUI mutex is Local and does not prevent silent runs. The worker exit code becomes the launcher exit code.

After packaging, run `.\tests\Smoke-Package.ps1 -PackagePath .\dist\DownloadOrganizerPro-2.2.0-portable.zip` under each PowerShell engine. It verifies SHA256, exact ZIP and manifest contents, payload hashes and source hashes, extracts into a workspace with spaces/metacharacters, exercises silent organization while the GUI mutex is held, and checks content restoration through Undo. Unexpected archive paths are rejected before extraction. Folder-mode smoke remains available for development builds.

The release manifest identifies the archive and every payload/source file by hash. A checksum is an integrity check, not a publisher signature; this build is unsigned. Consumers can compare `Get-FileHash .\DownloadOrganizerPro-2.2.0-portable.zip -Algorithm SHA256` with the sidecar. All companion files are required, and the destination must be writable for config, logs and recovery data.

CI runs tests on both Windows engines, packages and smoke-tests the ZIP, and uploads the three release files from the Windows PowerShell job. Publication still requires both engine jobs to succeed for the final source commit. The workflow does not tag or publish a GitHub Release automatically. Interactive verification is recorded in [RELEASE](RELEASE.md); future GUI/UI and installer work is not a gate for this portable release.
