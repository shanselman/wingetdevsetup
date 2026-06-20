# WinGet Dev Setup

Scott Hanselman's complete Windows dev machine setup. One script installs everything via [WinGet DSC](https://learn.microsoft.com/en-us/windows/package-manager/configuration/), then post-setup scripts clone repos and sync [GitHub Copilot CLI](https://github.com/features/copilot) skills.

## Quick Start

```powershell
# 1. Run the bootstrap (installs WinGet, runs DSC config)
irm https://raw.githubusercontent.com/shanselman/wingetdevsetup/master/boot.ps1 | iex

# 2. Authenticate to GitHub
gh auth login

# 3. Clone your repos
.\clone-repos.ps1

# 4. Sync your Copilot CLI skills
.\clone-skills.ps1
```

## What's in the Box

| File | Purpose |
|------|---------|
| `boot.ps1` | Bootstrap — ensures WinGet is ready, runs the DSC config from this repo |
| `hanselman.dev.dsc.yml` | WinGet DSC configuration (apps, Windows settings, dev drives) |
| `clone-repos.ps1` | Clones project repos to `D:\github` and configures Nightscout env var |
| `clone-skills.ps1` | Clones/updates Copilot CLI skill repos into `~\.copilot\skills` |
| `register-skill.ps1` | Turns a local skill folder into its own GitHub repo + updates the manifest |
| `skills-manifest.json` | Source-of-truth map of skill folder names → GitHub repos |
| `Microsoft.PowerShell_profile.ps1` | PowerShell 7 profile (Oh My Posh, modules, aliases) |
| `hanselman.omp.json` | Oh My Posh theme |
| `.vsconfig` | Visual Studio workload/component selection |

## Copilot CLI Skills

Skills live in `~\.copilot\skills`. Some are standalone Git repos (code you author/customize), and some are bundled by Copilot or other apps (docx, pptx, xlsx, etc.).

The standalone repo-based skills are tracked in **`skills-manifest.json`**:

```json
{
  "hanselman-code-review": "shanselman/hanselman-code-review-skill",
  "loop": "shanselman/loop-cli",
  "nightscout-cgm": "shanselman/nightscout-cgm-skill",
  "ttt-triage": "shanselman/ttt-triage-skill",
  "weekly-snapshot-skill": "shanselman/weekly-snapshot-skill",
  "windows-terminal": "shanselman/windows-terminal-copilot-skill"
}
```

The key is the **local folder name** (what Copilot sees), and the value is the **GitHub repo**.

### Syncing skills on a new machine

```powershell
.\clone-skills.ps1
```

This reads `skills-manifest.json` and for each entry:
- **Missing?** → clones it
- **Already cloned?** → fast-forward pulls (skips if there are local changes)

Safe to run repeatedly.

### Registering a new skill

When you create a new skill locally and want to track it across machines:

```powershell
# Basic — creates a public repo with the same name as the folder
.\register-skill.ps1 my-new-skill

# Custom repo name
.\register-skill.ps1 my-new-skill -RepoName my-new-skill-skill

# Private repo
.\register-skill.ps1 my-new-skill -Private

# Don't auto-commit the manifest change to this repo
.\register-skill.ps1 my-new-skill -NoCommit
```

What it does:
1. `git init` + commit the skill folder (if not already a repo)
2. `gh repo create` + push (or reuse an existing repo)
3. Append to `skills-manifest.json` (sorted alphabetically)
4. Commit + push that manifest change back to this repo

After registering, the skill will be cloned automatically by `clone-skills.ps1` on any other machine.

## What Gets Installed (DSC)

### Development
- Git, GitHub CLI, GitHub Copilot CLI
- VS Code + VS Code Insiders
- Visual Studio 2026 Community (with `.vsconfig` workloads)
- .NET SDK 10, Python 3.12, NVM + Node LTS
- Docker Desktop

### AI/ML
- Foundry Local, LM Studio, Ollama
- Claude Code, Goose, Gemini CLI

### Terminal & Shell
- Windows Terminal, PowerShell 7
- Oh My Posh + CascadiaCode Nerd Font
- Terminal-Icons, z (directory jumping)

### System
- WSL + Ubuntu 24.04
- 1Password, PowerToys, gsudo
- Windows App (Remote Desktop), FilePilot

### Windows Settings
- Dev Drive (D:, 50GB, ReFS)
- Show file extensions
- Hide widgets from taskbar
- `D:\github` folder created

## Notes

- The DSC config runs in Windows PowerShell 5.1, even when setting up PowerShell 7
- `boot.ps1` adds a cache-busting param to avoid GitHub CDN staleness
- Nightscout URL is fetched from a private gist and set as `OSTENSIBLY_NIGHTSCOUT_URL` env var
- Oh My Posh config is dynamically generated with the Nightscout URL baked in
