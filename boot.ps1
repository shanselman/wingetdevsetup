$mainFunction = {
    $mypath = $MyInvocation.MyCommand.Path
    Write-Output "Path of the script: $mypath"

    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if (!$isAdmin) {
        # Shoulder tap terminal so it gets registered moving forward
        Start-Process shell:AppsFolder\Microsoft.WindowsTerminal_8wekyb3d8bbwe!App

        # Restart as Admin
        Write-Host "Restarting as Administrator..."
        Start-Process PowerShell -Wait -Verb RunAs "-NoProfile -ExecutionPolicy Bypass -Command `"cd '$pwd'; & '$mypath';`""
        exit
    }
    else {
        # Ensure WinGet is ready before running DSC configuration
        GetLatestWinGet

        $dscUri = "https://raw.githubusercontent.com/shanselman/wingetdevsetup/master/"
        $dscDev = "hanselman.dev.dsc.yml"
        $cacheBust = "?v=$(Get-Date -Format 'yyyyMMddHHmmss')"
        $dscDevUri = $dscUri + $dscDev + $cacheBust

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
    Write-Host "Ensuring WinGet is ready..."
    
    # Turn off progress bar for better performance
    $ProgressPreference = 'SilentlyContinue'

    # Install NuGet provider and WinGet Client module
    try {
        Write-Host "Installing NuGet package provider..."
        Install-PackageProvider -Name NuGet -Force -ErrorAction Stop -WarningAction SilentlyContinue
        Write-Host "NuGet package provider installed successfully"
        
        Write-Host "Installing Microsoft.WinGet.Client module..."
        Install-Module -Name Microsoft.WinGet.Client -Force -Repository PSGallery -ErrorAction Stop -WarningAction SilentlyContinue
        Write-Host "Microsoft.WinGet.Client module installed successfully"
        
        Write-Host "Repairing WinGet Package Manager..."
        Repair-WinGetPackageManager -Force -Latest -ErrorAction Stop
        
        Write-Host "WinGet is ready"
    }
    catch {
        Write-Warning "Failed to repair WinGet using module approach"
        Write-Warning "Error: $($_.Exception.Message)"
        Write-Host "Attempting manual installation..."
        
        # Fallback to manual installation
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
                Write-Warning "BITS transfer failed for $filePath, falling back to Invoke-WebRequest"
                Invoke-WebRequest -Uri $fileUri -OutFile $filePath -ErrorAction Stop
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
}

& $mainFunction
