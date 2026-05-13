# Creating AI Images with Azure OpenAI DALL-E: A Comprehensive Guide

> **Blog Post Source Material** - This document provides detailed information about the create-image skill for GitHub Copilot CLI, including setup, usage examples, and best practices for AI-powered image generation.

## Introduction

The create-image skill brings AI-powered image generation to your command line through GitHub Copilot CLI. Built on Azure OpenAI's DALL-E models, this skill enables developers to generate high-quality images directly from text descriptions without leaving their terminal or development environment.

Whether you're creating mockups, generating placeholder images, or exploring creative concepts, this skill integrates seamlessly into your workflow.

## Why Use This Skill?

### Key Benefits

1. **Command-Line Integration**: Generate images without switching contexts or opening browser tools
2. **Azure RBAC Security**: Uses modern keyless authentication with proper role-based access control
3. **Developer-Friendly**: Simple Python API with clear examples and error handling
4. **Flexible Quality Options**: Choose between standard and HD quality based on your needs
5. **Multiple Size Options**: Portrait, landscape, or square formats available

### Use Cases

- **Prototyping**: Generate mockup images for UI/UX designs
- **Content Creation**: Create blog post headers, social media graphics, or documentation visuals
- **Brainstorming**: Visualize concepts during planning sessions
- **Testing**: Generate test images for application development
- **Presentations**: Create custom illustrations for slides and demos

## Prerequisites

Before you can use the create-image skill, you'll need:

### 1. Azure OpenAI Resource

You need an active Azure subscription with an Azure OpenAI resource deployed. The resource should have one of the following image generation models:

- **dall-e-3** (recommended): Latest model with better quality and understanding
- **dall-e-2**: Previous generation, supports multiple images per request

To create an Azure OpenAI resource:

```bash
# Using Azure CLI
az cognitiveservices account create \
  --name my-openai-resource \
  --resource-group my-resource-group \
  --kind OpenAI \
  --sku S0 \
  --location eastus
```

Deploy your chosen model through the Azure Portal or Azure CLI.

### 2. Authentication Setup

The skill prioritizes **Azure RBAC** (Role-Based Access Control) over API keys for security. Many organizations disable API keys entirely on their Azure OpenAI endpoints.

#### Option A: Azure RBAC (Recommended)

For local development:

```bash
# Sign in with Azure CLI
az login

# Assign the necessary role to your user account
az role assignment create \
  --assignee $(az ad signed-in-user show --query id -o tsv) \
  --role "Cognitive Services OpenAI User" \
  --scope /subscriptions/{subscription-id}/resourceGroups/{rg-name}/providers/Microsoft.CognitiveServices/accounts/{resource-name}
```

For Azure-hosted applications (App Service, Container Apps, etc.):

```bash
# Enable managed identity
az webapp identity assign \
  --name my-app \
  --resource-group my-resource-group

# Assign role to the managed identity
az role assignment create \
  --assignee {managed-identity-principal-id} \
  --role "Cognitive Services OpenAI User" \
  --scope {azure-openai-resource-id}
```

#### Option B: API Key (If Enabled)

If your endpoint supports API keys:

```bash
# Get the API key from Azure Portal or CLI
az cognitiveservices account keys list \
  --name my-openai-resource \
  --resource-group my-resource-group

# Set as environment variable
export AZURE_OPENAI_API_KEY="your-key-here"
```

### 3. Install the Skill

Install the skill collection which includes create-image:

```bash
# Install the entire skills plugin
copilot plugin install sujithq/skills

# Or install just the create-image skill
gh skill install sujithq/skills create-image
```

Verify installation:

```bash
copilot
/skills list
/skills info create-image
```

## Usage Guide

### Basic Image Generation

The simplest way to generate an image with Python:

```python
from openai import AzureOpenAI
from azure.identity import DefaultAzureCredential, get_bearer_token_provider

# Setup authentication
token_provider = get_bearer_token_provider(
    DefaultAzureCredential(),
    "https://cognitiveservices.azure.com/.default"
)

# Initialize client
client = AzureOpenAI(
    api_version="2024-02-01",
    azure_endpoint="https://YOUR-RESOURCE.openai.azure.com/",
    azure_ad_token_provider=token_provider
)

# Generate an image
result = client.images.generate(
    model="dall-e-3",
    prompt="A professional developer working on a laptop in a modern office",
    size="1024x1024",
    quality="standard"
)

# Get the image URL
print(f"Image generated: {result.data[0].url}")
```

