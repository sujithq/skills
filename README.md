# skills
Collection of skills

## Available skills

- `pdf-to-markdown`: Convert PDF and Office files to Markdown with `markitdown`.
- `commit-message-writer`: Generate conventional commit messages from code change summaries.

## Installation

### Option 1: Install as Plugin (Recommended)
Install all skills at once:

```powershell
copilot plugin install sujithq/skills
```

Then in Copilot CLI:
```
copilot
/skills list
```

### Option 2: Install Individual Skills
Install skills one at a time:

```powershell
gh skill install sujithq/skills commit-message-writer
gh skill install sujithq/skills pdf-to-markdown
```

### Option 3: Install from Marketplace (Future)
As marketplaces mature, install via:

```powershell
copilot plugin install awesome-copilot/sujithq-skills
```

## Usage

Once installed, use in Copilot CLI:

```
copilot
/skills info commit-message-writer
/skills info pdf-to-markdown
```

Or reference in prompts with `/skill-name` in agent mode.

## Contributing

### Commit Message Format
This project uses [Conventional Commits](https://www.conventionalcommits.org/) to automatically generate changelog entries and determine version bumps.

**Format**: `<type>(<scope>): <subject>`

**Types**:
- `feat`: A new feature
- `fix`: A bug fix
- `docs`: Documentation only
- `style`: Changes that don't affect code meaning (formatting, etc.)
- `refactor`: Code change that neither fixes a bug nor adds a feature
- `perf`: Code change that improves performance
- `test`: Adding or updating tests
- `ci`: Changes to CI/CD configuration

**Examples**:
```
feat(commit-writer): add support for scoped commits
fix(pdf-skill): handle corrupt PDF files gracefully
docs: update installation instructions
```

Commits are validated in pull requests—only conventional commits are accepted.

### Publishing
1. Push commits to main with conventional commit messages
2. When ready, create a tag: `git tag v1.2.0`
3. Push the tag: `git push origin v1.2.0`
4. GitHub Actions automatically:
   - Generates CHANGELOG.md
   - Publishes the release
   - Makes skills discoverable via `gh skill install` and `copilot plugin install`

No manual changelog editing needed!
