---
name: copilot-issue-image
description: Prepare GitHub Copilot issue-assigned workflows to generate images with Azure OpenAI using non-interactive authentication. Use when the user wants Copilot assigned to an issue to create images, wire image generation into a repository, or replace local az login with GitHub-safe Azure authentication.
license: MIT
---

# Copilot Issue Image Generation

This skill helps GitHub Copilot work from an assigned issue to add or run image generation in a repository. It is for the GitHub-hosted Copilot coding-agent flow, where local skills, local plugins, and local `az login` sessions are not available.

## When to use

- User wants to assign an issue to Copilot and have it generate images
- User asks whether a local image-generation skill can run from GitHub issues
- User needs a repository-ready image generation workflow or script
- User needs to replace interactive `az login` with non-interactive Azure authentication
- User wants Azure OpenAI `gpt-image-2` image generation from GitHub Actions or a Copilot-authored workflow

## Core guidance

1. Treat issue-assigned Copilot as a fresh hosted agent.
   - It cannot see locally installed Copilot skills or plugins.
   - It cannot reuse the user's local Azure CLI session.
   - It can only use repository files, issue instructions, allowed tools, and configured repository or environment secrets.

2. Put durable instructions in the repository.
   - Add scripts, workflow files, or documentation that Copilot can edit and run.
   - If a local skill already exists, copy the relevant behavior into repo-visible files instead of assuming the skill is installed.

3. Use non-interactive Azure authentication.
   - Prefer GitHub Actions OIDC with an Azure federated credential.
   - Use an Azure OpenAI API key only if the endpoint allows key auth and the key is stored as a GitHub secret.
   - Never ask the user to paste secrets into an issue body or chat prompt.

4. Keep generated images durable.
   - Azure OpenAI image URLs are temporary.
   - Download the image artifact into the repository workspace, attach it as a workflow artifact, or upload it to configured storage.

## Recommended architecture

Use this shape when the user wants Copilot to implement issue-driven image generation:

1. A script such as `scripts/generate-image.py` that accepts prompt, size, quality, style, and output path.
2. A GitHub Actions workflow such as `.github/workflows/generate-image.yml` that runs the script with configured authentication.
3. Repository or environment variables for non-secret values:
   - `AZURE_OPENAI_ENDPOINT`
   - `AZURE_OPENAI_IMAGE_DEPLOYMENT`
   - `AZURE_TENANT_ID`
   - `AZURE_CLIENT_ID`
   - `AZURE_SUBSCRIPTION_ID`
4. Repository or environment secrets only when required:
   - `AZURE_OPENAI_API_KEY` for key-based auth
5. A workflow artifact containing the generated image and metadata.

## GitHub Actions OIDC setup

Prefer OIDC when Azure RBAC is available.

Expected Azure setup:

1. Create or reuse a Microsoft Entra application or managed identity.
2. Add a federated credential that trusts the repository, branch, tag, or environment used by the workflow.
3. Assign the identity the `Azure AI User` role on the Azure OpenAI resource or the narrowest valid scope.
4. Store non-secret identifiers as repository variables or environment variables.

Workflow permissions must include:

```yaml
permissions:
  id-token: write
  contents: read
```

Use `azure/login` before running the image script:

```yaml
- name: Azure login
  uses: azure/login@v2
  with:
    client-id: ${{ vars.AZURE_CLIENT_ID }}
    tenant-id: ${{ vars.AZURE_TENANT_ID }}
    subscription-id: ${{ vars.AZURE_SUBSCRIPTION_ID }}
```

Then Python can use `DefaultAzureCredential`:

```python
from azure.identity import DefaultAzureCredential, get_bearer_token_provider
from openai import AzureOpenAI

token_provider = get_bearer_token_provider(
    DefaultAzureCredential(),
    "https://cognitiveservices.azure.com/.default",
)

client = AzureOpenAI(
    api_version="2024-02-01",
    azure_endpoint=azure_openai_endpoint,
    azure_ad_token_provider=token_provider,
)
```

## API key fallback

Use this only when the Azure OpenAI endpoint permits key authentication.

Required secret:

- `AZURE_OPENAI_API_KEY`

Python client shape:

```python
from openai import AzureOpenAI

client = AzureOpenAI(
    api_version="2024-02-01",
    azure_endpoint=azure_openai_endpoint,
    api_key=azure_openai_api_key,
)
```

If the API returns an error indicating key authentication is disabled, switch to OIDC and Azure RBAC.

## Issue prompt template

When the user asks for an issue prompt to assign to Copilot, provide something like this:

```markdown
Add repository-supported image generation using Azure OpenAI.

Requirements:
- Add a script that generates an image from a text prompt using the Azure OpenAI image deployment configured by environment variables.
- Support OIDC/RBAC authentication through `DefaultAzureCredential`; optionally support `AZURE_OPENAI_API_KEY` as a fallback only when present.
- Add a GitHub Actions workflow that can be manually dispatched with inputs for prompt, size, quality, style, and output filename.
- Upload generated images and metadata as workflow artifacts.
- Do not require interactive `az login`.
- Do not print secrets.
- Document required repository variables, secrets, Azure role assignment, and federated credential setup.
```

## Implementation checklist

When implementing the workflow, verify:

1. The workflow uses `workflow_dispatch` inputs for the image prompt and output options.
2. The workflow has `id-token: write` when OIDC is used.
3. The script downloads the temporary Azure OpenAI image URL to a persistent local file.
4. The workflow uploads the image as an artifact.
5. Errors clearly distinguish missing configuration, authentication failures, content filtering, and rate limits.
6. Logs never include API keys, access tokens, or generated temporary URLs unless the user explicitly accepts that exposure.

## Failure handling

- `401` or `403`: Check role assignment, federated credential subject, endpoint, tenant, and deployment name.
- `API key authentication disabled`: Use OIDC with Azure RBAC.
- `DefaultAzureCredential failed`: Confirm `azure/login` ran successfully and workflow permissions include `id-token: write`.
- `404 deployment not found`: Check that `AZURE_OPENAI_IMAGE_DEPLOYMENT` matches the deployment name, not only the model name.
- `429`: Add retry with exponential backoff or reduce usage.
- `content_filter`: Ask the user for a revised image prompt that complies with policy.

## Output expectations

For implementation tasks, produce repository files that Copilot can run without local setup. For explanation tasks, clearly separate local usage from issue-assigned Copilot usage and call out that local `az login` does not transfer to GitHub-hosted agents.