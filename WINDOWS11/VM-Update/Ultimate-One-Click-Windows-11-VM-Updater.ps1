# ==========================================================
# Windows 11 Ultimate One-Click Auto Update & Repair
# ==========================================================
# Run as Administrator
# Logs progress to C:\Logs\Win11_FullAutoUpdate.log
# by nu11secur1ty
# ==========================================================

$LogFile = "C:\Logs\Win11_FullAutoUpdate.log"
if (!(Test-Path "C:\Logs")) { New-Item -Path "C:\Logs" -ItemType Directory | Out-Null }

function Write-Log {
    param([string]$message)
    $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$time - $message" | Tee-Object -FilePath $LogFile -Append
}

Write-Log "`n=== Starting Ultimate Windows 11 Auto Update ===`n"

# --- 1) Stop update services ---
Write-Log "Stopping update services..."
$services = "wuauserv","bits","cryptsvc","msiserver"
foreach ($s in $services) {
    Stop-Service $s -Force -ErrorAction SilentlyContinue
}

# --- 2) Reset caches ---
Write-Log "Resetting SoftwareDistribution and Catroot2..."
Try {
    Rename-Item -Path "C:\Windows\SoftwareDistribution" -NewName "SoftwareDistribution.old" -ErrorAction SilentlyContinue
    Rename-Item -Path "C:\Windows\System32\catroot2" -NewName "catroot2.old" -ErrorAction SilentlyContinue
} Catch {
    Write-Log "Warning: Error renaming update caches: $_"
}

# --- 3) Reset Update Orchestrator tasks ---
Write-Log "Resetting Update Orchestrator tasks..."
$uoPath = "C:\Windows\System32\Tasks\Microsoft\Windows\UpdateOrchestrator"
Try {
    Remove-Item "$uoPath\*" -Recurse -Force -ErrorAction SilentlyContinue
} Catch {
    Write-Log "Warning: Could not remove Orchestrator tasks: $_"
}

# --- 4) Repair system files ---
Write-Log "Running SFC..."
sfc /scannow | Out-String | ForEach-Object {Write-Log $_}
Write-Log "Running DISM RestoreHealth..."
DISM /Online /Cleanup-Image /RestoreHealth | Out-String | ForEach-Object {Write-Log $_}

# --- 5) Re-register Windows Update DLLs ---
Write-Log "Re-registering Windows Update DLLs..."
$wuDlls = @(
    "atl.dll","urlmon.dll","mshtml.dll","shdocvw.dll","browseui.dll","jscript.dll","vbscript.dll",
    "scrrun.dll","msxml.dll","msxml3.dll","msxml6.dll","wuapi.dll","wuaueng.dll","wuaueng1.dll",
    "wucltui.dll","wups.dll","wups2.dll","wuweb.dll","qmgr.dll","qmgrprxy.dll","wucltux.dll",
    "muweb.dll","wuwebv.dll"
)
foreach ($dll in $wuDlls) {
    Start-Process regsvr32.exe "/s $dll" -WindowStyle Hidden
}

# --- 6) Restart update services ---
Write-Log "Restarting update services..."
foreach ($s in $services) { Start-Service $s }

# --- 7) Install PSWindowsUpdate module ---
Write-Log "Installing PSWindowsUpdate module..."
Install-PackageProvider -Name NuGet -Force -Confirm:$false -ErrorAction SilentlyContinue
Install-Module -Name PSWindowsUpdate -Force -AllowClobber -Confirm:$false -ErrorAction SilentlyContinue
Import-Module PSWindowsUpdate

# --- 8) Force scan and install all updates ---
Write-Log "Checking for all updates including feature updates..."
$updates = Get-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot -ErrorAction SilentlyContinue
if ($updates.Count -gt 0) {
    Write-Log "Installing $($updates.Count) updates..."
    Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -AutoReboot -Verbose | ForEach-Object {Write-Log $_}
} else {
    Write-Log "No updates found."
}

# --- 9) Clean component store ---
Write-Log "Cleaning component store..."
DISM.exe /Online /Cleanup-Image /StartComponentCleanup /Quiet

Write-Log "`n=== Ultimate Update Complete! Please restart your VM if it hasn't already ===`n"
Write-Host "=== Ultimate Update Complete! Logs saved at $LogFile ===" -ForegroundColor Green
