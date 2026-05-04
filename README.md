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
