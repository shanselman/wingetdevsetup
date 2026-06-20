# WinGet Dev Setup - Session Notes
**Date:** 2025-12-23  
**Repository:** https://github.com/shanselman/wingetdevsetup

## Overview
Built a complete Windows dev machine setup using WinGet DSC (Desired State Configuration) for Scott Hanselman's personal machine configuration.

## Key Files
- `hanselman.dev.dsc.yml` - Main DSC configuration file
- `boot.ps1` - Bootstrap script (runs DSC from URL with cache-busting)
- `clone-repos.ps1` - Clones repos and sets up Nightscout URL from private gist
- `clone-skills.ps1` - Clones/updates the Copilot CLI skills that are standalone Git repos into `~\.copilot\skills`
- `Microsoft.PowerShell_profile.ps1` - PowerShell 7 profile
- `hanselman.omp.json` - Oh My Posh theme configuration
- `.vsconfig` - Visual Studio workloads/components

## Installation Command
```powershell
irm https://raw.githubusercontent.com/shanselman/wingetdevsetup/master/boot.ps1 | iex
```

Then after:
```powershell
gh auth login
.\clone-repos.ps1
.\clone-skills.ps1
```

## What's Installed

### Development Tools
- Git, GitHub CLI, GitHub Copilot CLI
- VS Code, VS Code Insiders
- Visual Studio 2026 Community (with .vsconfig workloads)
- .NET SDK 10
- NVM for Windows + Node LTS
- Python 3.12
- Docker Desktop

### AI/ML Tools
- Foundry Local
- LM Studio
- Ollama
- Claude Code
- Goose
- Gemini CLI (via npm)

### Terminal/Shell
- Windows Terminal
- PowerShell 7
- Oh My Posh
- GNU Midnight Commander
- Terminal-Icons module
- z module (directory jumping)

### System Tools
- WSL + Ubuntu 24.04
- 1Password
- PowerToys
- gsudo
- Windows App (Remote Desktop)
- FilePilot

