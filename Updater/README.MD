<#
.SYNOPSIS
  Strong, idempotent Windows 11 updater script with logging, restore point attempt, WUA/PSWindowsUpdate support and evidence packaging.

.NOTES
  - Run as Administrator.
  - Recommended: take VM snapshot before running.
  - Use -DryRun to only enumerate updates without installing.

.PARAMETER DryRun
  If present, the script will only enumerate available updates and produce logs; no downloads/installs.

.PARAMETER AutoReboot
  If present, allow the script to reboot the system automatically when a reboot is required (will prompt unless -Force).

.PARAMETER Force
  Skip interactive prompts.

.PARAMETER LogDir
  Where to save logs and evidence (default: C:\WindowsUpdateEvidence\<timestamp>)

.PARAMETER UsePSWindowsUpdate
  If present, attempt to use the PSWindowsUpdate module (from PSGallery) to apply updates instead of WUA.

.EXAMPLE
  .\Strong-Win11Updater.ps1 -DryRun -LogDir C:\temp\winup
#>

[CmdletBinding()]
param(
    [switch]$DryRun,
    [switch]$AutoReboot,
    [switch]$Force,
    [string]$LogDir = "$(Join-Path -Path $env:ProgramData -ChildPath 'Win11Updater')\$(Get-Date -Format 'yyyyMMdd_HHmmss')",
    [switch]$UsePSWindowsUpdate
)

function Write-Log {
    param($Message, [switch]$Error)
    $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $entry = "$ts`t$($Message)"
    Add-Content -Path $global:LogFile -Value $entry
    if ($Error) { Write-Error $Message } else { Write-Host $Message }
}

# Ensure running elevated
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "This script must be run as Administrator. Exiting."
    exit 2
}

# Prepare logging folder
New-Item -Path $LogDir -ItemType Directory -Force | Out-Null
$global:LogFile = Join-Path $LogDir "update-log.txt"
Start-Transcript -Path (Join-Path $LogDir "transcript.txt") -Force | Out-Null
Write-Log "=== Strong-Win11Updater started ==="

# Reminder to snapshot
if (-not $Force) {
    Write-Host ""
    Write-Host "REMINDER: Take a VM snapshot (or checkpoint) before proceeding. Continue? (Y/N)"
    $resp = Read-Host
    if ($resp -notin @('Y','y','Yes','yes')) {
        Write-Log "User aborted before snapshot confirmation." -Error
        Stop-Transcript
        exit 3
    }
}

# Collect baseline system facts
try {
    Write-Log "Collecting baseline system facts..."
    Get-CimInstance -ClassName Win32_OperatingSystem | Select-Object Caption, Version, BuildNumber, OSArchitecture, InstallDate | Out-File (Join-Path $LogDir "system_os.txt")
    systeminfo | Out-File (Join-Path $LogDir "systeminfo.txt")
    Get-HotFix | Sort-Object InstalledOn -Descending | Out-File (Join-Path $LogDir "Get-HotFix.txt")
    Get-WmiObject -Class Win32_QuickFixEngineering | Select HotFixID, InstalledOn, Description | Sort-Object InstalledOn -Descending | Out-File (Join-Path $LogDir "QuickFixEngineering.txt")
    Write-Log "Baseline facts collected."
} catch {
    Write-Log "Unable to collect all baseline facts: $_" -Error
}

# Attempt to create a System Restore point (best-effort)
try {
    Write-Log "Attempting to create a System Restore point (if System Restore enabled)..."
    if (Get-Command -Name Checkpoint-Computer -ErrorAction SilentlyContinue) {
        try {
            Checkpoint-Computer -Description "PreUpdate_RestorePoint_$(Get-Date -Format 'yyyyMMdd_HHmmss')" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
            Write-Log "System Restore point created successfully (or scheduled)."
        } catch {
            Write-Log "Checkpoint-Computer failed or System Restore not available: $_"
        }
    } else {
        Write-Log "Checkpoint-Computer command not available in this environment."
    }
} catch {
    Write-Log "Restore point attempt encountered an error: $_"
}

