# WinGet Dev Setup

Scott Hanselman's personal Windows development machine setup using WinGet DSC (Desired State Configuration).

## Quick Start

Run this command in PowerShell to bootstrap your dev machine:

```powershell
irm https://raw.githubusercontent.com/shanselman/wingetdevsetup/master/boot.ps1 | iex
```

After installation completes:

```powershell
gh auth login
.\clone-repos.ps1
```

## What Gets Installed

### Development Tools
- **Git** - Version control
- **GitHub CLI** - GitHub command line interface
- **GitHub Copilot CLI** - AI-powered command suggestions
- **Visual Studio Code** - Code editor
- **Visual Studio Code Insiders** - Latest VS Code features
- **Visual Studio 2026 Community** - Full IDE with configured workloads
- **.NET SDK 10** - Latest .NET development platform
- **Node.js LTS** - Installed via NVM for Windows
- **NVM for Windows** - Node version manager
- **Python 3.12** - Python runtime and development tools
- **Docker Desktop** - Container platform

### Terminal & Shell
- **Windows Terminal** - Modern terminal application
- **PowerShell 7** - Latest stable version of PowerShell (cross-platform)
- **Oh My Posh** - Terminal prompt theme engine
- **GNU Midnight Commander** - Terminal file manager
- **Terminal-Icons** PowerShell module
- **z** PowerShell module - Directory jumping

### AI & ML Tools
- **Foundry Local** - Local AI development
- **LM Studio** - Local language model runner
- **Ollama** - Run large language models locally
- **Claude Code** - Anthropic's coding assistant
- **Goose** - AI-powered task automation
- **Gemini CLI** - Google's AI command line tool (via npm)

### System Tools
- **WSL** - Windows Subsystem for Linux
- **Ubuntu 24.04** - Linux distribution for WSL
- **1Password** - Password manager
- **PowerToys** - Windows utilities
- **gsudo** - Sudo for Windows
- **Windows App (Remote Desktop)** - Remote desktop client
- **FilePilot** - File management utility

### Communication & Productivity
- **Slack** - Team communication
- **Okta Verify** - Multi-factor authentication

### Media & Entertainment
- **VLC media player** - Media player
- **Netflix** - Streaming service

### Custom Installations
- **Handy** - Installed from GitHub releases
- **Okta Verify** - Installed from direct download

### Windows Configuration
- **Dev Drive** - Creates a 50GB ReFS Dev Drive on D:
- **File Extensions** - Shows file extensions in Explorer
- **Taskbar** - Hides widgets from taskbar
- **D:\github folder** - Created for repositories

## PowerShell 7

Yes, this setup **does install PowerShell 7 (the latest stable version)** using the `Microsoft.PowerShell` package from WinGet. This package always installs the most recent stable release of PowerShell 7.

The installation also configures:
- PowerShell profile with custom functions and aliases
- Oh My Posh theme for enhanced terminal prompts
- Required PowerShell modules (Terminal-Icons, z)
- CascadiaCode Nerd Font for proper icon display
- Windows Terminal configuration

## Files in This Repository

- `hanselman.dev.dsc.yml` - Main DSC configuration file
- `boot.ps1` - Bootstrap script that runs the DSC configuration
- `clone-repos.ps1` - Clones Scott's repositories and configures environment
- `Microsoft.PowerShell_profile.ps1` - PowerShell 7 profile
- `hanselman.omp.json` - Oh My Posh theme template
- `.vsconfig` - Visual Studio workloads and components configuration
- `SESSION-NOTES.md` - Detailed technical notes and troubleshooting

## Technical Details

This setup uses:
- **WinGet DSC** (Desired State Configuration) for declarative machine setup
- **WinGet** for package installation from official repositories
- **PowerShell 7** for scripting and automation
- **Dev Drive** (ReFS filesystem) for improved developer experience

The bootstrap script (`boot.ps1`) automatically:
1. Checks for administrator privileges (elevates if needed)
2. Ensures WinGet is installed and up-to-date
3. Downloads and applies the DSC configuration
4. Configures all applications and settings

## Requirements

- Windows 10/11
- Internet connection
- Administrator privileges (the script will request elevation)

## License

This is Scott Hanselman's personal configuration. Feel free to fork and customize for your own use.
