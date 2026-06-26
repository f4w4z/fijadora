@echo off
setlocal enabledelayedexpansion

echo ===================================================
echo               Phoebe Homes Setup Tool
echo ===================================================
echo.

:: 1. Check if Developer Mode is already enabled in registry
reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" /v "AllowDevelopmentWithoutDevLicense" 2>nul | findstr /i "0x1" >nul
if %errorlevel% equ 0 (
    echo [INFO] Developer Mode is already enabled on this system.
    goto check_flutter
)

echo [INFO] Developer Mode is NOT enabled. Symlink creation (required for building plugins) requires Developer Mode or Admin rights.
echo.
echo [!] Attempting to enable Developer Mode automatically...

:: 2. Check for Admin Privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [INFO] Requesting Administrator privileges to modify Developer Mode registry keys...
    powershell -Command "Start-Process cmd -ArgumentList '/c reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock /t REG_DWORD /f /v AllowDevelopmentWithoutDevLicense /d 1' -Verb RunAs -Wait"
    
    :: Re-check after elevation attempt
    reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" /v "AllowDevelopmentWithoutDevLicense" 2>nul | findstr /i "0x1" >nul
    if %errorlevel% neq 0 (
        echo.
        echo [WARNING] Developer Mode could not be enabled.
        echo [WARNING] If the UAC prompt was cancelled or failed, please enable Developer Mode manually.
        echo [WARNING] You can open settings by running: start ms-settings:developers
        echo.
        set /p "user_choice=Would you like to try running setup anyway? (y/n): "
        if /i "!user_choice!" neq "y" goto end
    ) else (
        echo [SUCCESS] Developer Mode enabled successfully!
    )
) else (
    :: Already admin, just add it directly
    reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" /t REG_DWORD /f /v "AllowDevelopmentWithoutDevLicense" /d "1"
    if %errorlevel% equ 0 (
        echo [SUCCESS] Developer Mode enabled successfully!
    ) else (
        echo [ERROR] Failed to enable Developer Mode. Please run this script as Administrator.
        goto end
    )
)

:check_flutter
echo.
echo ===================================================
echo          Verifying Flutter Installation
echo ===================================================
where flutter >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] 'flutter' command not found.
    echo [ERROR] Please make sure Flutter is installed and added to your system PATH.
    echo.
    goto end
)

echo [SUCCESS] Flutter detected.
echo.

echo ===================================================
echo          Configuring Flutter Project
echo ===================================================
echo [INFO] Running 'flutter create .' to configure/recreate platform files...
call flutter create .
if %errorlevel% neq 0 (
    echo.
    echo [ERROR] 'flutter create .' failed.
    goto end
)

echo.
echo [INFO] Fetching Flutter pub dependencies...
call flutter pub get
if %errorlevel% neq 0 (
    echo.
    echo [ERROR] 'flutter pub get' failed.
    goto end
)

echo.
echo ===================================================
echo [SUCCESS] Setup completed successfully!
echo ===================================================
echo.
echo You can now run the project with:
echo    flutter run
echo.
echo To run environment checks:
echo    flutter doctor
echo.

:end
pause
