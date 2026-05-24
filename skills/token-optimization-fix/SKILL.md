---
name: token-optimization-fix
description: Applies fixes recommended by the token-optimization-check audit. Compresses always-on context files, removes discoverable facts, adds output-control directives, prunes MCP servers, and dedupes AGENTS.md vs copilot-instructions.md. Use after running the audit or when asked to fix, compress, or optimize copilot token usage in a repo.
license: MIT
---

# Token Optimization Fix

Applies the remediations surfaced by `token-optimization-check`. Edits files in place after explicit user confirmation per change set.

## When to use

- User asks: "apply token optimization fixes", "compress copilot-instructions", "fix the audit findings", "shrink AGENTS.md", "prune MCP servers", "add output-control directive".
- Immediately after `token-optimization-check` produced findings.

## Inputs

One of:
1. Findings report from `token-optimization-check` (preferred — re-run if stale).
2. User-specified target ("just compress copilot-instructions.md", "only dedupe AGENTS.md").

If neither given → invoke logic of `token-optimization-check` first to discover findings, then proceed.

## Fix catalog

Each fix maps to a rule ID from the audit. Apply in this order (highest ROI first).

### F5 — Add output-control directive (R5)
Append to `.github/copilot-instructions.md` (create file if missing):
```
Be concise. Code only for generation. No explanations unless asked.
Bullets over paragraphs.
```
One-line, ~12 tokens, ~40–70% output savings on code tasks.

### F1 — Compress oversized always-on file (R1, R3)
Target: `.github/copilot-instructions.md`, `AGENTS.md`, `CLAUDE.md`.
Procedure per file:
1. Read full file.
2. Show user a diff preview before writing.
3. Apply transforms:
   - Drop articles: `the`, `a`, `an` when removable.
   - Drop filler: `just`, `really`, `basically`, `actually`, `simply`, `very`.
   - Drop pleasantries: `please`, `kindly`, `feel free to`, `I'd like you to`, `could you`.
   - Drop hedging: `maybe`, `perhaps`, `might want to`, `you should probably`, `it's important to`, `make sure to`.
   - Collapse multi-sentence prose into fragments: `[thing] [action] [reason].`
   - Bullets instead of paragraphs where lists fit.
   - Preserve verbatim: code blocks, inline `code`, URLs, file paths, technical terms, headings structure.
4. Target: ≤80 lines / ~600 tokens for `copilot-instructions.md`; ≤120 for `AGENTS.md`/`CLAUDE.md`.
5. Write file. Report before/after line + char counts.

### F4 — Strip discoverable facts (R4)
Remove lines matching:
- `\b(this (project|repo) (uses|is)|we use|tests? (are|live) in|main branch is)\b`
- Stack declarations that any manifest reveals (`package.json`, `tsconfig.json`, `pyproject.toml`, `*.csproj`, `Cargo.toml`, `go.mod`).
- Restatements of obvious directory structure.
Confirm each removal with user (batch: list candidates, ask "delete all? y/n/select").

### F2 — Dedupe AGENTS.md ↔ copilot-instructions.md (R2)
1. Diff the two files. Show overlapping lines.
2. Ask user: keep in which file? (default: keep in `AGENTS.md` as the cross-tool source, leave Copilot-specific rules in `copilot-instructions.md`).
3. Remove duplicates from the non-canonical file.

### F6 — Prune MCP servers (R6)
1. Read `.vscode/mcp.json` / `.copilot/mcp-config.json`.
2. List each server with brief purpose.
3. Ask user to mark keep/disable per server.
4. For "disable" → remove from workspace config (do NOT touch user-global config).
5. Report estimated savings: `removed_servers × 5 × 200 × est_steps` tokens per agent task.

### F9 — Add Conventional Commits hint (R9, optional)
If `copilot-instructions.md` lacks commit guidance and user wants it, append:
```
Commits: Conventional Commits. Subject ≤72 chars, imperative. Body only if "why" non-obvious.
```

### F8 — Translate non-English always-on content (R8)
Detect CJK/Cyrillic/Hebrew blocks. Offer English equivalent. User approves before replace.

## Workflow

1. Confirm scope: full audit fix-up vs targeted fix.
2. For each fix to apply:
   - Show before/after preview (diff or summary).
   - Wait for confirmation (`y` / `n` / `edit`).
   - Apply only on `y`.
3. After all fixes, run `token-optimization-check` logic again. Report new score.
4. Suggest `git diff --stat` for the user to review.

## Safety rules

- NEVER modify files outside: `.github/copilot-instructions.md`, `AGENTS.md`, `CLAUDE.md`, `.cursorrules`, `.github/instructions/**`, `.vscode/mcp.json`, `.copilot/mcp-config.json`, `.mcp.json`.
- NEVER touch user-global config (`~/.vscode/`, `~/.config/`).
- NEVER delete files outright — only edit contents, or empty + leave with a header comment.
- Preserve code blocks, URLs, file paths, headings verbatim during compression.
- If a transform would change technical meaning, skip it and flag for manual review.
- Show diff preview before every write. No silent edits.

## Output

After each fix:
```
[F<id>] <file> — <before> → <after> (Δ <n> lines, Δ ~<n> tokens)
```

Final summary:
```markdown
## Applied fixes
- F5: added output-control directive (+12 tokens, ~50% output savings ongoing)
- F1: compressed copilot-instructions.md (142 → 68 lines, ~980 → ~520 tokens)
- F6: pruned 4 MCP servers (~3200 tokens/agent-step saved)

## New audit score
<old> → <new> / 100

## Next steps
- Review `git diff`
- Commit with: `chore: optimize copilot token usage`
```

## Notes

- Token counts are estimates (`chars / 4`).
- Never claim exact billing savings — say "estimated".
- If user says "apply all", still surface a single combined preview before writing.
- Pair skill: `token-optimization-check` (read-only audit).
