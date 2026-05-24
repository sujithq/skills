---
mode: agent
description: Internal release workflow for this skills hub. Validates the package, summarizes changes, asks for confirmation, then runs publish.ps1.
---

# Release Skills Hub

Repo-internal automation. NOT a published skill — lives outside `apm.yml` `includes:`.

## Purpose

Walk a release end-to-end for this repo:
1. Sanity-check working tree.
2. Verify every skill under `skills/` is listed in `apm.yml` includes and vice versa.
3. Update README touch points if new skills were added since last release.
4. Run APM validations.
5. Show suggested version + changed files.
6. Ask for explicit confirmation.
7. Run `./publish.ps1` (or `-DryRun` if requested).

## Steps

### 1. Working tree check
Run:
```powershell
git status --short
git log --oneline (git describe --tags --abbrev=0)..HEAD
```
- If working tree has unrelated changes → list them, ask whether to include.
- If no commits since last tag and no staged changes → stop. Nothing to release.

### 2. Skill ↔ apm.yml consistency
- List `skills/*/` directories.
- Parse `apm.yml` `includes:`.
- For each skill dir NOT in includes → flag, offer to add.
- For each include entry NOT on disk → flag, offer to remove.

### 3. README sync
For each skill in `skills/`, verify it appears in:
- README "Available skills" bullet list
- README "Install Individual Skills" code block
- README "Project Structure" tree
- README "package contract" wording (should be generic, not pinned to a count)

For any missing → propose patch, apply on confirmation.

### 4. APM validation
Run (sync, in repo root):
```powershell
apm audit --ci
apm compile --dry-run
apm pack --dry-run --verbose
```
- All must pass. If any fail → stop and report.
- Capture the pack file list. Confirm count matches `skills/` + `plugin.json`.

### 5. Version suggestion
Run:
```powershell
./suggest-version.ps1
```
Show: current tag, suggested next, reason (feat/fix/breaking).

### 6. Confirmation
Present a single summary block:
```
Release plan
------------
Current tag:    v1.10.0
Suggested:      v1.11.0  (minor: feat commits since last tag)
Skills shipped: 6  (4 existing + 2 new: token-optimization-check, token-optimization-fix)
Pack contents:  7 files
Files to commit:
  M apm.yml
  M README.md
  A skills/token-optimization-check/SKILL.md
  A skills/token-optimization-fix/SKILL.md

Proceed?  [yes / dry-run / commit-only / abort]
```

Wait for explicit reply. Map:
- `yes` → step 7 with `./publish.ps1`
- `dry-run` → step 7 with `./publish.ps1 -DryRun`
- `commit-only` → only commit, no publish
- `abort` → stop, leave changes staged

### 7. Commit + publish
Commit message: derive from suggested bump type.
- minor → `feat: <comma-list of new skills or changes>`
- patch → `fix: <summary>`
- chore-only → `chore: <summary>`

Then:
```powershell
git add apm.yml README.md skills/
git commit -m "<message>"
./publish.ps1            # or with -DryRun
```

Echo the resulting tag + GH release URL when known.

## Safety rules

- NEVER force-push.
- NEVER `--no-verify`.
- NEVER modify `.git/` directly.
- NEVER touch `publish.ps1`, `suggest-version.ps1`, or `.github/workflows/`.
- Edits limited to: `apm.yml`, `README.md`, `skills/**/SKILL.md`, `plugin.json` (version field only).
- If `publish.ps1` exits non-zero → stop, surface its output, do not retry.

## Notes

- This prompt file is internal: kept under `.github/prompts/` so APM never packs it (`apm.yml` `includes:` lists only `plugin.json` + `skills/*/`).
- To use: in Copilot Chat type `/release-skills-hub`.
- If APM later adds prompt-file auto-discovery, add an explicit exclude in `apm.yml`.