The generated image URL is temporary (valid for 24 hours). Download it if you need to keep it:

```python
import requests
from PIL import Image
from io import BytesIO

# Download the image
response = requests.get(result.data[0].url)
img = Image.open(BytesIO(response.content))
img.save("output.png")
print("Image saved as output.png")
```

### Understanding the Parameters

#### Model Selection

- **dall-e-3**: Produces higher quality images with better prompt understanding. Limited to one image per request.
- **dall-e-2**: Faster, can generate multiple images (up to 10) per request, but with slightly lower quality.

```python
# Using DALL-E 3 for quality
result = client.images.generate(
    model="dall-e-3",
    prompt="Your prompt here"
)

# Using DALL-E 2 for multiple variations
result = client.images.generate(
    model="dall-e-2",
    prompt="Your prompt here",
    n=3  # Generate 3 variations
)
```

#### Size Options

Choose the appropriate dimensions for your use case:

- **1024x1024**: Square format, ideal for avatars, icons, or general purpose
- **1024x1792**: Portrait format (9:16), great for mobile screens, posters, or vertical displays
- **1792x1024**: Landscape format (16:9), perfect for headers, banners, or wide displays

```python
# Portrait for mobile mockup
result = client.images.generate(
    model="dall-e-3",
    prompt="Mobile app login screen with modern design",
    size="1024x1792"
)

# Landscape for website header
result = client.images.generate(
    model="dall-e-3",
    prompt="Technology website hero section with futuristic elements",
    size="1792x1024"
)
```

#### Quality Levels

- **standard**: Good quality for most use cases, faster generation, lower cost
- **hd**: Higher detail and fidelity, slower generation, higher cost

```python
# Standard quality for quick iterations
result = client.images.generate(
    model="dall-e-3",
    prompt="A simple logo concept",
    quality="standard"
)

# HD quality for final production images
result = client.images.generate(
    model="dall-e-3",
    prompt="Detailed architectural rendering of a modern building",
    quality="hd"
)
```

#### Style Control (DALL-E 3 Only)

- **vivid**: More hyper-real and dramatic images (default)
- **natural**: More natural, less hyper-real images

```python
# Vivid style for creative, dramatic images
result = client.images.generate(
    model="dall-e-3",
    prompt="Sunset over mountains",
    style="vivid"
)

# Natural style for realistic, subdued images
result = client.images.generate(
    model="dall-e-3",
    prompt="Office workspace photography",
    style="natural"
)
```

## Crafting Effective Prompts

The quality of your generated images heavily depends on how well you craft your prompts. Here are proven techniques:

### Be Specific and Descriptive

**Bad**: "A car"
**Good**: "A sleek red sports car with chrome details, parked on a coastal road at sunset, reflections on the glossy paint"

### Include Style and Mood

Add descriptors that set the visual style:
- Art styles: "watercolor painting", "3D render", "pencil sketch", "digital art"
- Photography styles: "professional photography", "vintage photo", "macro photography"
- Moods: "cheerful", "mysterious", "serene", "dramatic"

**Example**:
```python
prompt = """A cozy coffee shop interior with warm lighting,
wooden furniture, plants by the window, people working on laptops,
professional interior photography, shallow depth of field,
inviting atmosphere"""
```

### Specify Composition and Perspective

Guide the framing of your image:
- "aerial view"
- "close-up shot"
- "wide angle"
- "portrait orientation"
- "centered composition"
- "rule of thirds"

**Example**:
```python
prompt = """A modern data center server room, wide angle shot,
symmetrical composition, rows of servers with blue LED lights,
professional architectural photography, high detail"""
```

### Use Industry-Standard Terminology

Leverage photography and design vocabulary:
- Lighting: "golden hour", "studio lighting", "backlighting", "dramatic shadows"
- Quality: "sharp focus", "bokeh background", "high resolution", "detailed textures"
- Color: "vibrant colors", "muted tones", "monochromatic", "complementary colors"

### Avoid Ambiguity

Be explicit about what you want and don't want:

**Example**:
```python
prompt = """A professional business team meeting in a modern conference room,
diverse group of 4-5 people, natural office lighting,
clean and professional atmosphere, no text or logos visible,
contemporary business setting"""
```

