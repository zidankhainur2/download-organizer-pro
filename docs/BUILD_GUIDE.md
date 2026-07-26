# Executable Build Guide

**Download Organizer Pro v2.1.0** includes an automated native build pipeline (`build.ps1`) to compile the application into a standalone native Windows executable (`dist/DownloadOrganizerPro.exe`) with a custom application icon (`assets/app.ico`).

---

## Prerequisites

- Windows 10 / 11 / Server
- PowerShell 5.1 or newer
- Native .NET C# Compiler (`csc.exe` — pre-installed natively on 100% of Windows 10/11 machines)

---

## How to Build

Run `build.ps1` in PowerShell:

```powershell
.\build.ps1
```

The build script performs the following steps:
1. Locate native Windows C# Compiler (`C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe`).
2. Create output directory `dist/`.
3. Copy external `config.json` into `dist/config.json`.
4. Copy `modules/` into `dist/modules/`.
5. Copy `assets/app.ico` into `dist/app.ico`.
6. Compile native Win32 executable (`/target:winexe`) with embedded application icon (`/win32icon`).
7. Generate user instructions in `dist/README.txt`.

---

## Output Package (`dist/`)

```text
dist/
├── DownloadOrganizerPro.exe   # Native Standalone Windows GUI Executable
├── config.json                 # External Configuration File
├── app.ico                     # Application Icon
├── README.txt                  # User Instructions
└── modules/                    # Application Engine Modules
```

---

## Benefits of Native Build

- **Zero Debug Popups**: Eliminates third-party wrapper debug popups.
- **Zero Console Overhead**: Pure Win32 GUI application launch with 0ms terminal delay.
- **Clean Exit**: Process terminates instantly when the user closes the WPF window.
- **Portable**: The `dist/` directory can be zipped and run on any Windows machine.
