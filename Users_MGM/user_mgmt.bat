@echo off
chcp 1251 > nul
title User Management (Admin)
color 0F

:: Check for Administrator privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Please run as ADMINISTRATOR!
    echo Restarting with admin rights...
    timeout /t 2 > nul
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit
)

:menu
cls
echo ===================================================
echo             LOCAL USER MANAGEMENT
echo ===================================================
echo.
echo    [1] Create standard user
echo    [2] Create ADMINISTRATOR
echo    [3] Delete user
echo    [4] Change user password
echo    [5] List all users
echo    [6] Exit
echo.
set /p choice="Select (1-6): "

if "%choice%"=="1" goto create_user
if "%choice%"=="2" goto create_admin
if "%choice%"=="3" goto delete_user
if "%choice%"=="4" goto change_password
if "%choice%"=="5" goto list_users
if "%choice%"=="6" exit

echo Invalid choice!
timeout /t 2 > nul
goto menu

:create_user
cls
echo --- CREATE STANDARD USER ---
set /p username="Username: "
set /p password="Password: "
net user "%username%" "%password%" /add
if %errorlevel%==0 (
    echo User %username% created successfully (standard)
) else (
    echo Error creating user!
)
timeout /t 3 > nul
goto menu

:create_admin
cls
echo --- CREATE ADMINISTRATOR ---
set /p username="Username: "
set /p password="Password: "
net user "%username%" "%password%" /add
net localgroup administrators "%username%" /add
if %errorlevel%==0 (
    echo ADMINISTRATOR %username% created successfully
) else (
    echo Error creating administrator!
)
timeout /t 3 > nul
goto menu

:delete_user
cls
echo ===================================================
echo             DELETE USER
echo ===================================================
echo.
echo CURRENT USERS:
echo -----------------------------------------
net user
echo -----------------------------------------
echo.
set /p username="Enter username to delete: "

net user "%username%" >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: User "%username%" does NOT exist!
    timeout /t 3 > nul
    goto menu
)

echo.
echo WARNING! You are about to delete user: %username%
set /p confirm="Are you sure? (yes/no): "
if /i not "%confirm%"=="yes" (
    echo Cancelled.
    timeout /t 2 > nul
    goto menu
)

net user "%username%" /delete
if %errorlevel%==0 (
    echo User "%username%" DELETED successfully.
) else (
    echo Delete error!
)
timeout /t 3 > nul
goto menu

:change_password
cls
echo ===================================================
echo             CHANGE USER PASSWORD
echo ===================================================
echo.
echo CURRENT USERS:
echo -----------------------------------------
net user
echo -----------------------------------------
echo.
set /p username="Enter username to change password: "

net user "%username%" >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: User "%username%" does NOT exist!
    timeout /t 3 > nul
    goto menu
)

echo.
set /p password="Enter new password: "
net user "%username%" "%password%"
if %errorlevel%==0 (
    echo Password for user "%username%" changed successfully.
) else (
    echo Error changing password!
)
timeout /t 3 > nul
goto menu

:list_users
cls
echo ===================================================
echo             ALL LOCAL USERS
echo ===================================================
echo.
net user
echo.
echo Press any key to continue...
pause > nul
goto menu
