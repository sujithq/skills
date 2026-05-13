---
name: create-image
description: Generate images using Azure OpenAI DALL-E models through the Azure Image MCP Server. Use this skill when the user asks to create images, generate visuals, or produce artwork using AI.
license: MIT
---

# Azure Image MCP Server

This skill enables AI image generation using Azure OpenAI's DALL-E models through a Model Context Protocol (MCP) server.

## When to use

- User asks to generate, create, or produce an image
- User wants to visualize a concept or idea
- User requests artwork, illustrations, or graphics
- User needs images for documentation, presentations, or content
- User asks to create visual representations of descriptions

## Prerequisites

Before using this skill, ensure the Azure Image MCP Server is properly configured:

1. **Azure OpenAI Resource**
   - Azure OpenAI resource with deployed image models (`gpt-image-2` or `gpt-image-1.5`)
   - Endpoint URL available

2. **Authentication**
   - Local: Run `az login` with an account that has `Cognitive Services OpenAI User` role
   - Azure: Managed identity with the same role assigned

3. **MCP Server Installation**
   ```bash
   git clone https://github.com/sujithq/image-mcp-server
   cd image-mcp-server
   npm install
   npm run build
   ```

4. **Configuration**
   Create a `.env` file with required settings:
   ```bash
   AZURE_OPENAI_ENDPOINT=https://your-resource.openai.azure.com/
   AZURE_OPENAI_IMAGE_MODEL=gpt-image-2
   IMAGE_OUTPUT_DIR=./output/images
   ```

5. **VS Code Integration**
   Add to your MCP client configuration (Cline, Claude Code, or Continue):
   ```json
   {
     "azure-image": {
       "command": "node",
       "args": ["/absolute/path/to/image-mcp-server/dist/index.js"],
       "env": {
         "AZURE_OPENAI_ENDPOINT": "https://your-resource.openai.azure.com/",
         "AZURE_OPENAI_IMAGE_MODEL": "gpt-image-2",
         "IMAGE_OUTPUT_DIR": "/path/to/output/images"
       }
     }
   }
   ```

## How to use

When the user requests image generation, use the `generate_image` tool provided by the Azure Image MCP Server.

### Basic Usage

For simple image requests:
```
prompt: "A serene mountain landscape at sunset with a lake in the foreground"
```

### Advanced Options

| Parameter | Type | Options | Default | Description |
|-----------|------|---------|---------|-------------|
| `prompt` | string | 1-4000 chars | required | Description of the image to generate |
| `size` | string | `1024x1024`, `1024x1792`, `1792x1024` | `1024x1024` | Image dimensions |
| `quality` | string | `standard`, `hd`, `low`, `medium`, `high` | `standard` | Image quality level |
| `n` | number | 1-10 | `1` | Number of images to generate |
| `output_format` | string | `png`, `jpeg` | `png` | Output file format |
| `model` | string | `gpt-image-2`, `gpt-image-1.5` | `gpt-image-2` | Model to use |

### Quality Guidelines

- Use `standard` quality for most requests
- Use `hd` quality when user specifically requests high-quality or detailed images
- Use portrait dimensions (`1024x1792`) for vertical images
- Use landscape dimensions (`1792x1024`) for horizontal images
- Generate multiple images (`n > 1`) only when user asks for variations or options

### Prompt Crafting

Create effective prompts by:
1. Being specific and descriptive
2. Including style, mood, and atmosphere details
3. Specifying key visual elements
4. Mentioning desired composition or perspective
5. Avoiding vague or ambiguous language

## Examples

**Example 1 (basic image):**
```
User: "Create an image of a sunset over the ocean"
Tool call: generate_image
Parameters:
  prompt: "A vibrant sunset over a calm ocean with orange and pink sky reflecting on the water"
```

**Example 2 (high quality with specific size):**
```
User: "Generate a detailed portrait of a wise old wizard"
Tool call: generate_image
Parameters:
  prompt: "A detailed portrait of a wise elderly wizard with a long white beard, wearing star-patterned robes, holding a glowing staff, mystical atmosphere"
  size: "1024x1792"
  quality: "hd"
```

**Example 3 (multiple variations):**
```
User: "Show me a few options for a modern office space"
Tool call: generate_image
Parameters:
  prompt: "A modern minimalist office space with large windows, natural lighting, clean desk setup, ergonomic chair, indoor plants, and contemporary design"
  n: 3
```

**Example 4 (specific style and composition):**
```
User: "I need a wide landscape image of a futuristic city for a presentation"
Tool call: generate_image
Parameters:
  prompt: "A sprawling futuristic cityscape with tall sleek skyscrapers, flying vehicles, neon lights, bustling streets below, viewed from an elevated perspective, cyberpunk aesthetic, vibrant colors"
  size: "1792x1024"
  quality: "hd"
  output_format: "jpeg"
```

## Output

The tool returns:
- File paths to generated images
- Image dimensions and format
- Metadata including the original and revised prompts
- Any warnings or suggestions

Images are saved to the configured `IMAGE_OUTPUT_DIR` with accompanying `.json` metadata files.

## Error Handling

Common issues and solutions:

- **Authentication errors**: Verify Azure credentials with `az login` and role assignments
- **Model not found**: Check deployment names match configuration
- **Content filter rejection**: Revise prompt to comply with content policies
- **Rate limits**: Wait and retry, or reduce request frequency
- **Quota exceeded**: Check Azure OpenAI quota limits in Azure Portal

## Best Practices

1. **Prompt Quality**: Craft detailed, specific prompts for better results
2. **Size Selection**: Choose dimensions appropriate for the use case
3. **Quality vs Cost**: Use `standard` quality unless high detail is needed
4. **File Management**: Organize output directory by project or purpose
5. **Metadata**: Keep the `.json` sidecar files for tracking prompts and parameters

## References

- GitHub Repository: https://github.com/sujithq/image-mcp-server
- Azure OpenAI Documentation: https://learn.microsoft.com/azure/ai-services/openai/
- MCP Documentation: https://modelcontextprotocol.io/