## Real-World Examples

### Example 1: Blog Post Header

```python
result = client.images.generate(
    model="dall-e-3",
    prompt="""A modern tech blog header image featuring abstract
    circuit board patterns, flowing data streams, and cloud computing
    icons, gradient background from deep blue to cyan, professional
    and clean design, wide format, high-tech aesthetic""",
    size="1792x1024",
    quality="hd",
    style="vivid"
)
```

### Example 2: Mobile App Mockup Background

```python
result = client.images.generate(
    model="dall-e-3",
    prompt="""Abstract gradient background for a finance mobile app,
    smooth flowing shapes, professional blue and purple tones,
    subtle geometric patterns, modern and trustworthy feel,
    portrait orientation, minimal and clean""",
    size="1024x1792",
    quality="standard",
    style="natural"
)
```

### Example 3: Product Placeholder Images

```python
# Generate multiple variations with DALL-E 2
result = client.images.generate(
    model="dall-e-2",
    prompt="""Generic product box on white background,
    professional product photography, centered composition,
    soft shadows, studio lighting, square format""",
    size="1024x1024",
    n=5
)

# Save all variations
for i, image in enumerate(result.data):
    response = requests.get(image.url)
    img = Image.open(BytesIO(response.content))
    img.save(f"product_placeholder_{i+1}.png")
```

### Example 4: Icon or Avatar Generation

```python
result = client.images.generate(
    model="dall-e-3",
    prompt="""Simple, modern logo icon for a cloud storage service,
    minimal design with a cloud and lock symbol, blue and white colors,
    flat design style, centered on white background, professional""",
    size="1024x1024",
    quality="standard",
    style="natural"
)
```

## Best Practices

### 1. Use Azure RBAC for Production

Always prefer Azure RBAC over API keys:
- Better security posture
- Easier credential rotation
- Audit trail through Azure Activity Logs
- Supports managed identities for Azure-hosted apps

### 2. Implement Error Handling

Azure OpenAI can return various errors. Handle them gracefully:

```python
from openai import AzureOpenAI, OpenAIError
import time

def generate_image_with_retry(client, prompt, max_retries=3):
    for attempt in range(max_retries):
        try:
            result = client.images.generate(
                model="dall-e-3",
                prompt=prompt,
                size="1024x1024"
            )
            return result.data[0].url
        except OpenAIError as e:
            if "429" in str(e):  # Rate limit
                wait_time = (2 ** attempt) * 2  # Exponential backoff
                print(f"Rate limited. Waiting {wait_time}s...")
                time.sleep(wait_time)
            elif "content_filter" in str(e):
                print("Prompt rejected by content filter. Please revise.")
                return None
            else:
                print(f"Error: {e}")
                if attempt == max_retries - 1:
                    raise
```

### 3. Download and Store Images

Remember that generated image URLs expire after 24 hours:

```python
import os
from datetime import datetime

def save_generated_image(image_url, output_dir="generated_images"):
    os.makedirs(output_dir, exist_ok=True)

    # Create unique filename
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"image_{timestamp}.png"
    filepath = os.path.join(output_dir, filename)

    # Download and save
    response = requests.get(image_url)
    with open(filepath, 'wb') as f:
        f.write(response.content)

    return filepath
```

### 4. Monitor Costs

Track your usage to manage costs:
- DALL-E 3 Standard: ~$0.04 per image
- DALL-E 3 HD: ~$0.08 per image
- DALL-E 2: ~$0.02 per image

Set up Azure Cost Management alerts to avoid surprises.

### 5. Iterate on Prompts

Start with a basic prompt and refine:

```python
prompts = [
    "A modern office",
    "A modern office with large windows and natural light",
    "A modern office with large windows, natural light, wooden desks, plants, professional photography",
    "A modern open-plan office with floor-to-ceiling windows, abundant natural light, wooden standing desks, indoor plants, ergonomic chairs, minimal design, professional architectural photography, wide angle"
]

for i, prompt in enumerate(prompts):
    result = client.images.generate(model="dall-e-3", prompt=prompt)
    save_generated_image(result.data[0].url, f"iteration_{i+1}.png")
```

## Troubleshooting

### Authentication Errors (401/403)

**Problem**: Getting "Unauthorized" or "Forbidden" errors

