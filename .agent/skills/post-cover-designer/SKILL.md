---
name: post-cover-designer
description: Designs and generates a cover image for Hugo blog posts using Pillow. Use when creating a new post and a cover image is needed. Installs Pillow, runs the generation script, and saves cover.jpg to the correct post path.
---

# Post Cover Designer

This skill creates a `cover.jpg` for a Hugo blog post using the bundled Pillow-based script.
It picks colour values from the post content, runs the script to produce a 1600×900 JPEG,
and saves it in the right location — no external image service required.

## When to use

- A new Hugo post is being created from a source link
- A cover image is needed for an existing post that lacks one
- The user asks to regenerate or redesign a post cover

## Inputs required

Collect the following before proceeding (infer from the post content if already available):

- **Post title and slug** (e.g. `2024-06-15-azure-copilot-intro`)
- **Core technologies** mentioned in the post (e.g. `Azure,Bicep,GitHub Actions`)
- **Colour direction** — choose or derive:
  - `--bg-color`: dominant background colour in hex (default `#0a1628` — deep navy)
  - `--accent-color`: accent / pill colour in hex (default `#00b4d8` — cyan)

  Suggested palettes by topic:
  | Topic area | `--bg-color` | `--accent-color` |
  |------------|-------------|-----------------|
  | Azure / cloud | `#0a1628` | `#00b4d8` |
  | Security | `#1a0a28` | `#e040fb` |
  | DevOps / CI-CD | `#0d1f0a` | `#76c442` |
  | AI / ML | `#0a1020` | `#f4a261` |
  | Kubernetes | `#0a1628` | `#326ce5` |

## Step 1 – Install Pillow

Run once per environment before generating any cover:

```bash
pip install pillow
```

## Step 2 – Generate the cover image

Run the bundled script from the repository root.  
The script path is relative to the installed skill; adjust if needed.

```bash
python .agent/skills/post-cover-designer/scripts/generate_cover.py \
  --title "<post title>" \
  --output "content/posts/<slug>/cover.jpg" \
  --technologies "<Tech1>,<Tech2>,<Tech3>" \
  --bg-color "#0a1628" \
  --accent-color "#00b4d8"
```

**Arguments:**

| Argument | Required | Description |
|----------|----------|-------------|
| `--title` | ✅ | Full post title (used as headline text on the cover) |
| `--output` | ✅ | Destination path, must end with `cover.jpg` |
| `--technologies` | optional | Comma-separated list of technology tags shown as pills |
| `--bg-color` | optional | Background hex colour (default `#0a1628`) |
| `--accent-color` | optional | Accent / pill hex colour (default `#00b4d8`) |

The script will:
1. Create the output directory if it does not exist.
2. Render a 1600×900 gradient canvas with a subtle technical grid.
3. Draw the title as large white text with a drop shadow.
4. Render each technology as a coloured pill at the bottom of the image.
5. Save the result as a JPEG at the path specified by `--output`.

## Step 3 – Update front matter

Ensure the post's front matter includes:

```toml
cover        = true
author       = "sujith"
cover_prompt = "Pillow-generated cover: <title> | <technologies> | bg:<bg-color> accent:<accent-color>"
```

## Quality checks

- [ ] `pip install pillow` ran without errors.
- [ ] Script exited with `Cover saved → content/posts/<slug>/cover.jpg`.
- [ ] Output file exists and is a valid JPEG at `content/posts/<slug>/cover.jpg`.
- [ ] Front matter contains `cover = true`, `author = "sujith"`, and `cover_prompt`.
- [ ] Technology tags fit on one line (max ~8 short tags); reduce if overflow occurs.
