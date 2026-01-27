$mainFunction = {
    $mypath = $MyInvocation.MyCommand.Path
    Write-Output "Path of the script: $mypath"

    GetLatestWinGet

    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    $dscUri = "https://raw.githubusercontent.com/shanselman/wingetdevsetup/master/"
    $dscDev = "hanselman.dev.dsc.yml"
    $cacheBust = "?v=$(Get-Date -Format 'yyyyMMddHHmmss')"
    $dscDevUri = $dscUri + $dscDev + $cacheBust

    if (!$isAdmin) {
        # Shoulder tap terminal so it gets registered moving forward
        Start-Process shell:AppsFolder\Microsoft.WindowsTerminal_8wekyb3d8bbwe!App

        # Restart as Admin
        Write-Host "Restarting as Administrator..."
        Start-Process PowerShell -Wait -Verb RunAs "-NoProfile -ExecutionPolicy Bypass -Command `"cd '$pwd'; & '$mypath';`""
        exit
    }
    else {
        Write-Host "Start: Scott Hanselman Dev Machine Setup"
        winget configuration -f $dscDevUri
        Write-Host "Done: Scott Hanselman Dev Machine Setup"
        
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "  NEXT STEPS:" -ForegroundColor Cyan
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "1. Run: gh auth login" -ForegroundColor Yellow
        Write-Host "2. Then run: .\clone-repos.ps1" -ForegroundColor Yellow
        Write-Host "========================================" -ForegroundColor Cyan
    }
}

function GetLatestWinGet {
    # Forcing WinGet to be up to date
    $isWinGetRecent = (winget -v).Trim('v').TrimEnd("-preview").split('.')

    # Turn off progress bar for better performance
    $ProgressPreference = 'SilentlyContinue'

    if (!(([int]$isWinGetRecent[0] -gt 1) -or ([int]$isWinGetRecent[0] -ge 1 -and [int]$isWinGetRecent[1] -ge 6))) {
        # WinGet needs to be v1.6 or higher
        $paths = "Microsoft.VCLibs.x64.14.00.Desktop.appx", "Microsoft.UI.Xaml.2.8.x64.appx", "Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
        $uris = "https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx", "https://github.com/microsoft/microsoft-ui-xaml/releases/download/v2.8.6/Microsoft.UI.Xaml.2.8.x64.appx", "https://aka.ms/getwinget"
        
        Write-Host "Downloading WinGet and its dependencies..."

        for ($i = 0; $i -lt $uris.Length; $i++) {
            $filePath = $paths[$i]
            $fileUri = $uris[$i]
            Write-Host "Downloading: $filePath from $fileUri"
            try {
                Start-BitsTransfer -Source $fileUri -Destination $filePath -ErrorAction Stop
            }
            catch {
                Write-Warning "BITS transfer failed, falling back to Invoke-WebRequest: $_"
                Invoke-WebRequest -Uri $fileUri -OutFile $filePath
            }
        }

        Write-Host "Installing WinGet and its dependencies..."

        foreach ($filePath in $paths) {
            Write-Host "Installing: $filePath"
            Add-AppxPackage $filePath
        }

        Write-Host "Verifying Version number of WinGet"
        winget -v

        Write-Host "Cleaning up"
        foreach ($filePath in $paths) {
            if (Test-Path $filePath) {
                Write-Host "Deleting: $filePath"
                Remove-Item $filePath -Verbose
            }
            else {
                Write-Error "Path doesn't exist: $filePath"
            }
        }
    }
    else {
        Write-Host "WinGet is up to date, proceeding with DSC configuration"
    }
}

& $mainFunction
