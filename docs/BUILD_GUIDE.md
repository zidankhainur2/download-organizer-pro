# Executable Build Guide

**Download Organizer Pro v2.1.0** includes an automated build pipeline (`build.ps1`) to compile the PowerShell codebase into a standalone Windows executable (`dist/DownloadOrganizerPro.exe`) with a custom application icon (`assets/app.ico`).

---

## Prerequisites

- Windows 10 / 11 / Server
- PowerShell 5.1 or newer
- `ps2exe` PowerShell module (automatically installed by `build.ps1` if not present)

---

## How to Build

Run `build.ps1` in PowerShell:

```powershell
.\build.ps1
```

The build script will perform the following steps:
1. Verify and install the `ps2exe` module if required (`Install-Module ps2exe`).
2. Create the output directory `dist/`.
3. Copy external `config.json` into `dist/config.json`.
4. Copy `assets/app.ico` into `dist/app.ico`.
5. Execute `Invoke-PS2EXE` with `-noConsole` flag to produce a pure WPF desktop executable without a CMD terminal window.
6. Generate user instructions in `dist/README.txt`.

---

## Output Package (`dist/`)

```text
dist/
├── DownloadOrganizerPro.exe   # Standalone Windows GUI Executable
├── config.json                 # External Configuration File
├── app.ico                     # Application Icon
└── README.txt                  # User Instructions
```

---

## Testing the Build

To test the compiled executable, navigate to the `dist/` directory and double-click `DownloadOrganizerPro.exe`:

```powershell
cd dist
.\DownloadOrganizerPro.exe
```

The WPF Desktop GUI will open instantly with zero background terminal windows.
