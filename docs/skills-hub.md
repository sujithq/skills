# Skills Hub Workflow

This repository can be used as a skills hub: a place to publish local skills, curate skills found elsewhere, and give other users one install target.

## Hub Model

Use two different mechanisms depending on who owns the skill:

| Skill source | Where it lives | How it is maintained |
|--------------|----------------|----------------------|
| Skills authored in this repo | `skills/<skill-name>/SKILL.md` | Edit and release from this repository |
| Skills found in another repo | `dependencies.apm` in `apm.yml` | Refresh with `apm outdated` and `apm update` |

Keep `plugin.json` as package metadata only. Do not add a `skills` array to it; APM auto-discovers local skills from the `skills/` directory and resolves curated external skills from `apm.yml`.

## Add Your Own Skill

Create one directory under `skills/`:

```text
skills/<skill-name>/SKILL.md
```

The skill should include YAML frontmatter with at least `name` and `description`:

```markdown
---
name: example-skill
description: Describe what the skill does and when an agent should use it.
license: MIT
---

# Example Skill

Instructions for the agent go here.
```

Then add the directory to `includes` in `apm.yml` so it is part of the publish contract:

```yaml
includes:
- plugin.json
- skills/example-skill/
```

## Add a Skill Found Elsewhere

Use APM dependencies for external skills or packages. This keeps the upstream source visible and lets APM update it later.

Install an external skill into the hub manifest:

```powershell
apm install github/awesome-copilot/skills/review-and-refactor --target copilot
```

Install selected skills from a collection:

```powershell
apm install github/awesome-copilot --skill review-and-refactor --target copilot
```

Pin a version or commit when you want stable releases:

```powershell
apm install microsoft/apm-sample-package#v1.0.0 --target copilot
```

After adding external dependencies, commit both `apm.yml` and the generated `apm.lock.yaml`. The lockfile records exact commits and installed files so users get reproducible installs.

## Keep Curated Skills Up To Date

Check for stale dependencies:

```powershell
apm outdated --verbose
```

Preview updates before changing anything:

```powershell
apm update --dry-run
```

Apply updates:

```powershell
apm update --yes
```

Validate after every update:

```powershell
apm audit --ci
apm compile --dry-run
apm pack --dry-run --verbose
```

Review the diff carefully before committing. External updates can change the skills that downstream users receive.

Curated skill updates should be released just like local skill changes. After committing the updated `apm.yml` and `apm.lock.yaml`, create a new hub release so consumers can pin or upgrade to the refreshed hub state.

## How Others Use the Hub

Other users do not need to understand how the hub is assembled. They install this repository as one package and receive the skills you publish from `skills/` plus any curated external dependencies declared in `apm.yml`.

### First-Time Install

In any repository where they want the hub skills available, users can install directly from GitHub:

```powershell
apm install sujithq/skills --target copilot
```

This installs the runtime skills into `.agents/skills/`, but it also creates an `apm_modules/` cache with a full copy of the source repository. That cache can contain internal hub files such as `publish.ps1`, docs, workflows, and release scripts. Those files are not active runtime skills; they are cache/source material used by APM for reproducibility and updates.

