# Testing Guide

**Project:** Download Organizer Pro

---

# Purpose

Testing ensures the application behaves correctly, safely, and consistently.

Every module should be testable independently.

The project uses **Pester** for automated testing.

---

# Testing Strategy

Testing is divided into four levels.

```text
Unit Tests

↓

Integration Tests

↓

End-to-End Tests

↓

Regression Tests
```

---

# Test Directory

```text
tests/

├── Unit/
│   ├── Config.Tests.ps1
│   ├── Validation.Tests.ps1
│   ├── Scanner.Tests.ps1
│   ├── Classifier.Tests.ps1
│   ├── SmartClassifier.Tests.ps1
│   ├── Mover.Tests.ps1
│   ├── Logger.Tests.ps1
│   └── Summary.Tests.ps1
│
├── Integration/
│   ├── Organizer.Tests.ps1
│   └── Workflow.Tests.ps1
│
├── Fixtures/
│   ├── Downloads/
│   ├── Expected/
│   └── Config/
│
└── TestData/
```

---

# Running Tests

Run all tests.

```powershell
Invoke-Pester
```

Run a specific test.

```powershell
Invoke-Pester .\tests\Unit\Scanner.Tests.ps1
```

---

# Unit Tests

Each module must be tested independently.

Example:

```text
Scanner

↓

Input:
Downloads Folder

↓

Output:
OrganizerFile[]
```

No other modules should be required.

---

# Integration Tests

Integration tests verify module interaction.

Example workflow:

```text
Config

↓

Validation

↓

Scanner

↓

Classifier

↓

Mover

↓

Logger

↓

Summary
```

---

# End-to-End Tests

Verify the complete application.

Scenario:

```text
Prepare Downloads Folder

↓

Run Organizer

↓

Verify Destination

↓

Verify Log

↓

Verify Summary
```

---

# Regression Tests

Regression tests ensure previously fixed bugs do not return.

Every bug fix should include a corresponding regression test.

---

# Test Data

Test files should remain small.

Recommended examples:

```text
resume.pdf

invoice.xlsx

holiday.jpg

archive.zip

setup.exe

script.ps1
```

Avoid using sensitive or personal files.

---

# Test Fixtures

Fixtures provide repeatable input.

Example:

```text
Fixtures/

Downloads/

resume.pdf

photo.jpg

setup.exe
```

Expected output:

```text
Expected/

Documents/

Images/

Applications/
```

---

# Test Naming

Use descriptive names.

Good:

```text
Scanner.Tests.ps1
```

Bad:

```text
Test1.ps1
```

---

# Test Cases

Every public function should include tests for:

- Valid input
- Invalid input
- Empty input
- Edge cases
- Error handling

---

# Example Scenarios

## Scanner

Should:

- Scan existing folder
- Ignore directories
- Return OrganizerFile objects
- Return empty collection for empty folder

---

## Classifier

Should:

- Match known extensions
- Assign "Others" to unknown extensions
- Ignore extension case

---

## Smart Classifier

Should:

- Match keywords
- Ignore case
- Respect rule priority
- Leave unmatched files unchanged

---

## Mover

Should:

- Create destination folders
- Move files
- Rename duplicates
- Skip locked files
- Return move results

---

## Logger

Should:

- Create log file
- Append entries
- Record errors
- Record successful operations

---

## Summary

Should:

- Count files correctly
- Report duration
- Report moved files
- Report failed files

---

# Assertions

Tests should verify:

- Return types
- Property values
- File existence
- Directory structure
- Log contents

---

# Mocking

Use mocks for:

- File system operations
- Time-dependent functions
- External dependencies

Keep unit tests isolated.

---

# Code Coverage

Target coverage:

| Module          | Minimum |
| --------------- | ------- |
| Config          | 90%     |
| Validation      | 90%     |
| Scanner         | 90%     |
| Classifier      | 90%     |
| SmartClassifier | 90%     |
| Mover           | 90%     |
| Logger          | 85%     |
| Summary         | 85%     |

Overall target:

```text
90%
```

---

# Continuous Testing

Tests should run:

- Before every commit
- Before every pull request
- Before every release

---

# Manual Testing Checklist

Before release:

- [ ] Configuration loads
- [ ] Validation passes
- [ ] Scanner works
- [ ] Classification works
- [ ] Smart Rules work
- [ ] Files move correctly
- [ ] Duplicate handling works
- [ ] Logs generated
- [ ] Summary displayed
- [ ] No unexpected exceptions

---

# Performance Testing

Recommended scenarios:

| Files  | Expected Result        |
| ------ | ---------------------- |
| 100    | Instant                |
| 1,000  | Smooth                 |
| 5,000  | Stable                 |
| 10,000 | Acceptable performance |

Monitor:

- Execution time
- Memory usage
- Error rate

---

# Definition of Test Complete

Testing is considered complete when:

- All automated tests pass.
- Manual checklist is complete.
- No critical defects remain.
- Regression tests pass.
- Code coverage target is met.
- Documentation reflects current behavior.