**Solutions**:
1. Verify Azure CLI login: `az account show`
2. Check role assignments:
   ```bash
   az role assignment list --assignee $(az ad signed-in-user show --query id -o tsv)
   ```
3. Ensure you have "Cognitive Services OpenAI User" role
4. If using managed identity, verify it's enabled and has proper roles

### Content Filter Rejections

**Problem**: Prompts are being rejected

**Solutions**:
1. Remove potentially sensitive keywords
2. Be more specific about professional/safe contexts
3. Avoid prompts that could generate harmful content
4. Rephrase using neutral, descriptive language

Example revision:
- ❌ "A person in danger"
- ✅ "A person wearing safety equipment in an industrial setting"

### Rate Limiting (429 Errors)

**Problem**: Too many requests in a short time

**Solutions**:
1. Implement exponential backoff (see error handling example above)
2. Reduce request frequency
3. Consider upgrading your Azure OpenAI quota
4. Use DALL-E 2 with `n` parameter instead of multiple separate requests

### API Key Disabled Error

**Problem**: "API key authentication disabled" error

**Solution**: Switch to Azure RBAC authentication using DefaultAzureCredential:

```python
from azure.identity import DefaultAzureCredential, get_bearer_token_provider

token_provider = get_bearer_token_provider(
    DefaultAzureCredential(),
    "https://cognitiveservices.azure.com/.default"
)

client = AzureOpenAI(
    api_version="2024-02-01",
    azure_endpoint="https://YOUR-RESOURCE.openai.azure.com/",
    azure_ad_token_provider=token_provider  # No api_key parameter
)
```

## Environment Setup for Teams

For team environments, create a shared configuration:

```bash
# .env file
AZURE_OPENAI_ENDPOINT=https://your-resource.openai.azure.com/
AZURE_OPENAI_DEPLOYMENT=dall-e-3
```

```python
# config.py
import os
from dotenv import load_dotenv
from openai import AzureOpenAI
from azure.identity import DefaultAzureCredential, get_bearer_token_provider

load_dotenv()

def get_image_client():
    token_provider = get_bearer_token_provider(
        DefaultAzureCredential(),
        "https://cognitiveservices.azure.com/.default"
    )

    return AzureOpenAI(
        api_version="2024-02-01",
        azure_endpoint=os.getenv("AZURE_OPENAI_ENDPOINT"),
        azure_ad_token_provider=token_provider
    )

# Usage
from config import get_image_client

client = get_image_client()
result = client.images.generate(
    model=os.getenv("AZURE_OPENAI_DEPLOYMENT"),
    prompt="Your prompt here"
)
```

## Integration with CI/CD

Automate image generation in your pipelines:

```yaml
# GitHub Actions example
name: Generate Marketing Images

on:
  workflow_dispatch:
    inputs:
      prompt:
        description: 'Image prompt'
        required: true

jobs:
  generate:
    runs-on: ubuntu-latest
    steps:
      - uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}

      - name: Generate Image
        run: |
          pip install openai azure-identity
          python generate_image.py "${{ github.event.inputs.prompt }}"

      - name: Upload Artifact
        uses: actions/upload-artifact@v3
        with:
          name: generated-image
          path: output.png
```

## Conclusion

The create-image skill brings powerful AI image generation capabilities to your development workflow. By leveraging Azure OpenAI's DALL-E models with secure RBAC authentication, you can generate high-quality images directly from your terminal or integrate them into your applications.

Key takeaways:
- Use Azure RBAC for secure, keyless authentication
- Craft detailed, specific prompts for best results
- Choose the right model, size, and quality for your use case
- Implement proper error handling and retry logic
- Download and store images as URLs expire after 24 hours

## Additional Resources

- [Azure OpenAI Service Documentation](https://learn.microsoft.com/azure/ai-services/openai/)
- [DALL-E Image Generation Guide](https://learn.microsoft.com/azure/ai-services/openai/how-to/dall-e)
- [GitHub Copilot CLI Skills](https://github.com/sujithq/skills)
- [OpenAI Python SDK Documentation](https://github.com/openai/openai-python)

## Contributing

Found an issue or have a suggestion? Contributions are welcome:

1. Visit the [skills repository](https://github.com/sujithq/skills)
2. Open an issue or submit a pull request
3. Follow the conventional commit format

---

**Author**: sujithq
**License**: MIT
**Last Updated**: 2026-05-13