# Helper: check pending reboot (common checks)
function Test-PendingReboot {
    # Checks multiple locations for signs a reboot is pending
    $Pending = $false
    try {
        $regPaths = @(
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending",
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired",
            "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\PendingFileRenameOperations"
        )
        foreach ($p in $regPaths) {
            if (Test-Path $p) {
                Write-Log "Pending reboot registry key found: $p"
                $Pending = $true
            }
        }

        # Also check WMI for pending operations
        $wmipending = Get-CimInstance -ClassName Win32_ComputerSystem | Select -ExpandProperty DomainRole -ErrorAction SilentlyContinue
        # (domain role not directly giving pending reboot; leave WMI checks for later)
    } catch {
        Write-Log "Test-PendingReboot encountered an error: $_"
    }
    return $Pending
}

# Use native Windows Update Agent (WUA) by default
function Use-WUA-Install {
    param([switch]$OnlyList)
    Write-Log "Using native Windows Update Agent (WUA) to search for updates..."
    try {
        $session = New-Object -ComObject Microsoft.Update.Session
        $searcher = $session.CreateUpdateSearcher()
        Write-Log "Searching for available updates (this may take a while)..."
        # Query: not installed, software updates (includes security updates)
        $query = "IsInstalled=0 and IsHidden=0 and Type='Software'"
        $sr = $searcher.Search($query)
        Write-Log "Search returned $($sr.Updates.Count) updates."
        # build a simple results file
        $updates = for ($i=0; $i -lt $sr.Updates.Count; $i++) {
            $u = $sr.Updates.Item($i)
            [PSCustomObject]@{
                Index = $i
                Title = $u.Title
                KBs = ($u.KBArticleIDs -join ',')
                IsMandatory = $u.MsrcSeverity
                IsDownloaded = $u.IsDownloaded
                Identity = $u.Identity.UpdateID.Guid
            }
        }
        $updates | Out-File (Join-Path $LogDir "WUA_AvailableUpdates.txt")
        if ($OnlyList) {
            Write-Log "DryRun: enumerated updates saved to WUA_AvailableUpdates.txt"
            return $updates
        }

        if ($sr.Updates.Count -eq 0) {
            Write-Log "No applicable updates found."
            return @()
        }

        # Filter out driver-only or optional feature updates? Keep default set; you may refine here.
        $collection = New-Object -ComObject Microsoft.Update.UpdateColl
        for ($i=0; $i -lt $sr.Updates.Count; $i++) {
            $collection.Add($sr.Updates.Item($i)) | Out-Null
        }

        # Download
        $downloader = $session.CreateUpdateDownloader()
        $downloader.Updates = $collection
        Write-Log "Starting download of $($collection.Count) updates..."
        $downResult = $downloader.Download()
        Write-Log "Download result: ResultCode=$($downResult.ResultCode); RebootRequired=$($downResult.RebootRequired)"
        # Install
        $installer = $session.CreateUpdateInstaller()
        $installer.Updates = $collection
        Write-Log "Starting install..."
        $installResult = $installer.Install()
        Write-Log "Install result: ResultCode=$($installResult.ResultCode); RebootRequired=$($installResult.RebootRequired)"
        # Save details
        $installResult | Out-File (Join-Path $LogDir "WUA_InstallResult.txt")
        return $installResult
    } catch {
        Write-Log "WUA update process failed: $_" -Error
        return $null
    }
}

# Optional: use PSWindowsUpdate module (may be preferable for remote management)
function Use-PSWindowsUpdate {
    param([switch]$OnlyList)
    Write-Log "Using PSWindowsUpdate module (if missing, attempt to install from PSGallery)..."
    try {
        if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
            Write-Log "PSWindowsUpdate not found. Installing from PSGallery..."
            Install-PackageProvider -Name NuGet -Force -Scope CurrentUser -ErrorAction SilentlyContinue | Out-Null
            Set-PSRepository -Name "PSGallery" -ErrorAction SilentlyContinue | Out-Null
            Install-Module -Name PSWindowsUpdate -Force -Scope CurrentUser -AllowClobber -ErrorAction Stop
        }
        Import-Module PSWindowsUpdate -Force
        # List updates
        $available = Get-WUList -MicrosoftUpdate -ErrorAction Stop
        $available | Out-File (Join-Path $LogDir "PSWindowsUpdate_Available.txt")
        if ($OnlyList) {
            Write-Log "DryRun: enumerated updates saved to PSWindowsUpdate_Available.txt"
            return $available
        }
        # Install updates (accept EULA if needed)
        $result = Get-WUInstall -AcceptAll -IgnoreReboot -MicrosoftUpdate -Verbose -ErrorAction Stop
        $result | Out-File (Join-Path $LogDir "PSWindowsUpdate_InstallResult.txt")
        return $result
    } catch {
        Write-Log "PSWindowsUpdate method failed: $_" -Error
        return $null
    }
}

