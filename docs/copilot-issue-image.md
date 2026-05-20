# Use Copilot Issue Image Generation in a New Repository

This guide shows how to start from scratch in a new GitHub repository and use the `copilot-issue-image` skill to prepare an issue that GitHub Copilot can implement. The goal is image generation with Azure OpenAI from a GitHub-hosted workflow, without relying on local `az login`.

## What this skill is for

Use this skill when you want to assign an issue to GitHub Copilot and have Copilot add repository-supported image generation using Azure OpenAI.

The skill helps you produce instructions for a hosted Copilot coding-agent flow. In that flow:

- Locally installed skills and plugins are not automatically available to the GitHub-hosted agent.
- Your local Azure CLI login is not available to the hosted agent.
- Authentication must be configured through repository-visible workflow files, GitHub variables, GitHub secrets, and Azure identity setup.

## How the flow works

The `copilot-issue-image` skill does not run inside issue-assigned Copilot automatically. Use it locally to draft a strong issue prompt, then assign that issue to Copilot.

The practical flow is:

1. You use this skill locally to draft the issue and implementation requirements.
2. GitHub Copilot reads the assigned issue and opens a pull request that adds or updates repository files.
3. The repository contains the durable image-generation machinery: a script, a GitHub Actions workflow, and setup documentation.
4. GitHub Actions runs that workflow later and authenticates to Azure with OIDC and Azure RBAC.
5. The workflow calls Azure OpenAI and uploads generated images as artifacts.

In short: provision the workflow path in the target repository. Copilot builds or changes the machinery; GitHub Actions runs the machinery.

## Prerequisites

You need:

- A GitHub repository where GitHub Copilot coding agent can be assigned to issues.
- Permission to create issues and configure repository variables or secrets.
- An Azure subscription.
- An Azure OpenAI resource with an image generation deployment, such as `gpt-image-2`.
- Permission to create or use a Microsoft Entra application or managed identity.
- Permission to assign the `Azure AI User` role on the Azure OpenAI resource or an appropriate narrow scope.
- GitHub CLI and Copilot CLI locally if you want to install and invoke this skill from your machine.

Optional fallback:

- An Azure OpenAI API key stored as a GitHub secret, only if key authentication is enabled for the Azure OpenAI resource.

## Recommended authentication

Use GitHub Actions OIDC with Azure RBAC.

This avoids long-lived cloud credentials in GitHub secrets. The workflow requests a short-lived token from GitHub, Azure trusts that token through a federated credential, and the image generation script authenticates with `DefaultAzureCredential`.

Use API-key authentication only when OIDC is not available and the Azure OpenAI endpoint permits key authentication.

## Provisioning checklist

Before assigning the issue to Copilot, prepare the target repository and Azure identity path:

1. In Azure, create or choose an Azure OpenAI resource.
2. Deploy an image model, such as `gpt-image-2`.
3. Create or choose a Microsoft Entra application or managed identity for GitHub Actions.
4. Assign that identity the `Azure AI User` role on the Azure OpenAI resource or the narrowest working scope.
5. Add a federated credential for the repository, branch, or GitHub Environment that will run the workflow.
6. Add the required GitHub repository or environment variables.
7. Create the issue and assign it to Copilot so it can add the workflow, script, and docs.

The issue-assigned Copilot agent should not be expected to authenticate interactively or use local credentials. It should produce repository changes that allow GitHub Actions to authenticate later.

## Step 1: Create or choose a repository

Create a new repository in GitHub, then clone it locally if needed:

```powershell
gh repo create OWNER/REPO --private --clone
Set-Location REPO
```

You can also use an existing repository. The rest of this guide assumes the target repository is the repository where Copilot will open a pull request.

## Step 2: Prepare Azure OpenAI

Create or identify these Azure resources:

1. An Azure OpenAI resource.
2. An image model deployment, for example a `gpt-image-2` deployment.
3. A Microsoft Entra application or managed identity for GitHub Actions.

Record these values:

- Azure subscription ID
- Tenant ID
- Client ID for the app or identity
- Azure OpenAI endpoint, such as `https://YOUR-RESOURCE.openai.azure.com/`
- Azure OpenAI image deployment name

Assign the identity the `Azure AI User` role on the Azure OpenAI resource or the narrowest valid scope for your environment.

## Step 3: Add a federated credential

Configure the Microsoft Entra application or managed identity to trust your GitHub repository.

For a branch-based workflow, the federated credential subject usually looks like this:

```text
repo:OWNER/REPO:ref:refs/heads/main
```

For a GitHub Environment based workflow, the subject usually looks like this:

```text
repo:OWNER/REPO:environment:ENVIRONMENT_NAME
```

Use the exact repository owner, repository name, branch, or environment that your workflow will use.

## Step 4: Configure GitHub variables and secrets

Add these repository or environment variables:

