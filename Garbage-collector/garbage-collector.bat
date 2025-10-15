@ECHO OFF
:: Safe Aggressive Windows Cleaner Script
:: WARNING: Deletes unnecessary files but preserves browser logins
:: by nu11secur1ty

:: === USER TEMP FILES ===
ECHO Cleaning user temp folder...
IF EXIST "%USERPROFILE%\AppData\Local\Temp" (
    del /s /f /q "%USERPROFILE%\AppData\Local\Temp\*.*" >nul 2>&1
)

:: === WINDOWS TEMP FILES ===
ECHO Cleaning Windows temp folder...
IF EXIST "C:\Windows\Temp" (
    del /s /f /q "C:\Windows\Temp\*.*" >nul 2>&1
)

:: === WINDOWS UPDATE CACHE ===
ECHO Cleaning Windows Update downloads...
IF EXIST "C:\Windows\SoftwareDistribution\Download" (
    del /s /f /q "C:\Windows\SoftwareDistribution\Download\*.*" >nul 2>&1
)

:: === PREFETCH FILES ===
ECHO Cleaning Prefetch folder...
IF EXIST "C:\Windows\Prefetch" (
    del /s /f /q "C:\Windows\Prefetch\*.*" >nul 2>&1
)

:: === USER DOCUMENTS & PICTURES ===
ECHO Cleaning Camtasia projects...
IF EXIST "%USERPROFILE%\Documents\Camtasia" (
    del /s /f /q "%USERPROFILE%\Documents\Camtasia\*.*" >nul 2>&1
)

ECHO Cleaning Screenshots...
IF EXIST "%USERPROFILE%\Pictures\Screenshots" (
    del /s /f /q "%USERPROFILE%\Pictures\Screenshots\*.*" >nul 2>&1
)

:: === RECYCLE BIN ===
ECHO Emptying Recycle Bin...
PowerShell -Command "Clear-RecycleBin -Force" >nul 2>&1

:: === THUMBNAILS CACHE ===
ECHO Cleaning Thumbnails cache...
IF EXIST "%LOCALAPPDATA%\Microsoft\Windows\Explorer" (
    del /s /f /q "%LOCALAPPDATA%\Microsoft\Windows\Explorer\thumbcache_*.db" >nul 2>&1
)

:: === LOG FILES ===
ECHO Cleaning Windows log files...
IF EXIST "C:\Windows\Logs" (
    del /s /f /q "C:\Windows\Logs\*.*" >nul 2>&1
)

:: === BROWSER CACHE (SAFE) ===
ECHO Cleaning browser caches (safe)...

:: --- Google Chrome ---
IF EXIST "%LOCALAPPDATA%\Google\Chrome\User Data" (
    FOR /D %%G IN ("%LOCALAPPDATA%\Google\Chrome\User Data\*") DO (
        IF EXIST "%%G\Cache" (
            del /s /f /q "%%G\Cache\*.*" >nul 2>&1
        )
        IF EXIST "%%G\GPUCache" (
            del /s /f /q "%%G\GPUCache\*.*" >nul 2>&1
        )
        IF EXIST "%%G\Code Cache" (
            del /s /f /q "%%G\Code Cache\*.*" >nul 2>&1
        )
    )
)

:: --- Microsoft Edge ---
IF EXIST "%LOCALAPPDATA%\Microsoft\Edge\User Data" (
    FOR /D %%G IN ("%LOCALAPPDATA%\Microsoft\Edge\User Data\*") DO (
        IF EXIST "%%G\Cache" (
            del /s /f /q "%%G\Cache\*.*" >nul 2>&1
        )
        IF EXIST "%%G\GPUCache" (
            del /s /f /q "%%G\GPUCache\*.*" >nul 2>&1
        )
        IF EXIST "%%G\Code Cache" (
            del /s /f /q "%%G\Code Cache\*.*" >nul 2>&1
        )
    )
)

:: --- Mozilla Firefox ---
IF EXIST "%APPDATA%\Mozilla\Firefox\Profiles" (
    FOR /D %%G IN ("%APPDATA%\Mozilla\Firefox\Profiles\*") DO (
        IF EXIST "%%G\cache2" (
            del /s /f /q "%%G\cache2\*.*" >nul 2>&1
        )
        IF EXIST "%%G\startupCache" (
            del /s /f /q "%%G\startupCache\*.*" >nul 2>&1
        )
    )
)

:: --- Brave Browser ---
IF EXIST "%LOCALAPPDATA%\BraveSoftware\Brave-Browser\User Data" (
    FOR /D %%G IN ("%LOCALAPPDATA%\BraveSoftware\Brave-Browser\User Data\*") DO (
        IF EXIST "%%G\Cache" (
            del /s /f /q "%%G\Cache\*.*" >nul 2>&1
        )
        IF EXIST "%%G\GPUCache" (
            del /s /f /q "%%G\GPUCache\*.*" >nul 2>&1
        )
        IF EXIST "%%G\Code Cache" (
            del /s /f /q "%%G\Code Cache\*.*" >nul 2>&1
        )
    )
)

:: --- Vivaldi ---
IF EXIST "%LOCALAPPDATA%\Vivaldi\User Data" (
    FOR /D %%G IN ("%LOCALAPPDATA%\Vivaldi\User Data\*") DO (
        IF EXIST "%%G\Cache" (
            del /s /f /q "%%G\Cache\*.*" >nul 2>&1
        )
        IF EXIST "%%G\GPUCache" (
            del /s /f /q "%%G\GPUCache\*.*" >nul 2>&1
        )
        IF EXIST "%%G\Code Cache" (
            del /s /f /q "%%G\Code Cache\*.*" >nul 2>&1
        )
    )
)

:: --- Opera ---
IF EXIST "%LOCALAPPDATA%\Opera Software\Opera Stable\Cache" (
    del /s /f /q "%LOCALAPPDATA%\Opera Software\Opera Stable\Cache\*.*" >nul 2>&1
)
IF EXIST "%APPDATA%\Opera Software\Opera Stable\Cache" (
    del /s /f /q "%APPDATA%\Opera Software\Opera Stable\Cache\*.*" >nul 2>&1
)
IF EXIST "%LOCALAPPDATA%\Opera Software\Opera GX Stable\Cache" (
    del /s /f /q "%LOCALAPPDATA%\Opera Software\Opera GX Stable\Cache\*.*" >nul 2>&1
)

:: --- Chromium Generic ---
IF EXIST "%LOCALAPPDATA%\Chromium\User Data" (
    FOR /D %%G IN ("%LOCALAPPDATA%\Chromium\User Data\*") DO (
        IF EXIST "%%G\Cache" (
            del /s /f /q "%%G\Cache\*.*" >nul 2>&1
        )
        IF EXIST "%%G\GPUCache" (
            del /s /f /q "%%G\GPUCache\*.*" >nul 2>&1
        )
        IF EXIST "%%G\Code Cache" (
            del /s /f /q "%%G\Code Cache\*.*" >nul 2>&1
        )
    )
)

:: === WINDOWS.OLD REMOVAL ===
IF EXIST "C:\Windows.old" (
    ECHO Taking ownership of Windows.old...
    takeown /F "C:\Windows.old" /R /D Y
    icacls "C:\Windows.old" /grant administrators:F /T
    ECHO Deleting Windows.old...
    rmdir /S /Q "C:\Windows.old"
)

ECHO.
ECHO All unnecessary files cleaned! Browser logins preserved.
PAUSE
