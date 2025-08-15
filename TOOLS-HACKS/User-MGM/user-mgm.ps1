# Remove a Local User and Delete Their Profile - Colorized + Exit on * or Enter
# Compatible with Windows 7/8/10/11
# Must be run as Administrator
# by nu11secur1ty 2025

function Get-LocalUsers {
    try {
        if (Get-Command Get-LocalUser -ErrorAction SilentlyContinue) {
            return Get-LocalUser | Select-Object -ExpandProperty Name
        }
        else {
            return (net user | Select-String -Pattern "^\s+\S+" |
                ForEach-Object { $_.ToString().Trim().Split(" ",[System.StringSplitOptions]::RemoveEmptyEntries) }) -join "`n" |
                ForEach-Object { $_ }
        }
    }
    catch {
        Write-Host "ERROR: Failed to retrieve local users: $_" -ForegroundColor Red
    }
}

Write-Host "=== Local User Removal & Cleanup Tool ===" -ForegroundColor Cyan

# Get users
$users = Get-LocalUsers

if (-not $users -or $users.Count -eq 0) {
    Write-Host "No local users found." -ForegroundColor Yellow
    exit
}

Write-Host "`nLocal Users:" -ForegroundColor Magenta
for ($i = 0; $i -lt $users.Count; $i++) {
    Write-Host ("{0}. {1}" -f ($i+1), $users[$i]) -ForegroundColor White
}

Write-Host "`nType '*' or press Enter with no input to exit without deleting." -ForegroundColor Yellow

# Ask which user to remove
$selection = Read-Host -Prompt "Enter the number of the user to remove"

# Exit if '*' or empty
if ([string]::IsNullOrWhiteSpace($selection) -or $selection -eq '*') {
    Write-Host "No changes made. Exiting..." -ForegroundColor Cyan
    exit
}

# Validate number selection
if ($selection -notmatch '^\d+$' -or $selection -lt 1 -or $selection -gt $users.Count) {
    Write-Host "Invalid selection." -ForegroundColor Red
    exit
}

$targetUser = $users[$selection - 1]

# Confirm
Write-Host ""
$confirm = Read-Host -Prompt "Are you sure you want to REMOVE '$targetUser' and DELETE ALL their files? (Y/N)"
if ($confirm -ne 'Y' -and $confirm -ne 'y') {
    Write-Host "Operation cancelled." -ForegroundColor Yellow
    exit
}

try {
    # Remove account
    if (Get-Command Remove-LocalUser -ErrorAction SilentlyContinue) {
        Remove-LocalUser -Name $targetUser -ErrorAction Stop
    }
    else {
        cmd /c "net user `"$targetUser`" /delete"
    }
    Write-Host "User '$targetUser' removed from system." -ForegroundColor Green

    # Remove profile folder
    $profilePath = "C:\Users\$targetUser"
    if (Test-Path $profilePath) {
        Remove-Item -Path $profilePath -Recurse -Force -ErrorAction Stop
        Write-Host "Profile folder '$profilePath' deleted." -ForegroundColor Green
    }
    else {
        Write-Host "No profile folder found for '$targetUser'." -ForegroundColor Yellow
    }

    # Remove registry profile entry
    $userSID = (Get-WmiObject Win32_UserProfile | Where-Object { $_.LocalPath -eq $profilePath }).SID
    if ($userSID) {
        Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\$userSID" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "Registry profile for '$targetUser' removed." -ForegroundColor Green
    }

    Write-Host "Cleanup complete for '$targetUser'." -ForegroundColor Cyan
}
catch {
    Write-Host "ERROR: Failed to fully remove '$targetUser': $_" -ForegroundColor Red
}
