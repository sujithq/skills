#!/usr/bin/env pwsh
<#
.SYNOPSIS
Suggest next semantic version based on conventional commits since last tag.

.EXAMPLE
./suggest-version.ps1
#>

# Get last tag
$lastTag = git describe --tags --abbrev=0 2>$null
if (-not $lastTag) {
    Write-Host "No tags found. Starting from v1.0.0" -ForegroundColor Yellow
    $lastTag = "v0.0.0"
}

Write-Host "Last tag: $lastTag" -ForegroundColor Cyan

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
    Write-Host "No conventional commits found (feat/fix/BREAKING). No version bump needed." -ForegroundColor Yellow
    exit 0
}

$suggestedVersion = "v$major.$minor.$patch"

Write-Host "`n✓ Suggested next version: $suggestedVersion ($bump)" -ForegroundColor Green
Write-Host "`nTo publish:`n" -ForegroundColor Cyan
Write-Host "  git add ." -ForegroundColor Gray
Write-Host "  git commit -m ""feat: describe your change"""
Write-Host "  gh skill publish --tag $suggestedVersion" -ForegroundColor Green
