---
name: create-image
description: Generate images using Azure OpenAI DALL-E models. Use this skill when the user asks to create images, generate visuals, or produce artwork using AI.
license: MIT
---

# Image Generation with Azure OpenAI

This skill generates images using Azure OpenAI's DALL-E models through direct API calls.

## When to use

- User asks to generate, create, or produce an image
- User wants to visualize a concept or idea
- User requests artwork, illustrations, or graphics
- User needs images for documentation, presentations, or content
- User asks to create visual representations of descriptions

## Prerequisites

1. **Azure OpenAI Resource**
   - Azure OpenAI resource with deployed image model (`dall-e-3` or `dall-e-2`)
   - Note your endpoint: `https://YOUR-RESOURCE.openai.azure.com/`
   - Note your deployment name (e.g., `dall-e-3`)

2. **Authentication** (choose one)

   **Option A: API Key** (simplest)
   ```bash
   export AZURE_OPENAI_API_KEY="your-api-key-here"
   ```

   **Option B: Azure CLI** (recommended for local development)
   ```bash
   az login
   # Ensure you have "Cognitive Services OpenAI User" role
   ```

## How to use

### Using Python (Recommended)

Install the Azure OpenAI SDK:
```bash
pip install openai
```

Generate an image with Python:
```python
from openai import AzureOpenAI
import os
import json

# Initialize client
client = AzureOpenAI(
    api_version="2024-02-01",
    azure_endpoint=os.environ["AZURE_OPENAI_ENDPOINT"],
    api_key=os.environ.get("AZURE_OPENAI_API_KEY")  # or use Azure CLI auth
)

# Generate image
result = client.images.generate(
    model="dall-e-3",  # or your deployment name
    prompt="A serene mountain landscape at sunset",
    size="1024x1024",
    quality="standard",
    n=1
)

# Save the image
image_url = result.data[0].url
print(f"Image URL: {image_url}")
```

### Using curl (Quick testing)

With API key:
```bash
curl "https://YOUR-RESOURCE.openai.azure.com/openai/deployments/dall-e-3/images/generations?api-version=2024-02-01" \
  -H "Content-Type: application/json" \
  -H "api-key: $AZURE_OPENAI_API_KEY" \
  -d '{
    "prompt": "A serene mountain landscape at sunset",
    "size": "1024x1024",
    "quality": "standard",
    "n": 1
  }'
```

### Parameters

| Parameter | Type | Options | Default | Description |
|-----------|------|---------|---------|-------------|
| `prompt` | string | 1-4000 chars | required | Description of the image to generate |
| `size` | string | `1024x1024`, `1024x1792`, `1792x1024` | `1024x1024` | Image dimensions |
| `quality` | string | `standard`, `hd` | `standard` | Image quality level |
| `n` | number | 1 (dall-e-3), 1-10 (dall-e-2) | `1` | Number of images |
| `style` | string | `natural`, `vivid` | `vivid` | Image style (dall-e-3 only) |

### Quality Guidelines

- Use `standard` quality for most requests
- Use `hd` quality when user specifically requests high-quality or detailed images
- Use portrait dimensions (`1024x1792`) for vertical images
- Use landscape dimensions (`1792x1024`) for horizontal images
- DALL-E 3 generates one image at a time; DALL-E 2 can generate multiple

### Prompt Crafting Tips

Create effective prompts by:
1. Being specific and descriptive
2. Including style, mood, and atmosphere details
3. Specifying key visual elements
4. Mentioning desired composition or perspective
5. Avoiding vague or ambiguous language

## Examples

**Example 1: Basic image generation with Python**
```python
from openai import AzureOpenAI
import os

client = AzureOpenAI(
    api_version="2024-02-01",
    azure_endpoint="https://YOUR-RESOURCE.openai.azure.com/",
    api_key=os.environ["AZURE_OPENAI_API_KEY"]
)

result = client.images.generate(
    model="dall-e-3",
    prompt="A vibrant sunset over a calm ocean with orange and pink sky reflecting on the water",
    size="1024x1024"
)

print(result.data[0].url)
```