- `AZURE_CLIENT_ID`
- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`
- `AZURE_OPENAI_ENDPOINT`
- `AZURE_OPENAI_IMAGE_DEPLOYMENT`

If you must use API-key fallback, add this repository or environment secret:

- `AZURE_OPENAI_API_KEY`

Do not put secrets in issue bodies, pull request descriptions, workflow logs, or committed files.

## Step 5: Install the skill locally

Install the full plugin:

```powershell
copilot plugin install sujithq/skills
```

Or install only this skill:

```powershell
gh skill install sujithq/skills copilot-issue-image
```

Then open Copilot CLI and confirm the skill is available:

```text
copilot
/skills list
/skills info copilot-issue-image
```

## Step 6: Use the skill to draft a Copilot issue

Ask Copilot locally to use the skill and draft an issue for your target repository. Example prompt:

```text
Use the copilot-issue-image skill to draft a GitHub issue for a new repository.
The issue should ask Copilot to add Azure OpenAI image generation using GitHub Actions OIDC, DefaultAzureCredential, workflow_dispatch inputs, and workflow artifacts.
Use Azure AI User as the required Azure role.
Include setup documentation and avoid interactive az login.
```

Review the issue before assigning it to Copilot. Make sure it does not include secrets.

## Copyable issue prompt

Use this as a starting point when creating the GitHub issue:

```markdown
Add repository-supported image generation using Azure OpenAI.

Context:
- This repository should be able to generate images from a manually dispatched GitHub Actions workflow.
- The workflow must run in GitHub-hosted automation and must not depend on local `az login`.
- Azure authentication should use GitHub Actions OIDC with Azure RBAC.
- The Azure identity has the `Azure AI User` role on the Azure OpenAI resource.

Requirements:
- Add a Python script, such as `scripts/generate-image.py`, that generates an image from a text prompt using Azure OpenAI.
- Read configuration from environment variables:
  - `AZURE_OPENAI_ENDPOINT`
  - `AZURE_OPENAI_IMAGE_DEPLOYMENT`
  - `AZURE_OPENAI_API_KEY`, only as an optional fallback when present
- Authenticate with `DefaultAzureCredential` by default.
- Add a GitHub Actions workflow, such as `.github/workflows/generate-image.yml`, with `workflow_dispatch` inputs for:
  - prompt
  - size
  - quality
  - style
  - output filename
- Include workflow permissions for OIDC:
  - `id-token: write`
  - `contents: read`
- Use `azure/login@v2` with repository or environment variables:
  - `AZURE_CLIENT_ID`
  - `AZURE_TENANT_ID`
  - `AZURE_SUBSCRIPTION_ID`
- Download the temporary Azure OpenAI image URL to a durable file in the workflow workspace.
- Upload the generated image and metadata as workflow artifacts.
- Add documentation explaining prerequisites, required GitHub variables and secrets, Azure role assignment, and how to run the workflow.
- Do not print secrets, access tokens, or API keys.
- Clearly handle missing configuration, authentication failures, content filtering, rate limits, and deployment-name errors.
```

## Step 7: Assign the issue to Copilot

After the issue is created:

1. Open the issue in GitHub.
2. Assign it to Copilot if Copilot coding agent is enabled for the repository and organization.
3. Let Copilot create a pull request.
4. Review the generated files before merging.

The expected pull request should usually add:

- `scripts/generate-image.py`
- `.github/workflows/generate-image.yml`
- Documentation for setup and workflow usage
- Dependency installation in the workflow, usually `openai` and `azure-identity`

## Step 8: Run the workflow

After the pull request is merged:

1. Open the repository in GitHub.
2. Go to Actions.
3. Select the image generation workflow.
4. Choose Run workflow.
5. Enter the prompt and image options.
6. Download the generated image artifact when the workflow completes.

## Troubleshooting

`DefaultAzureCredential failed`

Check that the workflow has `id-token: write`, `azure/login@v2` ran successfully, and the federated credential matches the repository, branch, or environment.

`401` or `403`

Check the Azure OpenAI endpoint, tenant, client ID, role assignment, and federated credential subject. Confirm the identity has `Azure AI User` on the Azure OpenAI resource or an appropriate scope.

`404 deployment not found`

Confirm `AZURE_OPENAI_IMAGE_DEPLOYMENT` is the deployment name, not just the model name.

`API key authentication disabled`

Remove API-key fallback and use OIDC with Azure RBAC.

`429`

Reduce usage or add retry with exponential backoff.

`content_filter`

Revise the image prompt to comply with content policy.

## Security notes

- Prefer OIDC over long-lived secrets.
- Never include API keys, tokens, or client secrets in issue text.
- Use repository environments if you need approvals before image generation runs.
- Scope Azure role assignments as narrowly as practical.
- Treat generated image URLs as temporary and avoid logging them unless the repository owner accepts that exposure.