### Communication
- Slack
- Okta Verify (from https://gh.io/ov-windows)

### Media
- VLC media player
- Netflix

### Custom Installs (from GitHub releases)
- Handy (https://github.com/cjpais/Handy)

### Windows Settings
- Dev Drive (D:, 50GB, ReFS)
- Show file extensions in Explorer
- Hide widgets from taskbar
- D:\github folder created

## Major Issues Fixed

### 1. Visual Studio Override Not Supported
**Problem:** `WinGetPackage` DSC resource doesn't support `override` property.

**Solution:** Created separate `Script` resource to download .vsconfig and run `vs_installer.exe modify` after VS installation.

### 2. NVM Path Wrong
**Problem:** Script assumed `$env:APPDATA\nvm` but winget installs to `$env:LOCALAPPDATA\nvm`.

**Solution:** Changed path from `APPDATA` to `LOCALAPPDATA`.

### 3. PowerShell Profile $PROFILE Variable
**Problem:** `$PROFILE` variable not available in DSC Script context (Windows PowerShell 5.1).

**Solution:** 
- Use explicit paths: `$env:USERPROFILE\Documents\PowerShell\` (PS7) and `$env:USERPROFILE\Documents\WindowsPowerShell\` (PS5.1)
- Install profiles for BOTH PowerShell versions since DSC runs in PS 5.1 but users use PS 7

### 4. PowerShellGet Module Loading Issues
**Problem:** PowerShellGet couldn't be loaded in PS7 when called from DSC context.

**Attempts:**
- Import-Module explicitly - failed
- Script blocks - failed
- Here-strings (@'...'@) - broke YAML syntax

**Final Solution:** Use `Install-PSResource` (built into PS7.4+) instead of `Install-Module` (requires PowerShellGet).

### 5. YAML Syntax Errors
**Problem:** PowerShell here-strings (`@"..."@` and `@'...'@`) break YAML parsing.

**Solution:** Use arrays joined with newlines instead:
```yaml
$scriptLines = @(
  "line 1",
  "line 2"
)
$scriptLines -join "`n" | Out-File ...
```

### 6. GitHub CDN Caching
**Problem:** Raw GitHub URLs cache for several minutes, causing stale DSC file downloads.

**Solution:** Added cache-busting timestamp parameter in boot.ps1:
```powershell
$cacheBust = "?v=$(Get-Date -Format 'yyyyMMddHHmmss')"
$dscDevUri = $dscUri + $dscDev + $cacheBust
```

### 7. Nightscout URL Parsing
**Problem:** Private gist contains "Nightscout URL\n\nhttps://..." but Oh My Posh theme expects just the URL.

**Solution:** Extract URL with regex in clone-repos.ps1:
```powershell
$matched = $nightscoutRaw -match '(https://[^\s]+)'
if ($matched) {
    $nightscoutUrl = $matches[1]
}
```

**Note:** Store match result in variable BEFORE accessing `$matches[1]` to avoid "Cannot index into a null array" error.

### 8. Oh My Posh Config Environment Variables Don't Work
**Problem:** Oh My Posh JSON config files don't expand environment variables. Using `{{ .Env.VAR }}` in the `url` property failed - template syntax only works in the `template` property, not in `properties`/`options`.

**Attempts:**
- `{{ .Env.OSTENSIBLY_NIGHTSCOUT_URL }}` - Failed, tried to use literal string as URL
- `$env:OSTENSIBLY_NIGHTSCOUT_URL` - Failed, JSON doesn't expand PowerShell variables

**Final Solution:** Dynamically generate the Oh My Posh config during DSC setup:
1. Download template JSON from repo
2. Fetch Nightscout URL from private gist
3. Replace placeholder `$env:OSTENSIBLY_NIGHTSCOUT_URL` with actual URL using string replace
4. Write the final config file with embedded URL

```powershell
$ompTemplate = Invoke-WebRequest -Uri "$repoBase/hanselman.omp.json" -UseBasicParsing | Select-Object -ExpandProperty Content
$gistContent = (Invoke-WebRequest -Uri "https://gist.../raw" -UseBasicParsing).Content
if ($gistContent -match '(https://[^\s]+)') {
    $nightscoutUrl = $matches[1]
    $ompTemplate = $ompTemplate -replace '\$env:OSTENSIBLY_NIGHTSCOUT_URL', $nightscoutUrl
}
$ompTemplate | Out-File -FilePath $ompThemePath -Encoding UTF8
```

### 8. .NET SDK Package ID
**Problem:** Used `Microsoft.DotNet.SDK.Preview` but correct ID is `Microsoft.DotNet.SDK.10`.

**Solution:** Changed package ID to `Microsoft.DotNet.SDK.10`.

## Technical Decisions

### PowerShell Module Installation
- Created temporary script file instead of using script blocks (better compatibility)
- Use `Install-PSResource` instead of `Install-Module` (avoids PowerShellGet issues)
- Install to CurrentUser scope
- Trust PSGallery repository

### Profile Setup
- Install profile to BOTH PowerShell 7 and Windows PowerShell 5.1 directories
- Download Oh My Posh theme to user profile directory
- Install CascadiaCode Nerd Font
- Configure Windows Terminal to use the font
- Load Nightscout URL from private gist with error handling

### Clone Script Reentrant Design
- Check if repo directory exists before cloning
- Skip existing repos with yellow warning
- Continue with remaining repos
- Safe to run multiple times

## Oh My Posh Environment Variable
The theme template uses `$env:OSTENSIBLY_NIGHTSCOUT_URL` as a **placeholder** that gets replaced during DSC setup with the actual URL from the private gist. JSON files don't support environment variable expansion, so we dynamically generate the final config file.

**Important:** Go template syntax like `{{ .Env.VAR }}` only works in the `template` property, NOT in `properties`/`options` fields like `url`.

## Private Gist
- ID: `985fa5febe6dbf7f2df70d6582d734d9`
- Contains: Nightscout URL
- Accessed via: `gh gist view <id> --raw`
- Parsed to extract URL only

## Repository List (clone-repos.ps1)
- azurefridayaggregator
- hanselminutes-core
- HanselminutesAdmin
- WindowsEdgeLight
- hanselman-core
- devchangelog
- azure-friday-yaml
- azurefridayanalysis
- LLMStudyGuide
- babysmashwebsite
- babysmash

## Copilot Skills List (clone-skills.ps1)
Standalone-repo skills cloned into `~\.copilot\skills` (local folder name -> repo):
- hanselman-code-review -> shanselman/hanselman-code-review-skill
- loop -> shanselman/loop-cli
- nightscout-cgm -> shanselman/nightscout-cgm-skill
- ttt-triage -> shanselman/ttt-triage-skill
- weekly-snapshot-skill -> shanselman/weekly-snapshot-skill
- windows-terminal -> shanselman/windows-terminal-copilot-skill

Bundled skills (docx, pptx, xlsx, etc.) ship with Copilot / other apps and are intentionally NOT cloned.

## Apps NOT in WinGet (removed or noted)
- Toad - Linux only, removed from setup
- Gemini CLI - installed via npm instead

## Installation Flow
1. Run boot.ps1 (downloads and runs DSC)
2. DSC installs all packages, configures Windows
3. User runs `gh auth login`
4. User runs `.\clone-repos.ps1` to clone repos and set Nightscout URL env var
5. User runs `.\clone-skills.ps1` to clone/update Copilot CLI skill repos
6. Profile loads on next PowerShell launch with Oh My Posh + Nightscout data

## Key Learnings
1. DSC runs in Windows PowerShell 5.1 context even when installing PowerShell 7
2. Always use explicit paths instead of automatic variables like `$PROFILE`
3. Avoid here-strings in YAML (use arrays with `-join`)
4. GitHub CDN caches aggressively - add cache-busting for dynamic content
5. Always store regex match result before accessing `$matches` array
6. Use `Install-PSResource` in PS7.4+ instead of `Install-Module`
7. Script resources should be idempotent (TestScript returns false = always run is OK for setup)

## Status
✅ All core functionality working
✅ All apps installing successfully
✅ Nightscout URL parsing working
✅ PowerShell modules installing via PSResource
⚠️ PowerShell profile module installation had issues but workaround implemented
