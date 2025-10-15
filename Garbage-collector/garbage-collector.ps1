# Safe Aggressive Windows Cleaner Script (PowerShell)
# WARNING: Deletes unnecessary files but preserves browser logins
# by nu11secur1ty
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
Write-Host "Cleaning browser caches (safe)..."

# Helper function for Chrome-like browsers
function Clear-ChromeLikeCache($basePath) {
    if (Test-Path $basePath) {
        Get-ChildItem -Path $basePath -Directory | ForEach-Object {
            $profile = $_.FullName
            $cacheFolders = @("Cache", "GPUCache", "Code Cache", "Service Worker\CacheStorage", "Service Worker\ScriptCache")
            foreach ($folder in $cacheFolders) {
                $full = Join-Path $profile $folder
                if (Test-Path $full) {
                    Clear-Folder $full
                }
            }
        }
    }
}

# --- Chrome ---
Clear-ChromeLikeCache "$env:LOCALAPPDATA\Google\Chrome\User Data"

# --- Edge ---
Clear-ChromeLikeCache "$env:LOCALAPPDATA\Microsoft\Edge\User Data"

# --- Brave ---
Clear-ChromeLikeCache "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data"

# --- Vivaldi ---
Clear-ChromeLikeCache "$env:LOCALAPPDATA\Vivaldi\User Data"

# --- Opera ---
if (Test-Path "$env:LOCALAPPDATA\Opera Software\Opera Stable\Cache") {
    Clear-Folder "$env:LOCALAPPDATA\Opera Software\Opera Stable\Cache"
}
if (Test-Path "$env:APPDATA\Opera Software\Opera Stable\Cache") {
    Clear-Folder "$env:APPDATA\Opera Software\Opera Stable\Cache"
}
if (Test-Path "$env:LOCALAPPDATA\Opera Software\Opera GX Stable\Cache") {
    Clear-Folder "$env:LOCALAPPDATA\Opera Software\Opera GX Stable\Cache"
}

# --- Chromium generic ---
Clear-ChromeLikeCache "$env:LOCALAPPDATA\Chromium\User Data"

# --- Mozilla Firefox ---
$ffProfiles = "$env:APPDATA\Mozilla\Firefox\Profiles"
if (Test-Path $ffProfiles) {
    Get-ChildItem -Path $ffProfiles -Directory | ForEach-Object {
        $profile = $_.FullName
        foreach ($folder in @("cache2","startupCache")) {
            $full = Join-Path $profile $folder
            if (Test-Path $full) {
                Clear-Folder $full
            }
        }
    }
}

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
