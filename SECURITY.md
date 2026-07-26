# Security Policy

## Supported Versions

The following versions currently receive security updates.

| Version | Supported |
| ------- | --------- |
| 2.x     | ✅ Yes    |
| 1.x     | ❌ No     |

---

# Reporting a Security Vulnerability

Please **do not** report security vulnerabilities through public GitHub Issues.

Instead, contact the project maintainer privately with the following information:

- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested mitigation (if available)
- Proof of concept (optional)

Reports should include enough information to reproduce the issue.

---

# Scope

This project primarily interacts with the local file system.

Security considerations include:

- File movement
- Directory creation
- Configuration loading
- Log generation
- Path handling

---

# Security Goals

Download Organizer Pro is designed to:

- Never delete user files
- Never modify file contents
- Never overwrite files unless explicitly enabled
- Never execute downloaded files
- Never transmit user data
- Never require administrator privileges for normal operation

---

# Safe Defaults

The application follows secure defaults.

Examples:

- Unknown files remain categorized as `Others`
- Missing directories are created only inside the configured destination
- Invalid configuration stops execution
- Failed file operations are logged instead of ignored

---

# Configuration Security

The application validates configuration before execution.

Validation includes:

- Configuration file format
- Required settings
- Category definitions
- Smart Rules
- Download path existence

Invalid configuration prevents execution.

---

# File System Safety

The organizer will:

- Move files only
- Preserve original filenames whenever possible
- Automatically resolve filename conflicts
- Preserve file metadata whenever supported by the operating system

The organizer will **not**:

- Delete files
- Encrypt files
- Compress files
- Execute files
- Modify file contents

---

# Logging

Logs may contain:

- File names
- Categories
- Destination paths
- Error messages
- Execution timestamps

Logs do **not** contain:

- File contents
- Passwords
- Authentication tokens
- Network credentials

Users are responsible for protecting log files if filenames are considered sensitive.

---

# Dependencies

The project aims to minimize external dependencies.

Current goals:

- Native PowerShell
- Native .NET APIs
- No external executables
- No internet connection required

---

# Threat Model

Potential risks considered:

- Invalid configuration
- Locked files
- Permission errors
- Filename collisions
- Unexpected directory structures

Out of scope:

- Malware detection
- Antivirus functionality
- Data recovery
- Secure file deletion

---

# Responsible Disclosure

Security reports will be:

1. Acknowledged as soon as practical.
2. Investigated by the maintainer.
3. Fixed when confirmed.
4. Documented in the release notes when appropriate.

---

# Best Practices for Users

Before running the organizer:

- Review your `config.json`.
- Test with a small set of files.
- Keep regular backups of important data.
- Verify destination folders.
- Review generated logs after execution.

---

# Security Philosophy

Download Organizer Pro follows a conservative approach:

- Validate first
- Fail fast
- Never assume user input is valid
- Prefer explicit configuration
- Preserve user data whenever possible
- Avoid destructive operations by default
