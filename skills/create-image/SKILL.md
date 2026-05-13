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

2. **Authentication**

   **Important**: Many Azure OpenAI endpoints disable API key authentication for security. Always verify your endpoint's authentication requirements.

   **Option A: Azure RBAC (Recommended)**

   For local development:
   ```bash
   az login
   # Ensure you have "Cognitive Services OpenAI User" role assigned
   ```

   For Azure-hosted applications:
   ```bash
   # Enable managed identity on your Azure resource
   az webapp identity assign --name <app-name> --resource-group <rg-name>

   # Assign the required role
   az role assignment create \
     --assignee <managed-identity-principal-id> \
     --role "Cognitive Services OpenAI User" \
     --scope <azure-openai-resource-id>
   ```

   **Option B: API Key** (if enabled on your endpoint)
   ```bash
   export AZURE_OPENAI_API_KEY="your-api-key-here"
   ```

   **Note**: If API key authentication is disabled, you must use Azure RBAC with proper role assignments.

## How to use

### Using Python (Recommended)

Install the Azure OpenAI SDK:
```bash
pip install openai azure-identity
```

Generate an image with Python using Azure RBAC (recommended):
```python
from openai import AzureOpenAI
from azure.identity import DefaultAzureCredential, get_bearer_token_provider

# Use DefaultAzureCredential for keyless authentication
token_provider = get_bearer_token_provider(
    DefaultAzureCredential(),
    "https://cognitiveservices.azure.com/.default"
)

# Initialize client with Azure RBAC
client = AzureOpenAI(
    api_version="2024-02-01",
    azure_endpoint="https://YOUR-RESOURCE.openai.azure.com/",
    azure_ad_token_provider=token_provider
)

# Generate image
result = client.images.generate(
    model="dall-e-3",  # or your deployment name
    prompt="A serene mountain landscape at sunset",
    size="1024x1024",
    quality="standard",
    n=1
)

# Get the image URL
image_url = result.data[0].url
print(f"Image URL: {image_url}")
```

Alternative with API Key (if enabled):
```python
from openai import AzureOpenAI
import os

# Initialize client with API key
client = AzureOpenAI(
    api_version="2024-02-01",
    azure_endpoint=os.environ["AZURE_OPENAI_ENDPOINT"],
    api_key=os.environ["AZURE_OPENAI_API_KEY"]
)

# Generate image
result = client.images.generate(
    model="dall-e-3",
    prompt="A serene mountain landscape at sunset",
    size="1024x1024"
)

print(result.data[0].url)
```

### Using curl (Quick testing)

With Azure RBAC (recommended):
```bash
# Get an access token using Azure CLI
TOKEN=$(az account get-access-token --resource https://cognitiveservices.azure.com --query accessToken -o tsv)

# Make the API call
curl "https://YOUR-RESOURCE.openai.azure.com/openai/deployments/dall-e-3/images/generations?api-version=2024-02-01" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "prompt": "A serene mountain landscape at sunset",
    "size": "1024x1024",
    "quality": "standard",
    "n": 1
  }'
```

With API key (if enabled):
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

**Example 1: Basic image generation with Azure RBAC**
```python
from openai import AzureOpenAI
from azure.identity import DefaultAzureCredential, get_bearer_token_provider

# Use DefaultAzureCredential for keyless authentication
token_provider = get_bearer_token_provider(
    DefaultAzureCredential(),
    "https://cognitiveservices.azure.com/.default"
)

client = AzureOpenAI(
    api_version="2024-02-01",
    azure_endpoint="https://YOUR-RESOURCE.openai.azure.com/",
    azure_ad_token_provider=token_provider
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

- **401 Unauthorized**:
  - If using API key: Check your API key is correct and not expired
  - If using RBAC: Run `az login` or verify your managed identity is enabled
  - Verify the endpoint hasn't disabled API key authentication (use RBAC instead)

- **403 Forbidden**:
  - Verify you have "Cognitive Services OpenAI User" role assigned
  - Check role assignment scope includes your Azure OpenAI resource
  - For managed identity: Ensure the identity has proper RBAC assignments
  - Run: `az role assignment list --assignee <your-user-or-identity-id> --scope <azure-openai-resource-id>`

- **API Key Disabled Error**:
  - Your Azure OpenAI endpoint has disabled API key authentication
  - Switch to Azure RBAC authentication using DefaultAzureCredential
  - Ensure proper role assignments are in place

- **429 Too Many Requests**:
  - Rate limit reached, wait and retry with exponential backoff
  - Check your quota limits in Azure Portal

- **400 Bad Request**:
  - Check prompt length (max 4000 characters)
  - Verify size parameter matches available options
  - Ensure n=1 for DALL-E 3

- **Content filtered**:
  - Revise prompt to comply with Azure content policies
  - Remove potentially sensitive or inappropriate content

## Best Practices

1. **Authentication**: Use Azure RBAC (DefaultAzureCredential) over API keys for better security
2. **Prompt Quality**: Be specific and detailed for better results
3. **Size Selection**: Choose dimensions appropriate for the use case
4. **Quality vs Cost**: Use `standard` unless high detail is needed
5. **Save Images**: URLs expire after 24 hours - download if needed
6. **Error Handling**: Always implement retry logic for rate limits
7. **Cost Management**: Monitor usage in Azure Portal
8. **RBAC Roles**: Ensure proper "Cognitive Services OpenAI User" role assignments

## Environment Variables

For RBAC-based authentication (recommended):
```bash
export AZURE_OPENAI_ENDPOINT="https://YOUR-RESOURCE.openai.azure.com/"
export AZURE_OPENAI_DEPLOYMENT="dall-e-3"
# No API key needed - uses DefaultAzureCredential
```

For API key authentication (if enabled):
```bash
export AZURE_OPENAI_ENDPOINT="https://YOUR-RESOURCE.openai.azure.com/"
export AZURE_OPENAI_API_KEY="your-api-key"
export AZURE_OPENAI_DEPLOYMENT="dall-e-3"
```

Python usage with RBAC:
```python
from openai import AzureOpenAI
from azure.identity import DefaultAzureCredential, get_bearer_token_provider
import os

token_provider = get_bearer_token_provider(
    DefaultAzureCredential(),
    "https://cognitiveservices.azure.com/.default"
)

client = AzureOpenAI(
    api_version="2024-02-01",
    azure_endpoint=os.environ["AZURE_OPENAI_ENDPOINT"],
    azure_ad_token_provider=token_provider
)

result = client.images.generate(
    model=os.environ["AZURE_OPENAI_DEPLOYMENT"],
    prompt="Your prompt here"
)
```

Python usage with API key:
```python
from openai import AzureOpenAI
import os

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
