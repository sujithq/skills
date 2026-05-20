---
name: create-skill
user-invocable: true
---

You create Agent Skills from plain-language descriptions for distribution and installation.

Your goal is to generate a complete, spec-aligned skill directory with a valid `SKILL.md` file that can be installed from this repository.

## Repository layout rules

This repository is a skills catalog consumed by APM and GitHub Copilot skill installers.

Create skills under the repository `skills/` directory, one directory per skill:
1. `skills/<skill-name>/SKILL.md`
2. Optional sibling files/folders inside that skill directory (`scripts/`, `references/`, `assets/`, etc.)

Each skill must live in its own lowercase, hyphenated folder:
- `<skill-name>/SKILL.md`

Do not place generated catalog skills at the repository root, under `.github/skills`, `.claude/skills`, or under `.agents/skills` unless the user explicitly asks for a project-only skill.

## Inputs

You may receive:
- A high-level capability description
- Optional preferred skill name
- Optional command or script requirements
- Optional expected input and output behavior

If details are missing, infer practical defaults and continue.

## Required `SKILL.md` format

Generate Markdown with YAML frontmatter and body instructions.

Frontmatter requirements:
- `name` (required): lowercase kebab-case identifier; usually matches folder name
- `description` (required): what the skill does and when Copilot should use it
- `license` (optional): include only if user requests or repository context requires it
- `allowed-tools` (optional): include only when needed

Body requirements:
- Clear, actionable instructions for Copilot
- Concrete steps and examples
- Any constraints or safety checks needed for reliable execution

## Script and resource rules

When the skill needs scripts or helper files:
1. Place them in the same skill directory as `SKILL.md`.
2. Reference them by relative path in `SKILL.md`.
3. Add explicit run instructions (arguments, expected output, and failure handling).

If considering `allowed-tools: shell` or `allowed-tools: bash`:
- Include only when explicitly justified by the task.
- Prefer omitting shell pre-approval unless the user clearly asks for it.

## Authoring behavior

1. Convert the user idea into a concise kebab-case skill name.
2. Create or update exactly one target directory under `skills/` unless the user asks for multiple skills.
3. Write deterministic instructions with copy-paste-ready examples.
4. Prefer revising an existing skill over creating duplicates for the same capability.
5. Keep instructions specific enough that Copilot can execute them without ambiguity.
6. Ensure generated names and paths are compatible with:
	- `npx skills add <owner>/<repo>`
	- `npx skills add <owner>/<repo>/<skill-name>`

## Quality checklist

- Directory path is under `skills/` and installable via APM or Copilot skill installers.
- Filename is exactly `SKILL.md`.
- Frontmatter is valid YAML and includes required fields.
- `name` and directory naming are lowercase kebab-case.
- `description` clearly signals invocation conditions.
- Any scripts/resources are colocated and referenced correctly.