#!/usr/bin/env pwsh
<#
.SYNOPSIS
Automated publish script: suggests version, updates changelog, commits, and publishes skills.

.EXAMPLE
./publish.ps1
#>

$ErrorActionPreference = "Stop"

Write-Host "=== GitHub Skills Publisher ===" -ForegroundColor Cyan

# Check for uncommitted changes
$status = git status --porcelain
if ($status) {
    Write-Host "⚠ Uncommitted changes found:" -ForegroundColor Yellow
    Write-Host $status
    $proceed = Read-Host "Continue anyway? (y/n)"
    if ($proceed -ne 'y') {
        Write-Host "Aborted." -ForegroundColor Yellow
        exit 1
    }
}

# Get last tag
$lastTag = git describe --tags --abbrev=0 2>$null
if (-not $lastTag) {
    Write-Host "No tags found. Starting from v1.0.0" -ForegroundColor Yellow
    $lastTag = "v0.0.0"
}

Write-Host "`nLast tag: $lastTag" -ForegroundColor Cyan

# Get commits since last tag
$commits = git log "$lastTag..HEAD" --pretty=format:"%s" 2>$null

if (-not $commits) {
    Write-Host "No new commits since $lastTag" -ForegroundColor Yellow
    exit 0
}

Write-Host "`nCommits since $lastTag`:" -ForegroundColor Cyan
$commits | ForEach-Object { Write-Host "  $_" }

# Parse version
$version = $lastTag -replace '^v', ''
$parts = $version -split '\.'
[int]$major = $parts[0]
[int]$minor = $parts[1]
[int]$patch = $parts[2]

# Analyze commit types
$hasBreaking = $commits -match 'BREAKING CHANGE|^!:'
$hasFeature = $commits -match '^feat(\(.*\))?:'
$hasFix = $commits -match '^fix(\(.*\))?:'

# Suggest version bump
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
    Write-Host "`n⚠ No conventional commits (feat/fix/BREAKING). Treating as PATCH." -ForegroundColor Yellow
    $patch++
    $bump = "PATCH"
}

$suggestedVersion = "v$major.$minor.$patch"

Write-Host "`n✓ Suggested version: $suggestedVersion ($bump)" -ForegroundColor Green

# Allow override
$userVersion = Read-Host "Version to publish (or press Enter to use suggested)"
if ($userVersion) {
    $suggestedVersion = $userVersion
    if (-not $suggestedVersion.StartsWith('v')) {
        $suggestedVersion = "v$suggestedVersion"
    }
    Write-Host "Using: $suggestedVersion" -ForegroundColor Cyan
}

# Confirm
$confirm = Read-Host "`nPublish skills as $suggestedVersion`? (Y/n)"
if ($confirm -eq 'n' -or $confirm -eq 'no') {
    Write-Host "Aborted." -ForegroundColor Yellow
    exit 1
}

# Update changelog
Write-Host "`n[1/3] Updating CHANGELOG.md..." -ForegroundColor Cyan
try {
    # Check if conventional-changelog is installed
    $ccExists = npm list -g conventional-changelog-cli 2>$null | Select-String -Quiet "conventional-changelog"
    if (-not $ccExists) {
        Write-Host "  Installing conventional-changelog-cli..." -ForegroundColor Gray
        npm install -g conventional-changelog-cli --silent | Out-Null
    }
    
    conventional-changelog -p angular -i CHANGELOG.md -s | Out-Null
    Write-Host "  ✓ CHANGELOG.md updated" -ForegroundColor Green
} catch {
    Write-Host "  ✘ Failed to update changelog: $_" -ForegroundColor Red
    exit 1
}

# Commit
Write-Host "[2/3] Committing changes..." -ForegroundColor Cyan
try {
    git add CHANGELOG.md
    git config user.email "user@example.com" 2>$null
    git config user.name "Skill Publisher" 2>$null
    git commit -m "docs: update changelog for $suggestedVersion" | Out-Null
    Write-Host "  ✓ Committed" -ForegroundColor Green
} catch {
    Write-Host "  ✘ Commit failed: $_" -ForegroundColor Red
    exit 1
}

# Publish
Write-Host "[3/3] Publishing skills..." -ForegroundColor Cyan
try {
    gh skill publish --tag $suggestedVersion
    Write-Host "  ✓ Published $suggestedVersion" -ForegroundColor Green
} catch {
    Write-Host "  ✘ Publish failed: $_" -ForegroundColor Red
    Write-Host "  Note: CHANGELOG was committed. You can retry with: gh skill publish --tag $suggestedVersion" -ForegroundColor Yellow
    exit 1
}

Write-Host "`n✓ Done! Published $suggestedVersion" -ForegroundColor Green
Write-Host "`nInstall with:`n  gh skill install sujithq/skills`n" -ForegroundColor Cyan
