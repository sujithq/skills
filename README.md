# skills

Collection of GitHub Copilot skills for enhanced productivity.

## Available skills

- **pdf-to-markdown**: Convert PDF and Office files to Markdown using Microsoft's `markitdown` package. Supports multiple file formats: PDF, PowerPoint, Word, Excel.
- **commit-message-writer**: Generate conventional commit messages following best practices. Supports all standard commit types: feat, fix, docs, style, refactor, perf, test, chore.
- **create-image**: Generate images using Azure OpenAI DALL-E models through direct API calls. Provides Python and curl examples for AI-powered image creation with customizable quality, size, and style options.

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
/skills info commit-message-writer
```

### Option 2: Install Individual Skills
Install skills one at a time:

```powershell
gh skill install sujithq/skills commit-message-writer
gh skill install sujithq/skills pdf-to-markdown
gh skill install sujithq/skills create-image
```

### Option 3: Install from Marketplace (Future)
As plugin marketplaces mature:

```powershell
copilot plugin install awesome-copilot/sujithq-skills
```

## Usage

Once installed, use in Copilot CLI:

```
copilot
/skills list               # See installed skills
/skills info commit-message-writer  # Get skill details
```

Or reference directly in prompts when in agent mode.

## Development Setup

### Prerequisites
- PowerShell 7+ (Windows, macOS, Linux)
- Git
- `gh` CLI (GitHub CLI) with skill support
- Node.js 24+ (for commit validation)

### Install Dependencies
```powershell
# Install conventional-changelog for CHANGELOG generation
npm install -g conventional-changelog-cli

# Install commitlint for commit validation
npm install -g @commitlint/cli @commitlint/config-conventional
```

### Project Structure
```
.
├── skills/                 # Skill definitions
│   ├── commit-message-writer/
│   │   └── SKILL.md
│   ├── pdf-to-markdown/
│   │   └── SKILL.md
│   └── create-image/
│       └── SKILL.md
├── plugin.json            # Plugin manifest for all-in-one install
├── publish.ps1            # Publishing automation script
├── suggest-version.ps1    # Version suggestion script
├── .commitlintrc.json     # Commit validation rules
└── validate-commits.yml   # GitHub Actions workflow
```

## Publishing

### Quick Start
```powershell
# 1. Make commits with conventional format
git commit -m "feat: add new skill"

# 2. Run publish script (handles everything)
./publish.ps1

# That's it! Script will:
# - Suggest version based on commits
# - Update CHANGELOG.md
# - Create git tag
# - Publish to GitHub
```

### Manual Publishing

If you prefer manual control:

```powershell
# 1. Check suggested version
./suggest-version.ps1

# 2. Update changelog
npm install -g conventional-changelog-cli
conventional-changelog -p angular -i CHANGELOG.md -s

# 3. Commit
git add CHANGELOG.md
git commit -m "docs: update changelog for v1.2.0"

# 4. Publish
gh skill publish --tag v1.2.0

# 5. Sync git tag
git tag v1.2.0
git push origin v1.2.0
```

### Version Numbering
Versions follow [Semantic Versioning](https://semver.org/):
- **MAJOR** (x.0.0): Breaking changes (`BREAKING CHANGE:` in commit)
- **MINOR** (0.x.0): New features (`feat:` commits)
- **PATCH** (0.0.x): Bug fixes (`fix:` commits)

The `suggest-version.ps1` script automatically determines the correct version based on your commits.

## Contributing

### Commit Message Format

This project enforces [Conventional Commits](https://www.conventionalcommits.org/) using commitlint. All commits must follow this format:

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Type** (required):
- `feat`: A new feature
- `fix`: A bug fix
- `docs`: Documentation only
- `style`: Changes that don't affect code meaning (formatting, whitespace, etc.)
- `refactor`: Code change that neither fixes a bug nor adds a feature
- `perf`: Code change that improves performance
- `test`: Adding or updating tests
- `chore`: Build process, dependencies, tooling

**Scope** (optional):
- `commit-writer`: Commit message writer skill
- `pdf-markdown`: PDF to Markdown converter skill
- `create-image`: Azure Image MCP Server skill

**Subject** (required):
- Imperative mood ("add" not "added")
- Don't capitalize first letter
- No period at the end

**Examples:**
```
feat(commit-writer): add support for co-authored commits
fix(pdf-markdown): handle corrupted PDF files gracefully
docs: update installation instructions
chore: update dependencies
```

### Validation
Commits are automatically validated on push to `main` and in pull requests. Invalid commits will be rejected:

```
✓ Valid: feat(pdf-markdown): add xlsx support
✗ Invalid: Added new feature
✗ Invalid: update stuff
```

### Development Workflow

1. **Create feature branch:**
   ```powershell
   git checkout -b feature/your-feature
   ```

2. **Make commits** with conventional messages:
   ```powershell
   git commit -m "feat(skill-name): your feature description"
   ```

3. **Push and create PR:**
   ```powershell
   git push origin feature/your-feature
   ```

4. **Commits are validated** automatically in PR

5. **Merge to main** when approved

6. **Publish release:**
   ```powershell
   ./publish.ps1
   ```

## License

MIT - See [LICENSE](LICENSE) for details
