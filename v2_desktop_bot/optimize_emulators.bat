@echo off
setlocal enabledelayedexpansion
title MEmu Optimizer V2

:: Generate real ESC character for ANSI colors
for /f %%a in ('echo prompt $E ^| cmd') do set "E=%%a"

echo   %E%[36m==================================================%E%[0m
echo   %E%[92m[+] MEmu Emulator Space & Performance Optimizer%E%[0m
echo   %E%[36m==================================================%E%[0m
echo.

:: Find ADB
set "ADB_PATH=adb"
where adb >nul 2>nul
if !errorlevel! neq 0 (
    set "ADB_PATH=D:\Program Files\Microvirt\MEmu\adb.exe"
    if not exist "!ADB_PATH!" set "ADB_PATH=C:\Program Files\Microvirt\MEmu\adb.exe"
)

if not exist "!ADB_PATH!" if "!ADB_PATH!" neq "adb" (
    echo  %E%[31m[-] ADB not found. Make sure MEmu is installed.%E%[0m
    pause
    exit /b 1
)

echo  %E%[33m[*] Detecting connected emulators...%E%[0m
:: Ensure server is running
"!ADB_PATH!" start-server >nul 2>nul

for /f "tokens=1" %%i in ('"!ADB_PATH!" devices ^| findstr /r /c:"\bdevice$"') do (
    set "deviceId=%%i"
    echo.
    echo  %E%[92m[+] Optimizing Device: !deviceId!%E%[0m
    
    echo      - Shrinking Resolution (540x960 @ 160 DPI)...
    "!ADB_PATH!" -s !deviceId! shell wm size 540x960
    "!ADB_PATH!" -s !deviceId! shell wm density 160
    
    echo      - Disabling UI Animations...
    "!ADB_PATH!" -s !deviceId! shell settings put global window_animation_scale 0.0
    "!ADB_PATH!" -s !deviceId! shell settings put global transition_animation_scale 0.0
    "!ADB_PATH!" -s !deviceId! shell settings put global animator_duration_scale 0.0
    
    echo      - Disabling Bloatware (Play Store, Maps, YouTube...)...
    "!ADB_PATH!" -s !deviceId! shell pm disable-user --user 0 com.android.vending >nul 2>nul
    "!ADB_PATH!" -s !deviceId! shell pm disable-user --user 0 com.google.android.gms >nul 2>nul
    "!ADB_PATH!" -s !deviceId! shell pm disable-user --user 0 com.google.android.youtube >nul 2>nul
    "!ADB_PATH!" -s !deviceId! shell pm disable-user --user 0 com.google.android.apps.maps >nul 2>nul
    "!ADB_PATH!" -s !deviceId! shell pm disable-user --user 0 com.google.android.gm >nul 2>nul
    "!ADB_PATH!" -s !deviceId! shell pm disable-user --user 0 com.android.chrome >nul 2>nul
    
    echo      - Trimming Caches...
    "!ADB_PATH!" -s !deviceId! shell pm trim-caches 999999999999 >nul 2>nul

    echo      - Disabling Auto-Updates...
    "!ADB_PATH!" -s !deviceId! shell settings put global auto_update_app 0
)

echo.
echo   %E%[36m==================================================%E%[0m
echo   %E%[92m[+] Done! You should restart your 10 MEmu instances.%E%[0m
echo   %E%[33m[!] Make sure in MEmu settings each is: 1 CPU, 1024MB RAM%E%[0m
echo   %E%[36m==================================================%E%[0m
pause
