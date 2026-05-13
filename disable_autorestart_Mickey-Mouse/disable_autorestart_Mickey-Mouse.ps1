# ==========================================================
# nu11secur1ty - Anti-MickyMouse Auto-Restart Script
# Target: Windows 11 / Windows 10
# Purpose: Stop automatic reboots during deep sessions
# ==========================================================

Write-Host "Starting the nu11secur1ty-tunnel protection..." -ForegroundColor Cyan

# 1. Disable Auto-Reboot with Logged-on Users (Registry)
$registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
if (!(Test-Path $registryPath)) {
    New-Item -Path $registryPath -Force | Out-Null
}
New-ItemProperty -Path $registryPath -Name "NoAutoRebootWithLoggedOnUsers" -Value 1 -PropertyType DWORD -Force
Write-Host "[+] Registry: Auto-Reboot blocked for logged users." -ForegroundColor Green

# 2. Disable the Reboot Tasks in Task Scheduler
$tasks = @(
    "\Microsoft\Windows\UpdateOrchestrator\Reboot",
    "\Microsoft\Windows\UpdateOrchestrator\Reboot_AC",
    "\Microsoft\Windows\UpdateOrchestrator\Reboot_Battery"
)

foreach ($taskPath in $tasks) {
    try {
        Disable-ScheduledTask -TaskPath (Split-Path $taskPath -Parent) -TaskName (Split-Path $taskPath -Leaf) -ErrorAction Stop
        Write-Host "[+] Task Scheduler: Disabled $taskPath" -ForegroundColor Green
    } catch {
        Write-Host "[-] Task Scheduler: Could not find or disable $taskPath (it might not exist in this build)" -ForegroundColor Yellow
    }
}

# 3. Disable the 'UpdateOrchestrator' service from triggering reboots
# Note: We don't stop the service (to keep updates), we just block the reboot command
$rebootFile = "$env:windir\System32\Tasks\Microsoft\Windows\UpdateOrchestrator\Reboot"
if (Test-Path $rebootFile) {
    takeown /f $rebootFile /a
    icacls $rebootFile /inheritance:r /grant:r "Administrators:F" /deny "SYSTEM:F"
    Write-Host "[+] File System: Denied SYSTEM access to Reboot task file." -ForegroundColor Green
}

# 4. Force apply the policies
gpupdate /force

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "THE THEOREM IS PROTECTED! No more Micky Mouse resets." -ForegroundColor White
Write-Host "==========================================================" -ForegroundColor Cyan
