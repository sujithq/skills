---
name: commit-message-writer
description: Generates clear, conventional commit messages from a summary of code changes. Use when asked to write a commit message, summarize changes for commit, or create Conventional Commits format messages.
license: MIT
---

# Commit Message Writer

This skill generates well-formatted, conventional commit messages that follow best practices and make version history readable.

## When to use

- User asks to write a commit message
- User asks to summarize changes for a commit
- User wants a message following Conventional Commits format
- User needs help with commit message structure or wording

## How to use

1. Ask the user for a brief summary of their code changes if not provided.
2. Determine the commit type based on the changes:
   - `feat`: A new feature
   - `fix`: A bug fix
   - `docs`: Documentation changes only
   - `style`: Code style changes (formatting, missing semicolons, etc.)
   - `refactor`: Code refactoring without feature or bug changes
   - `perf`: Performance improvements
   - `test`: Adding or updating tests
   - `chore`: Build process, dependencies, tooling changes
3. Write a concise subject line (max 72 characters) in lowercase, starting with the type and optional scope.
4. If changes warrant explanation, add a blank line and detailed body (optional).
5. Output only the final commit message — no markdown formatting, no explanation.

## Examples

**Example 1 (simple bug fix):**
```
fix: correct typo in user authentication logic
```

**Example 2 (new feature with scope):**
```
feat(dashboard): add dark mode toggle
```

**Example 3 (with body):**
```
refactor(api): simplify error handling in middleware

- Consolidate duplicate error checks
- Use consistent error response format
- Remove unnecessary try-catch blocks
- Improves code readability by 15%
```

**Example 4 (breaking change note):**
```
feat(auth): require JWT for all endpoints

BREAKING CHANGE: Legacy token support removed.
Clients must upgrade to JWT-based authentication.
```

## Output

- Output the commit message ready to copy into `git commit -m "..."` or a commit dialog.
- For multi-line messages, format with subject, blank line, then body.
- Keep subject line under 72 characters.
- Use imperative mood ("add" not "added" or "adds").
