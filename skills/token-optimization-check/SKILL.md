---
name: token-optimization-check
description: Audits the current repository for compliance with GitHub Copilot token-optimization rules. Use when asked to check, audit, score, or review a repo for token efficiency, copilot-instructions size, AGENTS.md bloat, MCP overhead, or always-on context cost.
license: MIT
---

# Token Optimization Check

Audits the current repo against the GitHub Copilot token-optimization ruleset and reports concrete violations with file paths, line counts, estimated token cost, and fix suggestions.

## When to use

- User asks: "check token optimization", "audit copilot costs", "is this repo token efficient", "review copilot-instructions", "AGENTS.md too big", "MCP overhead check".
- After adding/editing `.github/copilot-instructions.md`, `AGENTS.md`, `CLAUDE.md`, `.vscode/mcp.json`, or `.copilot/` config.
- Before publishing a template repo or onboarding new contributors.

## Rules checked

Rule IDs map to the token-optimization guide. Each finding = rule ID + severity + path + evidence + fix.

### R1 — Always-on context size (HIGH)
- Files: `.github/copilot-instructions.md`, `AGENTS.md`, `CLAUDE.md`, `.cursorrules`, `.github/instructions/**/*.md`
- Limits:
  - copilot-instructions.md: ≤ 80 lines AND ≤ ~600 tokens (~2400 chars)
  - AGENTS.md / CLAUDE.md: ≤ 120 lines
- Token estimate: `chars / 4`
- Flag if any file exceeds limits.

### R2 — Duplicate always-on files (HIGH)
- If both `AGENTS.md` AND `.github/copilot-instructions.md` exist, diff them. Flag overlapping content (>30% line similarity) as "paid twice".

### R3 — Verbose / non-caveman instructions (MEDIUM)
- Scan always-on files for filler patterns:
  - Articles overload: lines starting with "The ", "A ", "An " > 20% of lines
  - Pleasantries: "please", "kindly", "feel free", "I'd like you to", "could you"
  - Hedging: "maybe", "perhaps", "might want to", "you should probably", "it's important to"
  - Filler: "just", "really", "basically", "actually", "simply"
- Flag if ≥ 3 hits across these categories.

### R4 — Discoverable / redundant facts (MEDIUM)
- Flag lines that restate what code reveals:
  - "This project uses TypeScript" when `tsconfig.json` exists
  - "We use PostgreSQL/Node/Python/etc" when manifest declares it
  - "Tests are in `tests/`" when `tests/` exists
  - "Main branch is protected" / "Repo uses Git"
- Pattern: `\b(this (project|repo) (uses|is)|we use|tests? (are|live) in)\b`

### R5 — Missing output-control directive (HIGH, single-line fix)
- Always-on files SHOULD contain at least one of:
  - "code only" / "no explanation" / "be concise" / "terse" / "bullets over paragraphs"
- If none found → flag. Suggested fix: append `Be concise. Code only for generation. No explanations unless asked.`

### R6 — MCP server bloat (HIGH)
- Files: `.vscode/mcp.json`, `.copilot/mcp-config.json`, `.mcp.json`
- Count servers. Estimate `servers × 5 tools × 200 tokens` per-step cost.
- Flag if > 5 servers configured at workspace scope (global is user's concern).
- For each server, note name + flag if obviously off-topic for the repo's language/stack.

### R7 — Open-tab / large-file risks (LOW)
- List source files > 1000 lines under `src/`, `lib/`, `app/`. These bloat auto-context when open.

### R8 — Non-English always-on content (LOW)
- Detect CJK / Cyrillic / Hebrew / Arabic characters in always-on files. CJK costs ~2x English tokens.

### R9 — Missing Conventional Commits / terse commit hint (LOW)
- If `.github/copilot-instructions.md` covers commit guidance, check for "conventional commits" or "≤50 chars" / "subject line ≤ 72".

### R10 — Wenyan / classical-Chinese prompts (LOW)
- Flag files containing dense classical Chinese markers (e.g., `之`, `也`, `矣`, `乎`) used as prompt style. Recommend terse English.

## How to use

1. Read the repo root listing. Identify which always-on files exist.
2. For each existing file, read fully and run rules R1–R5, R8, R9, R10.
3. Read MCP config files if present → run R6.
4. Scan workspace for files > 1000 lines (R7). Use file_search/grep, not full reads.
5. Compute an overall score:
   - 100 baseline
   - HIGH violation: −20
   - MEDIUM: −10
   - LOW: −3
   - Floor at 0.
6. Output a single Markdown report (see Output).

## Output

Emit ONE markdown report. No preamble, no postamble. Structure:

```markdown
# Token Optimization Audit — <repo name>

**Score:** <0–100> / 100  |  **Findings:** <H> high · <M> medium · <L> low

## Always-on context budget
| File | Lines | ~Tokens | Limit | Status |
|---|---:|---:|---|---|
| .github/copilot-instructions.md | 142 | ~980 | 80 / ~600 | ❌ Over |
| AGENTS.md | — | — | — | n/a |

## Findings

### [R1·HIGH] copilot-instructions.md exceeds size budget
- File: `.github/copilot-instructions.md` (142 lines, ~980 tokens)
- Cost: ~980 tokens × every interaction
- Fix: Compress to ≤80 lines. Drop discoverable facts. See R4 candidates below.

### [R5·HIGH] No output-control directive
- Fix: Append one line:
  ```
  Be concise. Code only for generation. No explanations unless asked.
  ```

(... one block per finding ...)

## Quick wins (apply in order)
1. <highest-ROI fix first>
2. ...

## Estimated savings if all fixes applied
- Per-interaction input: −<N> tokens
- Per agent step (tool defs): −<N> tokens
```

## Notes

- Token counts are estimates (`chars / 4`). Do not claim exact billing numbers.
- Do NOT modify any files. Report only. The user applies fixes.
- If a file is absent, omit its row rather than flagging absence (except R5).
- Keep the report itself terse. Caveman style allowed in finding text.
