# Style Guide

**Project:** Download Organizer Pro

---

# Purpose

This document defines the coding standards used throughout the project.

All source code should follow these guidelines to ensure consistency, readability, and maintainability.

---

# General Principles

Code should be:

- Simple
- Readable
- Predictable
- Maintainable
- Testable

Prefer clarity over cleverness.

---

# PowerShell Version

Minimum supported version:

```text
PowerShell 5.1
```

All code must remain compatible with PowerShell 5.1 unless otherwise documented.

---

# File Encoding

Use:

```text
UTF-8
```

Line endings:

```text
LF
```

---

# Indentation

Use:

```text
4 spaces
```

Do not use tabs.

---

# Line Length

Recommended maximum:

```text
120 characters
```

Break long pipelines across multiple lines.

Example:

```powershell
$files |
    Set-FileCategory `
        -Categories $config.Categories |
    Move-OrganizerFiles
```

---

# Naming Conventions

## Functions

Use:

```text
Verb-Noun
```

Examples:

```powershell
Get-DownloadFiles

Move-OrganizerFiles

Write-OrganizerLog

Show-OrganizerSummary
```

---

## Variables

Use:

```text
camelCase
```

Example:

```powershell
$config

$downloadPath

$classifiedFiles

$logFile
```

Avoid abbreviations.

---

## Classes

Use:

```text
PascalCase
```

Example:

```text
OrganizerFile

OrganizerSummary
```

---

## Methods

Use:

```text
PascalCase
```

Example:

```powershell
SetCategory()

MarkMoved()

MarkFailed()
```

---

## Constants

Use:

```text
UPPER_CASE
```

Only for true constants.

---

# Approved Verbs

Always use approved PowerShell verbs.

Examples:

```text
Get

Set

New

Move

Write

Show

Test

Invoke

Remove

Clear
```

Avoid custom verbs.

---

# Functions

Every public function should include:

- CmdletBinding
- Parameter validation
- Comment-Based Help
- Meaningful output
- Error handling

Example:

```powershell
function Get-DownloadFiles {

    [CmdletBinding()]

    param()

}
```

---

# Parameters

Always validate input.

Examples:

```powershell
[ValidateNotNullOrEmpty()]
```

```powershell
[ValidateSet()]
```

```powershell
[ValidateRange()]
```

---

# Pipeline

Support pipeline input whenever appropriate.

Preferred:

```powershell
Get-DownloadFiles |
Set-FileCategory |
Move-OrganizerFiles
```

---

# Objects

Prefer strongly typed classes.

Preferred:

```powershell
OrganizerFile
```

Avoid:

```powershell
PSCustomObject
```

unless there is a specific reason.

---

# Comments

Comment why.

Do not comment obvious code.

Good:

```powershell
# Skip hidden files to avoid processing system artifacts.
```

Bad:

```powershell
# Increment counter.
$counter++
```

---

# Regions

Use regions only for large modules.

Example:

```powershell
#region Private Functions

#endregion

#region Public Functions

#endregion
```

---

# Error Handling

Fatal errors:

```powershell
throw
```

Recoverable errors:

- Log
- Continue

Never suppress exceptions silently.

Avoid:

```powershell
catch {

}
```

---

# Output

Modules should return objects.

Do not use:

```powershell
Write-Host
```

inside modules.

Console output belongs in:

```text
DownloadOrganizer.ps1
```

---

# Configuration

Never hardcode:

- Paths
- Categories
- Extensions
- Keywords

Everything should come from:

```text
config.json
```

---

# Module Design

Each module should have one responsibility.

Good:

```text
Scanner

↓

Enumerate files
```

Bad:

```text
Scanner

↓

Enumerate

↓

Classify

↓

Move

↓

Log
```

---

# Function Size

Recommended maximum:

```text
80 lines
```

If a function grows significantly larger, consider extracting helper functions.

---

# Module Size

Recommended maximum:

```text
400 lines
```

Split large modules into logical units.

---

# Dependencies

Preferred order:

1. Native PowerShell
2. .NET APIs
3. External modules (only when necessary)

---

# Performance

Prefer:

- Generic Lists
- Hashtable lookups
- Single-pass processing
- Streaming pipelines

Avoid:

- Array +=
- Repeated enumeration
- Duplicate calculations

---

# Documentation

Public functions require:

- Synopsis
- Description
- Parameters
- Examples

---

# Testing

Every new feature should be testable.

Prefer small functions over complex functions.

---

# Logging

All logging should go through:

```text
Logger.psm1
```

No module should implement its own logging.

---

# Code Review Checklist

Before committing:

- [ ] Uses approved verbs
- [ ] Uses parameter validation
- [ ] No duplicated logic
- [ ] No Write-Host in modules
- [ ] Supports pipeline where appropriate
- [ ] Returns objects
- [ ] Documentation updated
- [ ] Tests updated
- [ ] Changelog updated

---

# Architecture Rule

Code should follow the existing architecture.

When in doubt:

- Extend, don't rewrite.
- Refactor carefully.
- Preserve public APIs.
- Keep modules independent.

Consistency is more valuable than cleverness.
