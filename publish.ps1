#!/usr/bin/env pwsh
<#
.SYNOPSIS
Release the skills hub: bump package metadata, validate APM, pack an archive, commit, tag, and push.

.DESCRIPTION
Run this after committing changes that should become a new hub release, including:
- new or changed local skills under skills/
- curated dependency updates in apm.yml/apm.lock.yaml
- documentation or metadata changes that affect consumers

.EXAMPLE
./publish.ps1

.EXAMPLE
./publish.ps1 -Version 1.2.0

.EXAMPLE
./publish.ps1 -DryRun
#>

[CmdletBinding()]
param(
    [string]$Version,
    [switch]$DryRun,
    [switch]$NoPush,
    [switch]$PublishGitHubSkill
)

$ErrorActionPreference = "Stop"

function Assert-Command {
    param([string]$Name)

    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "Required command not found: $Name"
    }
}

function Invoke-Step {
    param(
        [string]$Name,
        [scriptblock]$Action
    )

    Write-Host "`n==> $Name" -ForegroundColor Cyan
    & $Action
}

function Get-LatestTag {
    $tag = git describe --tags --abbrev=0 2>$null
    if (-not $tag) {
        return "v0.0.0"
    }

    return $tag
}

function Get-SuggestedVersion {
    param(
        [string]$LastTag,
        [string[]]$CommitSubjects
    )

    $version = $LastTag -replace '^v', ''
    $parts = $version -split '\.'

    if ($parts.Count -lt 3) {
        throw "Last tag '$LastTag' is not a semantic version tag. Expected vMAJOR.MINOR.PATCH."
    }

    [int]$major = $parts[0]
    [int]$minor = $parts[1]
    [int]$patch = $parts[2]

    $hasBreaking = $CommitSubjects -match 'BREAKING CHANGE|^[a-zA-Z]+(\([^)]+\))?!:'
    $hasFeature = $CommitSubjects -match '^feat(\([^)]+\))?:'
    $hasFix = $CommitSubjects -match '^fix(\([^)]+\))?:'

    if ($hasBreaking) {
        $major++
        $minor = 0
        $patch = 0
        $bump = "MAJOR"
    } elseif ($hasFeature) {
        $minor++
        $patch = 0
        $bump = "MINOR"
    } elseif ($hasFix) {
        $patch++
        $bump = "PATCH"
    } else {
        $patch++
        $bump = "PATCH"
    }

    return [pscustomobject]@{
        Version = "$major.$minor.$patch"
        Tag = "v$major.$minor.$patch"
        Bump = $bump
    }
}

function Set-ApmVersion {
    param([string]$PackageVersion)

    $apmPath = "apm.yml"
    $apmContent = Get-Content $apmPath -Raw
    if ($apmContent -notmatch '(?m)^version:\s*') {
        throw "Could not find version field in $apmPath"
    }

    $apmContent = $apmContent -replace '(?m)^version:\s*.*$', "version: $PackageVersion"
    Set-Content -Path $apmPath -Value $apmContent -NoNewline

    $pluginPath = "plugin.json"
    $plugin = Get-Content $pluginPath -Raw | ConvertFrom-Json
    $plugin.version = $PackageVersion
    $plugin | ConvertTo-Json -Depth 10 | Set-Content -Path $pluginPath
}

Write-Host "=== Skills Hub Release ===" -ForegroundColor Cyan

Assert-Command git
Assert-Command apm
Assert-Command npm

if ($PublishGitHubSkill) {
    Assert-Command gh
}

$status = git status --porcelain
if ($status) {
    Write-Host "`nUncommitted changes found:" -ForegroundColor Yellow
    Write-Host $status
    Write-Host "`nCommit or stash your skill/dependency changes before releasing. The release script creates its own metadata commit." -ForegroundColor Yellow
    exit 1
}

$lastTag = Get-LatestTag
$commits = @(git log "$lastTag..HEAD" --pretty=format:"%s" 2>$null)