**Example 2: High quality portrait**
```python
result = client.images.generate(
    model="dall-e-3",
    prompt="A detailed portrait of a wise elderly wizard with a long white beard, wearing star-patterned robes, holding a glowing staff, mystical atmosphere",
    size="1024x1792",
    quality="hd",
    style="natural"
)

print(result.data[0].url)
```

**Example 3: Multiple variations with DALL-E 2**
```python
result = client.images.generate(
    model="dall-e-2",
    prompt="A modern minimalist office space with large windows, natural lighting, clean desk setup",
    n=3,
    size="1024x1024"
)

for i, image in enumerate(result.data):
    print(f"Image {i+1}: {image.url}")
```

**Example 4: Landscape with vivid style**
```python
result = client.images.generate(
    model="dall-e-3",
    prompt="A sprawling futuristic cityscape with tall sleek skyscrapers, flying vehicles, neon lights, bustling streets below, viewed from an elevated perspective, cyberpunk aesthetic",
    size="1792x1024",
    quality="hd",
    style="vivid"
)

print(result.data[0].url)
```

**Example 5: Download and save image**
```python
import requests
from PIL import Image
from io import BytesIO

result = client.images.generate(
    model="dall-e-3",
    prompt="A cute red panda eating bamboo in a forest",
    size="1024x1024"
)

# Download and save
response = requests.get(result.data[0].url)
img = Image.open(BytesIO(response.content))
img.save("red_panda.png")
print("Image saved as red_panda.png")
```

## Response Format

The API returns:
```json
{
  "created": 1702424000,
  "data": [
    {
      "url": "https://...",
      "revised_prompt": "Enhanced version of your prompt..."
    }
  ]
}
```

- `url`: Temporary URL to the generated image (valid for 24 hours)
- `revised_prompt`: The prompt used by the model (may be enhanced for safety/quality)

## Error Handling

Common issues and solutions:

- **401 Unauthorized**: Check your API key or Azure CLI login status
- **403 Forbidden**: Verify you have "Cognitive Services OpenAI User" role assigned
- **429 Too Many Requests**: Rate limit reached, wait and retry
- **400 Bad Request**:
  - Check prompt length (max 4000 characters)
  - Verify size parameter matches available options
  - Ensure n=1 for DALL-E 3
- **Content filtered**: Revise prompt to comply with content policies

## Best Practices

1. **Prompt Quality**: Be specific and detailed for better results
2. **Size Selection**: Choose dimensions appropriate for the use case
3. **Quality vs Cost**: Use `standard` unless high detail is needed
4. **Save Images**: URLs expire after 24 hours - download if needed
5. **Error Handling**: Always implement retry logic for rate limits
6. **Cost Management**: Monitor usage in Azure Portal

## Environment Variables

Set these for easier usage:
```bash
export AZURE_OPENAI_ENDPOINT="https://YOUR-RESOURCE.openai.azure.com/"
export AZURE_OPENAI_API_KEY="your-api-key"
export AZURE_OPENAI_DEPLOYMENT="dall-e-3"
```

Then in Python:
```python
client = AzureOpenAI(
    api_version="2024-02-01",
    azure_endpoint=os.environ["AZURE_OPENAI_ENDPOINT"],
    api_key=os.environ["AZURE_OPENAI_API_KEY"]
)

result = client.images.generate(
    model=os.environ["AZURE_OPENAI_DEPLOYMENT"],
    prompt="Your prompt here"
)
```

## References

- [Azure OpenAI Image Generation Documentation](https://learn.microsoft.com/azure/ai-services/openai/how-to/dall-e)
- [OpenAI Python SDK](https://github.com/openai/openai-python)
- [Azure OpenAI API Reference](https://learn.microsoft.com/azure/ai-services/openai/reference)