# Main flow: enumerate and optionally install
if ($UsePSWindowsUpdate) {
    $list = Use-PSWindowsUpdate -OnlyList:$DryRun
} else {
    $list = Use-WUA-Install -OnlyList:$DryRun
}

# If dry-run, stop here after packaging logs
if ($DryRun) {
    Write-Log "Dry run requested; skipping download/install. Packaging evidence..."
    # Package logs
    $zipPath = Join-Path $LogDir "UpdateEvidence-DryRun-$((Get-Date).ToString('yyyyMMdd_HHmmss')).zip"
    try {
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::CreateFromDirectory($LogDir, $zipPath)
        Write-Log "Evidence zip created: $zipPath"
        # hash
        $h = Get-FileHash -Path $zipPath -Algorithm SHA256
        $h | Out-File (Join-Path $LogDir "EvidenceZipHash.txt")
        Write-Log "SHA256 of evidence: $($h.Hash)"
    } catch {
        Write-Log "Failed to create evidence zip: $_" -Error
    }
    Stop-Transcript
    Write-Log "Dry run completed. Exiting."
    exit 0
}

# After installation, collect post-run facts
try {
    Write-Log "Collecting post-installation facts..."
    Get-HotFix | Sort-Object InstalledOn -Descending | Out-File (Join-Path $LogDir "Get-HotFix_Post.txt")
    Get-WmiObject -Class Win32_QuickFixEngineering | Select HotFixID, InstalledOn, Description | Sort-Object InstalledOn -Descending | Out-File (Join-Path $LogDir "QuickFixEngineering_Post.txt")
    systeminfo | Out-File (Join-Path $LogDir "systeminfo_post.txt")
} catch {
    Write-Log "Failed to collect post-install info: $_"
}

# Check pending reboot
$pending = Test-PendingReboot
if ($pending) {
    Write-Log "System indicates a reboot may be required."
} else {
    Write-Log "No obvious pending reboot indicators were found."
}

# Offer to reboot if needed
if ($pending -and $AutoReboot) {
    if ($Force -or (Read-Host "A reboot appears required. Reboot now? (Y/N)") -in @('Y','y','Yes','yes')) {
        Write-Log "Rebooting system now as requested..."
        # create final evidence zip before reboot
        try {
            $zipPath = Join-Path $LogDir "UpdateEvidence_PreReboot-$((Get-Date).ToString('yyyyMMdd_HHmmss')).zip"
            Add-Type -AssemblyName System.IO.Compression.FileSystem
            [System.IO.Compression.ZipFile]::CreateFromDirectory($LogDir, $zipPath)
            Write-Log "Pre-reboot evidence zip created: $zipPath"
            $h = Get-FileHash -Path $zipPath -Algorithm SHA256
            $h | Out-File (Join-Path $LogDir "EvidenceZipHash_PreReboot.txt")
            Write-Log "SHA256: $($h.Hash)"
        } catch {
            Write-Log "Failed to build pre-reboot zip: $_"
        }

        Stop-Transcript
        Restart-Computer -Force
        # script will stop here due to reboot
    } else {
        Write-Log "User chose not to reboot at this time."
    }
} else {
    Write-Log "No reboot requested/required or AutoReboot not set."
}

# Final packaging of logs and evidence
try {
    $zipPath = Join-Path $LogDir "UpdateEvidence-Completed-$((Get-Date).ToString('yyyyMMdd_HHmmss')).zip"
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::CreateFromDirectory($LogDir, $zipPath)
    Write-Log "Final evidence zip created: $zipPath"
    $h = Get-FileHash -Path $zipPath -Algorithm SHA256
    $h | Out-File (Join-Path $LogDir "EvidenceZipHash.txt")
    Write-Log "SHA256: $($h.Hash)"
} catch {
    Write-Log "Failed to create final evidence zip: $_"
}

Write-Log "=== Strong-Win11Updater completed ==="
Stop-Transcript
exit 0