If users want only the packaged runtime files on disk, use the packed release archive instead of direct repo install. See [Install from a Packed Bundle](#install-from-a-packed-bundle).

For a shared agent-skills layout that can be used across multiple clients, they can install to the `agent-skills` target:

```powershell
apm install sujithq/skills --target agent-skills
```

For multiple runtimes, they can pass a comma-separated target list:

```powershell
apm install sujithq/skills --target copilot,claude,cursor
```

After install, APM writes the resolved skills into that consumer repository's agent runtime folders and records the resolved commit in the consumer's `apm.lock.yaml`.

### Reproducible Install

For teams, docs, templates, and onboarding scripts, prefer a release tag:

```powershell
apm install sujithq/skills#v1.0.0 --target copilot
```

This gives consumers a stable hub version. When you publish `v1.1.0`, they can choose when to move to it instead of receiving changes unexpectedly.

### Update an Existing Consumer Repo

If a user installed an unpinned hub reference, they can preview and apply updates with:

```powershell
apm outdated --verbose
apm update --dry-run
apm update --yes
```

If they pinned a tag, they update by changing the dependency to a newer tag:

```powershell
apm install sujithq/skills#v1.1.0 --target copilot
```

Then they should validate their repository's agent context:

```powershell
apm audit --ci
```

### Install from a Packed Bundle

For offline sharing, private handoff, release artifacts, or a cleaner install without the hub source cache, use a packed bundle.

Build a bundle from this hub:

```powershell
apm pack --archive -o ./dist
```

Share the generated archive. Consumers install it from the downloaded path:

```powershell
apm install ./dist/sujithq-skills-1.0.0.tar.gz --target copilot
```

Use this path when consumers cannot reach GitHub directly, when you want to hand them the exact package artifact you tested, or when they do not want internal hub files such as release scripts cached under `apm_modules/`.

For GitHub releases, consumers can download the release artifact first:

```powershell
gh release download v1.10.0 --repo sujithq/skills --pattern "sujithq-skills-*.tar.gz"
apm install ./sujithq-skills-1.10.0.tar.gz --target copilot
```

### What Consumers Receive

Consumers receive:

- local skills listed under `skills/` and included by `apm.yml`
- curated external APM dependencies declared in `apm.yml`
- runtime files generated by APM for the target they choose
- `apm_modules/` cache files when they install directly from a Git repo

Consumers do not receive:

- `apm_modules/` when they install from a packed release archive
- `build/`, which is generated package output
- project-only files that are not part of the APM package contract

## Release the Hub

Create a new release whenever consumers should receive a new hub state:

- a local skill is added, removed, or changed
- a curated external skill is added, removed, or updated
- package metadata changes in `apm.yml` or `plugin.json`

Commit the hub change first, then run the release script:

```powershell
./publish.ps1
```

The script suggests the next semantic version from commit messages, updates `apm.yml`, `plugin.json`, and `CHANGELOG.md`, validates the APM package, creates a release archive under `dist/`, commits release metadata, tags the release, and pushes the release commit and tag.

Use an explicit version when needed:

```powershell
./publish.ps1 -Version 1.2.0
```

Preview validation without changing files:

```powershell
./publish.ps1 -DryRun
```

Pushing a `v*.*.*` tag starts the `Release APM Package` GitHub Actions workflow. The workflow rebuilds the APM archive and uploads it to the GitHub release.

### Manual Release Steps

If you do not use `publish.ps1`, perform the same steps manually.

Update `apm.yml` and `plugin.json` to the release version, then update the changelog:

```powershell
npm install -g conventional-changelog-cli
conventional-changelog -p angular -i CHANGELOG.md -s
```

Validate the package and build an archive:

```powershell
apm install --target copilot
apm audit --ci
apm compile --dry-run
apm pack --archive -o ./dist
```

Commit the release metadata and push the tag:

```powershell
git add CHANGELOG.md apm.yml plugin.json
if (Test-Path apm.lock.yaml) { git add apm.lock.yaml }
git commit -m "chore: release v1.2.0"
git tag v1.2.0
git push origin HEAD
git push origin v1.2.0
```

The generated bundle appears under `build/` for directory bundles or `dist/` for release archives. It includes `plugin.json`, local skills, curated dependencies resolved by APM, and package metadata needed by consumers.

## Rules of Thumb

- Put skills you own under `skills/`.
- Put skills you curate from elsewhere under `dependencies.apm`.
- Commit `apm.lock.yaml` when external dependencies exist.
- Do not commit `apm_modules/`; it is a local dependency cache.
- Do not put generated APM dependency output under `.agents/` or `.github/` unless it is intentionally maintained as local repo content.
- Keep `plugin.json` focused on bundle identity: name, display name, description, version, license, and author.
- Run `apm outdated` and `apm update --dry-run` before refreshing curated skills.