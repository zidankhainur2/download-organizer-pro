# Configuration Guide

**Project:** Download Organizer Pro

---

# Overview

Download Organizer Pro is fully configuration-driven.

Application behavior is controlled through:

```text
config.json
```

No source code modifications should be required for normal customization.

---

# Configuration Structure

```json
{
  "Settings": {},
  "Categories": {},
  "SmartRules": {}
}
```

---

# Settings

Application-level settings.

Example:

```json
{
  "Settings": {
    "DownloadsPath": "%USERPROFILE%\\Downloads",
    "CreateMissingFolders": true,
    "OverwriteExisting": false,
    "RenameDuplicates": true,
    "GenerateLog": true,
    "ShowSummary": true
  }
}
```

---

## DownloadsPath

Directory to organize.

Example:

```json
"%USERPROFILE%\\Downloads"
```

Environment variables are supported.

Examples:

```text
%USERPROFILE%

%TEMP%

%HOMEDRIVE%
```

---

## CreateMissingFolders

Automatically create destination folders.

Type:

```text
Boolean
```

Example:

```json
true
```

---

## OverwriteExisting

Allow overwriting existing files.

Type:

```text
Boolean
```

Default:

```json
false
```

---

## RenameDuplicates

Automatically rename duplicate filenames.

Type:

```text
Boolean
```

Example:

```json
true
```

---

## GenerateLog

Create a log file after execution.

Type:

```text
Boolean
```

---

## ShowSummary

Display execution summary.

Type:

```text
Boolean
```

---

# Categories

Defines extension-to-category mapping.

Example:

```json
{
  "Categories": {
    "Documents": ["pdf", "doc", "docx", "xls", "xlsx"],

    "Images": ["jpg", "jpeg", "png", "gif"],

    "Applications": ["exe", "msi"],

    "Archives": ["zip", "rar", "7z"]
  }
}
```

---

## Rules

Extensions:

- are case-insensitive
- should not include "."
- must be unique

Correct:

```json
"pdf"
```

Incorrect:

```json
".pdf"
```

---

# Smart Rules

Smart Rules perform keyword-based classification.

Example:

```json
{
  "SmartRules": {
    "CV": {
      "Category": "Documents",
      "Keywords": ["resume", "cv", "curriculum vitae"]
    }
  }
}
```

---

## Category

Target category.

Example:

```json
"Documents"
```

---

## Keywords

List of filename keywords.

Matching is case-insensitive.

Example:

```json
["resume", "cv", "portfolio"]
```

---

# Example

Filename:

```text
Resume_John.pdf
```

Evaluation:

```text
Extension

↓

Documents

↓

Keyword "resume"

↓

SubCategory = CV
```

Destination:

```text
Documents/CV
```

---

# Duplicate Handling

When a destination filename already exists:

If:

```json
"RenameDuplicates": true
```

Result:

```text
Resume.pdf

↓

Resume (1).pdf

↓

Resume (2).pdf
```

If:

```json
"OverwriteExisting": true
```

Existing file will be replaced.

If both are disabled:

File is skipped.

---

# Environment Variables

Supported in path settings.

Example:

```text
%USERPROFILE%\Downloads

%USERPROFILE%\Desktop

%TEMP%
```

Variables are expanded before validation.

---

# Validation Rules

Configuration validation checks:

- Required sections exist
- Downloads path exists
- Categories are valid
- Extensions are unique
- Smart Rules are valid
- Required settings are present

Invalid configuration stops execution.

---

# Best Practices

- Keep categories focused.
- Avoid duplicate extensions.
- Use lowercase extensions.
- Keep Smart Rules specific.
- Test configuration before production use.

---

# Common Categories

Recommended categories:

```text
Applications

Archives

Audio

Code

Documents

Fonts

Images

Others

Scripts

Videos
```

---

# Common Smart Rules

Examples:

```text
CV

Invoices

Taxes

Receipts

Screenshots

Wallpapers

Projects

Backups

Books

Courses
```

---

# Example Configuration

```json
{
  "Settings": {
    "DownloadsPath": "%USERPROFILE%\\Downloads",
    "CreateLogs": true,
    "MoveUnknownFiles": true,
    "Overwrite": false,
    "EnableSmartRules": true,
    "CreateCategoryFolders": true,
    "Verbose": false,
    "DryRun": false,
    "Recursive": false,
    "IgnorePatterns": [ "*.tmp", "*.crdownload", "desktop.ini", ".DS_Store", "*.part" ],
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

  "Categories": {
    "Documents": ["pdf", "docx", "xlsx"],
    "Images": ["jpg", "png"],
    "Archives": ["zip", "rar"],
    "Applications": ["exe", "msi"]
  },

  "SmartRules": {
    "CV": {
      "Category": "Documents",
      "Priority": 10,
      "Keywords": ["resume", "cv"]
    }
  }
}
```

---

# Future Configuration

Future versions may introduce:

- Multiple profiles
- Rule priority
- Folder templates
- Ignore patterns
- Recursive scanning
- File age rules
- Size-based rules
- Plugin configuration

Backward compatibility will be maintained whenever possible.
