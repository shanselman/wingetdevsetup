# Clone Scott Hanselman's GitHub Copilot CLI skills that live in their own repos
# Run this AFTER: gh auth login
#
# Only the skills that are standalone Git repos are handled here. The bundled
# skills (docx, pptx, xlsx, etc.) ship with Copilot / other apps and are not cloned.
# Safe to re-run: existing skills are pulled (fast-forward), missing ones are cloned.

$skillsRoot = Join-Path $env:USERPROFILE ".copilot\skills"

# Verify gh is authenticated
$authStatus = gh auth status 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Not authenticated to GitHub. Run 'gh auth login' first." -ForegroundColor Red
    exit 1
}

# Ensure the skills folder exists
if (-not (Test-Path $skillsRoot)) {
    Write-Host "Creating skills folder: $skillsRoot" -ForegroundColor Cyan
    New-Item -ItemType Directory -Path $skillsRoot -Force | Out-Null
}

Write-Host "Authenticated to GitHub. Syncing skills to $skillsRoot..." -ForegroundColor Green

# Map of local skill folder name -> GitHub repo.
# The local folder name is what Copilot uses, and sometimes differs from the repo name.
$skills = [ordered]@{
    "hanselman-code-review" = "shanselman/hanselman-code-review-skill"
    "loop"                  = "shanselman/loop-cli"
    "nightscout-cgm"        = "shanselman/nightscout-cgm-skill"
    "ttt-triage"            = "shanselman/ttt-triage-skill"
    "weekly-snapshot-skill" = "shanselman/weekly-snapshot-skill"
    "windows-terminal"      = "shanselman/windows-terminal-copilot-skill"
}

foreach ($skill in $skills.GetEnumerator()) {
    $folderName = $skill.Key
    $repo       = $skill.Value
    $targetPath = Join-Path $skillsRoot $folderName

    if (Test-Path (Join-Path $targetPath ".git")) {
        Write-Host "Updating: $folderName" -ForegroundColor Cyan
        Push-Location $targetPath
        $status = git status --porcelain
        if ($status) {
            Write-Host "  SKIP pull: $folderName has local changes" -ForegroundColor Yellow
        } else {
            git pull --ff-only
        }
        Pop-Location
    } elseif (Test-Path $targetPath) {
        Write-Host "SKIP: $folderName exists but is not a git repo" -ForegroundColor Yellow
    } else {
        Write-Host "Cloning: $repo -> $folderName" -ForegroundColor Cyan
        gh repo clone $repo $targetPath
    }
}

Write-Host ""
Write-Host "Done! Your repo-based skills are in $skillsRoot" -ForegroundColor Green
