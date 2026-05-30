---
name: changelog-from-tags
description: >-
  Update a Dart/Flutter package's CHANGELOG.md by computing changes between the
  previous released git tag and the current branch/HEAD. Use this whenever the
  user asks to “find changes since last release tag”, “generate/update release
  notes”, “update CHANGELOG.md”, or “what changed between versions” for a
  package folder in a git repo (especially Flutter/Dart packages).
---

# changelog-from-tags

## Goal

Given a **package directory** inside a git repo, find the **previous released
version tag**, compute **what changed since that tag** (preferably scoped to the
package directory), then **update the package's `CHANGELOG.md` latest entry**
with accurate release notes.

## Assumptions

- The package is a folder in a git repo and has:
  - `pubspec.yaml`
  - `CHANGELOG.md`
- Tags in the repo follow SemVer-ish names (e.g. `2.1.7`, `2.1.7+1`,
  `2.1.7-dev.1`).

## Workflow

### 1) Identify the target package and its current version

1. Read `<package>/pubspec.yaml`.
2. Record `version:` as `currentVersion`.

### 2) Identify the “previous released version tag”

1. List tags sorted by version descending.
   - Example:
     ```sh
     git -C <package> tag --list --sort=-v:refname
     ```
2. Prefer the latest **stable** tag (no `-dev`, `-alpha`, `-beta`, `-rc`), unless
   the user explicitly requests a pre-release comparison.
3. Confirm what tag points at `HEAD` (if any). If `HEAD` is already tagged,
   your diff range should usually still be `previousTag..HEAD` (unless user asked
   for `tagA..tagB`).

### 3) Collect changes since previous tag (package-scoped)

1. Gather commit list affecting only the package directory:
   ```sh
   git -C <package> log <previousTag>..HEAD --oneline --decorate -- .
   ```
2. Gather a stat summary:
   ```sh
   git -C <package> diff --stat <previousTag>..HEAD -- .
   ```
3. If needed, inspect diffs of relevant files (e.g. `pubspec.yaml`, platform code
   folders, README).

**Optional helper (no extra dependencies):**

If you want a single command to print the scoped commits and diffstat, run:

```bat
.agents\skills\changelog-from-tags\scripts\collect_changes.cmd <path-to-package>
```

### 4) Update `CHANGELOG.md`

1. Read `<package>/CHANGELOG.md` and identify the topmost version header.
2. Decide the target section to update:
   - If the topmost section matches `currentVersion`, update that section.
   - Otherwise, add a new top section `## <currentVersion>` (or `## Unreleased`
     if the repo uses that convention) and place notes there.
3. Write release notes based on actual changes between tags:
   - Prefer user-facing impact.
   - Keep bullets concise.
   - Include PR/issue links when present in commit messages or known references.
   - Avoid guessing. If the diff only changes dependency constraints/lockfiles,
     say so.

### 5) Sanity checks

- Ensure `CHANGELOG.md` remains valid Markdown.
- Show `git diff -- <package>/CHANGELOG.md` for review.

## Output expectations

When done, report:

- Previous tag used (e.g. `2.1.7`)
- Diff range (e.g. `2.1.7..HEAD`)
- A short bullet list of what was added to the changelog
- The updated file path

## Edge cases & guidance

- **Monorepo tags:** If tags are global but package changes are scoped, always
  scope logs/diffs to the package directory (`-- .`) to avoid unrelated changes.
- **No tags:** If no tags exist, treat all history as changes and create an
  initial changelog entry.
- **Mismatch between tag and pubspec version:** If `pubspec.yaml` version is not
  newer than the latest stable tag, ask the user whether to update the existing
  top section or create a new one.