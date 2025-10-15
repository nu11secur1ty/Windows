# Safe Aggressive Windows Cleaner Script (PowerShell)
# WARNING: Deletes unnecessary files but preserves browser logins

# Function to safely delete a folder's contents
function Clear-Folder($path) {
    if (Test-Path $path) {
        Write-Host "Cleaning $path..."
        try {
            Remove-Item "$path\*" -Recurse -Force -ErrorAction SilentlyContinue
        } catch {
            Write-Warning "Failed to delete some items in $path"
        }
    }
}

# === USER TEMP FILES ===
Clear-Folder "$env:LOCALAPPDATA\Temp"

# === WINDOWS TEMP FILES ===
Clear-Folder "C:\Windows\Temp"

# === WINDOWS UPDATE CACHE ===
Clear-Folder "C:\Windows\SoftwareDistribution\Download"

# === PREFETCH FILES ===
Clear-Folder "C:\Windows\Prefetch"

# === USER DOCUMENTS & PICTURES ===
Clear-Folder "$env:USERPROFILE\Documents\Camtasia"
Clear-Folder "$env:USERPROFILE\Pictures\Screenshots"

# === RECYCLE BIN ===
Write-Host "Emptying Recycle Bin..."
try {
    Clear-RecycleBin -Force -ErrorAction SilentlyContinue
} catch {
    Write-Warning "Failed to clear Recycle Bin"
}

# === THUMBNAILS CACHE ===
Clear-Folder "$env:LOCALAPPDATA\Microsoft\Windows\Explorer"

# === LOG FILES ===
Clear-Folder "C:\Windows\Logs"

# === BROWSER CACHE (SAFE) ===
Clear-Folder "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache"
Clear-Folder "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache"

# === WINDOWS.OLD REMOVAL ===
$windowsOld = "C:\Windows.old"
if (Test-Path $windowsOld) {
    Write-Host "Taking ownership and deleting Windows.old..."
    try {
        takeown /F $windowsOld /R /D Y | Out-Null
        icacls $windowsOld /grant administrators:F /T | Out-Null
        Remove-Item $windowsOld -Recurse -Force -ErrorAction SilentlyContinue
    } catch {
        Write-Warning "Failed to delete Windows.old"
    }
}

Write-Host
Write-Host "All unnecessary files cleaned! Browser logins preserved." -ForegroundColor Green
Pause
