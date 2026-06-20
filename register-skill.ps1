# Register a local Copilot CLI skill as its own GitHub repo and add it to the manifest.
#
# Given a skill folder under ~\.copilot\skills, this will:
#   1. git init (if needed) and commit the skill
#   2. create the GitHub repo and push (or reuse it if it already exists)
#   3. add the skill to skills-manifest.json (so clone-skills.ps1 picks it up)
#   4. commit + push that manifest change back to this repo (unless -NoCommit)
#
# Examples:
#   .\register-skill.ps1 my-new-skill
#   .\register-skill.ps1 my-new-skill -RepoName my-new-skill-skill -Private
#
# Run this AFTER: gh auth login

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Name,              # skill folder name under ~\.copilot\skills

    [string]$RepoName,          # GitHub repo name (default: same as $Name)
    [string]$Owner = "shanselman",
    [switch]$Private,           # create the repo private (default: public)
    [switch]$NoCommit           # don't auto-commit the manifest change to this repo
)

$ErrorActionPreference = "Stop"

$skillsRoot   = Join-Path $env:USERPROFILE ".copilot\skills"
$skillPath    = Join-Path $skillsRoot $Name
$manifestPath = Join-Path $PSScriptRoot "skills-manifest.json"

if (-not $RepoName) { $RepoName = $Name }
$repoSlug = "$Owner/$RepoName"

# Verify the skill folder exists
if (-not (Test-Path $skillPath -PathType Container)) {
    Write-Host "ERROR: Skill folder not found: $skillPath" -ForegroundColor Red
    exit 1
}

# Verify gh is authenticated
gh auth status 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Not authenticated to GitHub. Run 'gh auth login' first." -ForegroundColor Red
    exit 1
}

Write-Host "Registering skill '$Name' as $repoSlug ..." -ForegroundColor Green

Push-Location $skillPath
try {
    # 1. Init git repo if needed
    if (-not (Test-Path (Join-Path $skillPath ".git"))) {
        Write-Host "Initializing git repo" -ForegroundColor Cyan
        git init -b main | Out-Null
    }

    # 2. Make sure everything is committed
    git add -A
    $hasCommits = $false
    git rev-parse --verify HEAD 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) { $hasCommits = $true }

    if (-not $hasCommits) {
        git commit -q -m "Initial commit of $Name skill"
    } elseif (git status --porcelain) {
        git commit -q -m "Update $Name skill"
    }

    # 3. Create the GitHub repo (or reuse if it already exists)
    gh repo view $repoSlug 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Repo $repoSlug already exists; wiring up remote + pushing" -ForegroundColor Yellow
        if (-not (git remote)) {
            git remote add origin "https://github.com/$repoSlug.git"
        }
        git push -u origin HEAD
    } else {
        $visibility = if ($Private) { "--private" } else { "--public" }
        Write-Host "Creating GitHub repo $repoSlug ($visibility)" -ForegroundColor Cyan
        gh repo create $repoSlug --source . --push $visibility
    }
}
finally {
    Pop-Location
}

# 4. Update the manifest (kept alphabetically sorted for clean diffs)
$map = [ordered]@{}
if (Test-Path $manifestPath) {
    $existing = Get-Content $manifestPath -Raw | ConvertFrom-Json
    foreach ($prop in $existing.PSObject.Properties) { $map[$prop.Name] = $prop.Value }
}
$map[$Name] = $repoSlug

$sorted = [ordered]@{}
foreach ($key in ($map.Keys | Sort-Object)) { $sorted[$key] = $map[$key] }

$sorted | ConvertTo-Json | Set-Content -Path $manifestPath -Encoding UTF8
Write-Host "Updated manifest: $Name -> $repoSlug" -ForegroundColor Green

# 5. Commit the manifest change back to this repo
if (-not $NoCommit -and (Test-Path (Join-Path $PSScriptRoot ".git"))) {
    Push-Location $PSScriptRoot
    try {
        git add skills-manifest.json
        if (git status --porcelain skills-manifest.json) {
            git commit -q -m "Register skill: $Name ($repoSlug)"
            git push
            Write-Host "Committed manifest update to this repo" -ForegroundColor Green
        }
    }
    finally {
        Pop-Location
    }
}

Write-Host ""
Write-Host "Done! '$Name' is now a repo ($repoSlug) and tracked in the manifest." -ForegroundColor Green
