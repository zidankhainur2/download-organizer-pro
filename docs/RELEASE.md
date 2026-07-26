# Release Guide

**Project:** Download Organizer Pro

---

# Release Strategy

The project follows **Semantic Versioning (SemVer)**.

Version format:

```text
MAJOR.MINOR.PATCH
```

Example:

```text
2.0.0
2.1.0
2.1.1
3.0.0
```

---

# Version Rules

## MAJOR

Increment when:

- Public APIs change
- Breaking changes occur
- Architecture changes significantly

Example:

```text
2.x.x

↓

3.0.0
```

---

## MINOR

Increment when:

- New features are added
- Existing APIs remain compatible

Example:

```text
2.0.0

↓

2.1.0
```

---

## PATCH

Increment when:

- Bugs are fixed
- Documentation is updated
- Performance is improved
- Internal refactoring occurs without changing behavior

Example:

```text
2.1.0

↓

2.1.1
```

---

# Release Workflow

```text
Feature Complete

↓

Documentation Updated

↓

Tests Pass

↓

Code Review

↓

Version Updated

↓

CHANGELOG Updated

↓

Git Tag

↓

GitHub Release
```

---

# Release Checklist

## Documentation

- [ ] README updated
- [ ] CHANGELOG updated
- [ ] ROADMAP updated
- [ ] Documentation reviewed

---

## Code

- [ ] Build successful
- [ ] No debug code
- [ ] No TODO comments
- [ ] No unused functions
- [ ] No duplicated logic

---

## Testing

- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Manual tests completed
- [ ] Regression tests pass

---

## Configuration

- [ ] Example configuration updated
- [ ] Configuration validated
- [ ] New settings documented

---

## Repository

- [ ] Version updated
- [ ] Git tag created
- [ ] Release notes written
- [ ] GitHub Release published

---

# Version Locations

Update version numbers in:

```text
DownloadOrganizer.ps1

README.md

CHANGELOG.md

Git Tag

GitHub Release
```

---

# Git Tag Format

Use:

```text
v2.0.0
```

Examples:

```text
v2.0.1

v2.1.0

v3.0.0
```

---

# Commit Freeze

During release preparation:

- No new features
- Bug fixes only
- Documentation corrections
- Critical performance improvements

---

# Release Candidate

Release Candidate format:

```text
2.0.0-rc1

2.0.0-rc2
```

Purpose:

- Final testing
- Community feedback
- Bug verification

---

# Stable Release

Requirements:

- All tests pass
- No known critical issues
- Documentation complete
- Changelog complete
- Version finalized

---

# Hotfix Release

Hotfixes are used for critical issues.

Example:

```text
2.0.0

↓

2.0.1
```

Only include:

- Critical bug fixes
- Security fixes
- Data loss prevention

Do not introduce new features.

---

# Release Notes Template

```markdown
# Version X.Y.Z

## Added

-

## Changed

-

## Fixed

-

## Removed

-

## Performance

-

## Documentation

-
```

---

# Backward Compatibility

Minor and patch releases should preserve compatibility whenever possible.

Breaking changes should be reserved for major releases.

---

# Deprecation Policy

Deprecated functionality should:

- Be documented
- Remain available for at least one major version
- Provide migration guidance
- Be removed only in the next major release

---

# Post-Release

After publishing a release:

- Update ROADMAP
- Create next milestone
- Update version references
- Close completed issues
- Review community feedback

---

# Release Quality Standard

A release is considered complete when:

- Documentation is current.
- Automated tests pass.
- Manual verification is complete.
- Changelog is accurate.
- Version numbers are consistent.
- Repository is ready for public use.