if (-not $commits -and -not $Version) {
    Write-Host "No new commits since $lastTag. Nothing to release." -ForegroundColor Yellow
    exit 0
}

Write-Host "`nLast tag: $lastTag" -ForegroundColor Cyan
if ($commits) {
    Write-Host "`nCommits since ${lastTag}:" -ForegroundColor Cyan
    $commits | ForEach-Object { Write-Host "  $_" }
}

if ($Version) {
    $plainVersion = $Version -replace '^v', ''
    if ($plainVersion -notmatch '^\d+\.\d+\.\d+([-.+][0-9A-Za-z.-]+)?$') {
        throw "Version '$Version' is not a valid semantic version."
    }

    $releaseTag = "v$plainVersion"
    $bump = "manual"
} else {
    $suggestion = Get-SuggestedVersion -LastTag $lastTag -CommitSubjects $commits
    $plainVersion = $suggestion.Version
    $releaseTag = $suggestion.Tag
    $bump = $suggestion.Bump
}

Write-Host "`nRelease version: $releaseTag ($bump)" -ForegroundColor Green

$tagExists = git tag -l $releaseTag
if ($tagExists) {
    throw "Tag $releaseTag already exists. Choose another version."
}

if ($DryRun) {
    Invoke-Step "Validate APM package" {
        apm install --target copilot
        apm audit --ci
        apm compile --dry-run
        apm pack --dry-run --verbose
    }

    Write-Host "`nDry run complete. No files changed." -ForegroundColor Green
    exit 0
}

$confirm = Read-Host "`nRelease hub as $releaseTag? (Y/n)"
if ($confirm -eq 'n' -or $confirm -eq 'no') {
    Write-Host "Aborted." -ForegroundColor Yellow
    exit 1
}

Invoke-Step "Update package versions" {
    Set-ApmVersion -PackageVersion $plainVersion
}

Invoke-Step "Update changelog" {
    $ccExists = npm list -g conventional-changelog-cli 2>$null | Select-String -Quiet "conventional-changelog"
    if (-not $ccExists) {
        Write-Host "Installing conventional-changelog-cli..." -ForegroundColor Gray
        npm install -g conventional-changelog-cli --silent | Out-Null
    }

    conventional-changelog -p angular -i CHANGELOG.md -s | Out-Null
}

Invoke-Step "Validate APM package" {
    apm install --target copilot
    apm audit --ci
    apm compile --dry-run
    apm pack --dry-run --verbose
}

Invoke-Step "Pack release archive" {
    if (Test-Path dist) {
        Remove-Item dist -Recurse -Force
    }

    apm pack --archive -o ./dist
}

Invoke-Step "Commit release metadata" {
    git add CHANGELOG.md apm.yml plugin.json
    if (Test-Path apm.lock.yaml) {
        git add apm.lock.yaml
    }

    git commit -m "chore: release $releaseTag" | Out-Null
}

Invoke-Step "Create release tag" {
    git tag $releaseTag
}

if ($PublishGitHubSkill) {
    Invoke-Step "Publish legacy GitHub skill package" {
        gh skill publish --tag $releaseTag
    }
}

if (-not $NoPush) {
    Invoke-Step "Push release commit and tag" {
        git push origin HEAD
        git push origin $releaseTag
    }
} else {
    Write-Host "`nSkipping push because -NoPush was specified." -ForegroundColor Yellow
    Write-Host "Push later with:" -ForegroundColor Cyan
    Write-Host "  git push origin HEAD" -ForegroundColor Gray
    Write-Host "  git push origin $releaseTag" -ForegroundColor Gray
}

Write-Host "`nRelease complete: $releaseTag" -ForegroundColor Green
Write-Host "`nConsumer install:" -ForegroundColor Cyan
Write-Host "  apm install sujithq/skills#$releaseTag --target copilot" -ForegroundColor Gray
Write-Host "`nArchive output:" -ForegroundColor Cyan
Write-Host "  dist/sujithq-skills-$plainVersion.tar.gz" -ForegroundColor Gray
