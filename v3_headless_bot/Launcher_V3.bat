@echo off
setlocal enabledelayedexpansion
title ScraperKing V3 - Headless FB Lite
chcp 437 >nul 2>nul

:: Generate real ESC character for ANSI colors
for /f %%a in ('echo prompt $E ^| cmd') do set "E=%%a"

cd /d "%~dp0"

set "VERSION=1.0"
set "PREMIUM_STATUS=TRIAL"

:: == GENERATE HARDWARE ID =====================================
set "HWID_TMP=%TEMP%\sk_hwid_%RANDOM%.tmp"
powershell -NoProfile -Command "$g = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Cryptography' -Name MachineGuid -ErrorAction SilentlyContinue).MachineGuid; if (-not $g) { $g = (Get-CimInstance Win32_ComputerSystemProduct).UUID }; if ($g) { $clean = $g -replace '-',''; $id = 'SKING-' + $clean.Substring(0,8) + '-' + $clean.Substring(8,4) + '-' + $clean.Substring(12,4); $id.ToUpper() } else { '' }" >"!HWID_TMP!"
set /p HARDWARE_ID=<"!HWID_TMP!"
del /f /q "!HWID_TMP!" 2>nul

if "%HARDWARE_ID%"=="" (
    echo   %E%[31m[-] Could not detect Hardware ID.%E%[0m
    pause & exit /b 1
)

:: == FETCH VERSION (Obfuscated) ===============================
set "VER_SCRIPT=%TEMP%\sk_ver_%RANDOM%.ps1"
>"!VER_SCRIPT!" echo.$ErrorActionPreference='SilentlyContinue'
>>"!VER_SCRIPT!" echo.[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
>>"!VER_SCRIPT!" echo.$u1 = [char[]]@(104,116,116,112,115,58,47,47,114,97,119,46,103,105,116,104,117,98,117,115,101,114,99,111,110,116,101,110,116,46,99,111,109,47) -join ''
>>"!VER_SCRIPT!" echo.$u2 = [char[]]@(97,107,97,115,104,57,57,97,107,47) -join ''
>>"!VER_SCRIPT!" echo.$u3 = [char[]]@(83,99,97,112,101,114,45,107,105,110,103,47,109,97,105,110,47,118,101,114,115,105,111,110,46,106,115,111,110) -join ''
>>"!VER_SCRIPT!" echo.try { $r = (New-Object System.Net.WebClient).DownloadString($u1+$u2+$u3); $v = ($r ^| ConvertFrom-Json).version; Write-Host $v } catch { Write-Host '1.0' }
for /f "delims=" %%V in ('powershell -NoProfile -ExecutionPolicy Bypass -File "!VER_SCRIPT!"') do set "VERSION=%%V"
del /f /q "!VER_SCRIPT!" >nul 2>nul

:: == VALIDATE LICENSE =========================================
cls
call :print_header
echo.
echo   %E%[36m--------------------------------------------------%E%[0m
echo   %E%[32m  YOUR HARDWARE ID:%E%[0m
echo   %E%[33m  %HARDWARE_ID%%E%[0m
echo   %E%[36m--------------------------------------------------%E%[0m
echo.
echo   %E%[33m[*] Validating license...%E%[0m
echo.

set "PS_SCRIPT=%TEMP%\sk_validate_%RANDOM%.ps1"
>"!PS_SCRIPT!" echo.$ErrorActionPreference='SilentlyContinue'
>>"!PS_SCRIPT!" echo.[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
>>"!PS_SCRIPT!" echo.$p1 = [char[]]@(104,116,116,112,115,58,47,47,103,105,115,116,46,103,105,116,104,117,98,117,115,101,114,99,111,110,116,101,110,116,46,99,111,109,47) -join ''
>>"!PS_SCRIPT!" echo.$p2 = [char[]]@(97,107,97,115,104,57,57,97,107,47) -join ''
>>"!PS_SCRIPT!" echo.$p3 = [char[]]@(56,102,50,56,55,54,57,97,100,98,57,54,53,50,52,50,52,102,49,99,98,55,48,51,99,101,97,49,55,99,53,56,47,114,97,119,47,107,101,121,115,46,106,115,111,110) -join ''
>>"!PS_SCRIPT!" echo.$url = $p1 + $p2 + $p3 + '?t=' + [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
>>"!PS_SCRIPT!" echo.try {
>>"!PS_SCRIPT!" echo.    $raw = curl.exe -4 --connect-timeout 3 -m 5 -s -f "$url" 2^>$null
>>"!PS_SCRIPT!" echo.    if (-not $raw) { $wc = New-Object System.Net.WebClient; $raw = $wc.DownloadString($url) }
>>"!PS_SCRIPT!" echo.    if (-not $raw) { throw 'Fetch failed' }
>>"!PS_SCRIPT!" echo.    $json = $raw ^| ConvertFrom-Json
>>"!PS_SCRIPT!" echo.    $hwid = '!HARDWARE_ID!'
>>"!PS_SCRIPT!" echo.    $entry = $json.keys.PSObject.Properties ^| Where-Object { $_.Name -eq $hwid }
>>"!PS_SCRIPT!" echo.    if ($entry) {
>>"!PS_SCRIPT!" echo.        $u = $entry.Value.user; $e = $entry.Value.expires; $today = Get-Date -Format 'yyyy-MM-dd'
>>"!PS_SCRIPT!" echo.        if ($e -ge $today) { Write-Host ('1' + [char]124 + $u + [char]124 + $e) } else { Write-Host ('2' + [char]124 + $u + [char]124 + $e) }
>>"!PS_SCRIPT!" echo.    } else { Write-Host ('0' + [char]124 + 'NotFound' + [char]124) }
>>"!PS_SCRIPT!" echo.} catch { Write-Host ('3' + [char]124 + 'Error' + [char]124) }

set "VALIDATION_CODE=0"
for /f "tokens=1,2,3 delims=|" %%A in ('powershell -NoProfile -ExecutionPolicy Bypass -File "!PS_SCRIPT!"') do (
    set "VALIDATION_CODE=%%A"
    set "KEY_USER=%%B"
    set "KEY_EXPIRES=%%C"
)
del /f /q "!PS_SCRIPT!" >nul 2>nul

if "!VALIDATION_CODE!"=="1" (
    echo   %E%[32m[+] License APPROVED! User: !KEY_USER! Expires: !KEY_EXPIRES!%E%[0m
    timeout /t 2 >nul
    goto :auth_v3_passed
)
if "!VALIDATION_CODE!"=="2" (
    echo   %E%[31m[-] License EXPIRED! Contact https://t.me/scraper_king%E%[0m
    pause & exit /b 1
)
if "!VALIDATION_CODE!"=="3" (
    echo   %E%[31m[-] Could not reach license server!%E%[0m
    pause & exit /b 1
)
echo   %E%[31m[!] License NOT APPROVED. HWID: %HARDWARE_ID%%E%[0m
echo   %E%[33m  Send to: https://t.me/scraper_king%E%[0m
pause & exit /b 1

:auth_v3_passed

:: Find Node.js
set "NODE_EXE=node"
where node >nul 2>nul
if !errorlevel! neq 0 (
    set "NODE_EXE=%~dp0bin\node\node.exe"
    if not exist "!NODE_EXE!" set "NODE_EXE=C:\Program Files\nodejs\node.exe"
    if not exist "!NODE_EXE!" set "NODE_EXE=C:\Program Files (x86)\nodejs\node.exe"
    if not exist "!NODE_EXE!" set "NODE_EXE=%LOCALAPPDATA%\Programs\nodejs\node.exe"
)

set "NPM_CMD="
for /f "delims=" %%P in ('where npm.cmd 2^>nul') do (
    echo %%P | findstr /i "ScraperKing" >nul || (
        set "NPM_CMD=%%P"
        goto :found_npm
    )
)
:found_npm
if "!NPM_CMD!"=="" (
    set "NPM_CMD=%~dp0bin\node\npm.cmd"
    if not exist "!NPM_CMD!" set "NPM_CMD=C:\Program Files\nodejs\npm.cmd"
    if not exist "!NPM_CMD!" set "NPM_CMD=C:\Program Files (x86)\nodejs\npm.cmd"
    if not exist "!NPM_CMD!" set "NPM_CMD=%LOCALAPPDATA%\Programs\nodejs\npm.cmd"
)

:: Auto-Download Portable Node.js if completely missing!
if "!NODE_EXE!" neq "node" if not exist "!NODE_EXE!" (
    cls
    call :print_header
    echo   %E%[33m  FIRST-TIME SETUP: Core Engine runtime%E%[0m
    echo   %E%[36m--------------------------------------------------%E%[0m
    echo.
    echo   %E%[37m  Node.js is not installed on this PC.%E%[0m
    echo   %E%[37m  Downloading standalone Portable Node.js runtime...%E%[0m
    echo.
    mkdir "%~dp0bin" 2>nul
    powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://nodejs.org/dist/v20.11.1/node-v20.11.1-win-x64.zip' -OutFile '%~dp0bin\node.zip'"
    if exist "%~dp0bin\node.zip" (
        echo   %E%[33m  Extracting payload...%E%[0m
        powershell -Command "Expand-Archive -Path '%~dp0bin\node.zip' -DestinationPath '%~dp0bin' -Force"
        rename "%~dp0bin\node-v20.11.1-win-x64" "node"
        del /q "%~dp0bin\node.zip"
        set "NODE_EXE=%~dp0bin\node\node.exe"
        set "NPM_CMD=%~dp0bin\node\npm.cmd"
        set "PATH=%~dp0bin\node;!PATH!"
        echo.
        echo  %E%[32m[+] Portable Runtime Initialized successfully!%E%[0m
        timeout /t 2 >nul
    ) else (
        echo.
        echo  %E%[31m[!] Failed to download Node.js automatically.%E%[0m
        pause
        exit /b 1
    )
)

:: Install deps if missing
if not exist "%~dp0node_modules\chalk" (
    cls
    call :print_header
    echo  %E%[33m[*] Installing Headless Engine dependencies...%E%[0m
    echo.
    call "!NPM_CMD!" install unzipper cli-progress node-fetch@2 chalk@4
    if !errorlevel! neq 0 (
        echo  %E%[31m[~] Install failed.%E%[0m
        pause
        exit /b 1
    )
    echo  %E%[32m[+] Dependencies installed.%E%[0m
    timeout /t 2 >nul
)

:: == Check if Engine is installed =============================
if not exist "%~dp0engine\sdk\emulator\emulator.exe" (
    cls
    call :print_header
    echo   %E%[33m  FIRST-TIME SETUP%E%[0m
    echo   %E%[36m--------------------------------------------------%E%[0m
    echo.
    echo   %E%[33m  The engine requires a One-time setup.%E%[0m
    echo   %E%[37m  Permission is needed to download core components.%E%[0m
    echo.
    set "SETUP_CONFIRM="
    set /p "SETUP_CONFIRM=  %E%[32m>%E%[37m Press ENTER to begin setup or N to cancel: %E%[0m"
    if /i "!SETUP_CONFIRM!"=="N" exit /b 0
    
    echo.
    "!NODE_EXE!" "%~dp0setup_engine.js"
    if !errorlevel! neq 0 (
        echo.
        echo  %E%[31m[~] Setup failed. Check errors above.%E%[0m
        pause
        exit /b 1
    )
    echo.
    echo  %E%[32m[+] Engine setup complete!%E%[0m
    timeout /t 2 >nul
)

:: == Auto-migrate: android-22 image upgrade ===================
if not exist "%~dp0engine\sdk\system-images\android-22\default\x86\" (
    cls
    call :print_header
    echo   %E%[33m  UPGRADING: Downloading lighter Android 5.1 image...%E%[0m
    echo   %E%[36m--------------------------------------------------%E%[0m
    echo.
    echo   %E%[37m  The engine is switching to Android 5.1 for%E%[0m
    echo   %E%[37m  drastically lower RAM usage ^(~350MB per instance^).%E%[0m
    echo   %E%[37m  This is a one-time automatic upgrade.%E%[0m
    echo.
    "!NODE_EXE!" "%~dp0setup_engine.js"
    if !errorlevel! neq 0 (
        echo.
        echo  %E%[31m[~] Image download failed. Check your internet.%E%[0m
        pause
        exit /b 1
    )
    echo.
    echo  %E%[32m[+] Android 5.1 image ready!%E%[0m
    timeout /t 2 >nul
    :: Force AVD re-creation with the new image
    if exist "%USERPROFILE%\.android\avd\Scraper_King_Base.avd" (
        echo  %E%[33m[*] Re-creating AVD with new image...%E%[0m
        rmdir /s /q "%USERPROFILE%\.android\avd\Scraper_King_Base.avd" 2>nul
        del /f /q "%USERPROFILE%\.android\avd\Scraper_King_Base.ini" 2>nul
    )
)

:: == Check if Golden AVD exists ===============================
if not exist "%USERPROFILE%\.android\avd\Scraper_King_Base.avd\config.ini" (
    cls
    call :print_header
    echo   %E%[33m  Creating Golden Base AVD...%E%[0m
    echo   %E%[36m--------------------------------------------------%E%[0m
    echo.
    "!NODE_EXE!" "%~dp0avd_manager.js"
    if !errorlevel! neq 0 (
        echo.
        echo  %E%[31m[~] AVD creation failed. Check errors above.%E%[0m
        pause
        exit /b 1
    )
    timeout /t 2 >nul
)

:: Sync App Library (always check for new apps, apk_manager caches existing ones)
cls
call :print_header
echo   %E%[33m  Syncing App Library...%E%[0m
echo   %E%[36m--------------------------------------------------%E%[0m
echo.
echo   %E%[37m  Checking for new apps in the cloud...%E%[0m
echo.
"!NODE_EXE!" "%~dp0apk_manager.js"
if !errorlevel! neq 0 (
    :: If sync fails, check if we have local cache
    set "APK_COUNT=0"
    if exist "%~dp0apks\*.apk" (
        for %%F in ("%~dp0apks\*.apk") do set /a APK_COUNT+=1
    )
    if !APK_COUNT! EQU 0 (
        echo.
        echo  %E%[31m[~] App download failed and no local cache. Check your internet.%E%[0m
        pause
        exit /b 1
    )
    echo  %E%[33m[~] Cloud sync failed but local apps found. Continuing offline.%E%[0m
)
timeout /t 1 >nul

:: STEP 0: App Selection
:ask_app
cls
call :print_header
echo   %E%[33m  Step 0: Select App%E%[0m
echo   %E%[36m--------------------------------------------------%E%[0m
echo.
set "APK_INDEX=0"
for %%F in ("%~dp0apks\*.apk") do (
    set /a APK_INDEX+=1
    set "APK_!APK_INDEX!=%%~nxF"
    echo   %E%[32m  [!APK_INDEX!]%E%[37m %%~nF%E%[0m
)
echo.
set "APP_CHOICE="
set /p "APP_CHOICE=  %E%[32m>%E%[37m Select app [1-!APK_INDEX!] (Default 1): %E%[0m"
if "!APP_CHOICE!"=="" set "APP_CHOICE=1"
set "SELECTED_APK=!APK_%APP_CHOICE%!"
if "!SELECTED_APK!"=="" (
    echo  %E%[31m[~] Invalid selection.%E%[0m
    timeout /t 1 >nul
    goto ask_app
)
echo.
echo   %E%[32m[+]%E%[37m Selected: %E%[33m!SELECTED_APK!%E%[0m
timeout /t 1 >nul

:: == STEP 1: Numbers file =====================================
:ask_numbers
cls
call :print_header
echo   %E%[33m  Step 1: Target List%E%[0m
echo   %E%[36m--------------------------------------------------%E%[0m
echo.
set "NUMBERS_FILE="
set /p "NUMBERS_FILE=  %E%[32m>%E%[37m Numbers file path (or drag/drop): %E%[0m"
set "NUMBERS_FILE=!NUMBERS_FILE:"=!"

if "!NUMBERS_FILE!"=="" (
    echo  %E%[31m[~] Required.%E%[0m
    timeout /t 1 >nul
    goto ask_numbers
)
if not exist "!NUMBERS_FILE!" (
    echo  %E%[31m[~] File not found.%E%[0m
    timeout /t 1 >nul
    goto ask_numbers
)

:: == STEP 2: Proxy Configuration ==============================
:ask_proxy
cls
call :print_header
echo   %E%[33m  Step 2: Proxy Configuration%E%[0m
echo   %E%[36m--------------------------------------------------%E%[0m
echo.
echo   %E%[32m[1]%E%[37m Direct Connection (No Proxy)%E%[0m
echo.
echo   %E%[90m  -- Proxy Input -------------------------------%E%[0m
echo   %E%[32m[2]%E%[37m Single Proxy String%E%[0m
echo   %E%[32m[3]%E%[37m Multiple Proxy File (Rotation)%E%[0m
echo.
set "PROXY_CHOICE="
set /p "PROXY_CHOICE=  %E%[32m>%E%[37m Choice [1-3] (Default 1): %E%[0m"
if "!PROXY_CHOICE!"=="" set "PROXY_CHOICE=1"

set "PROXY_INPUT="
set "PROXY_PROTOCOL=http"
set "IS_GB_PROXY=no"
set "PROXY_COUNTRY=random"
set "PROXY_QUOTA_MB=0"
set "PROXY_PATTERN=5"
set "PROXY_METHOD=1"

if "!PROXY_CHOICE!"=="1" goto proxy_done

:: == Proxy Input ==============================================
cls
call :print_header
echo   %E%[33m  Proxy Input%E%[0m
echo   %E%[36m--------------------------------------------------%E%[0m
echo.
if "!PROXY_CHOICE!"=="2" (
    echo   %E%[37m  Supported formats: IP:PORT, IP:PORT:USER:PASS, etc.%E%[0m
    echo.
    set /p "PROXY_INPUT=  %E%[32m>%E%[37m Proxy string: %E%[0m"
) else (
    echo   %E%[37m  File should contain one proxy per line.%E%[0m
    echo.
    set /p "PROXY_INPUT=  %E%[32m>%E%[37m Proxy file path (or drag/drop): %E%[0m"
)

set "PROXY_INPUT=!PROXY_INPUT:"=!"
if "!PROXY_INPUT!"=="" goto ask_proxy

:: == Proxy Method =============================================
cls
call :print_header
echo   %E%[33m  Proxy Method%E%[0m
echo   %E%[36m--------------------------------------------------%E%[0m
echo.
echo   %E%[32m[1]%E%[37m Strict Rotation (1 IP = 1 Number)%E%[0m
echo   %E%[32m[2]%E%[37m Infinite Loop   (Reuse IPs, 5-min Refresh)%E%[0m
echo.
set "METHOD_CHOICE="
set /p "METHOD_CHOICE=  %E%[32m>%E%[37m Choice [1-2] (Default 1): %E%[0m"
if "!METHOD_CHOICE!"=="" set "METHOD_CHOICE=1"
set "PROXY_METHOD=!METHOD_CHOICE!"

:: == Dynamic Rotation (Smart Mode) ============================
cls
call :print_header
echo   %E%[33m  Dynamic Rotation (Smart Mode)%E%[0m
echo   %E%[36m--------------------------------------------------%E%[0m
echo.
echo   %E%[37m  Enable Smart Mode for GB/Residential Proxies?%E%[0m
echo   %E%[90m  (Auto-detects BrightData, IPRoyal, Webshare, etc.)%E%[0m
echo.
echo   %E%[32m[1]%E%[37m Yes, enable Smart Rotation (GB/Sticky)%E%[0m
echo   %E%[32m[2]%E%[37m No, use Proxies as-is (Static)%E%[0m
echo.
set "SMART_CHOICE="
set /p "SMART_CHOICE=  %E%[32m>%E%[37m Choice [1-2] (Default 1): %E%[0m"
if "!SMART_CHOICE!"=="" set "SMART_CHOICE=1"

if "!SMART_CHOICE!"=="2" goto proxy_done

set "IS_GB_PROXY=yes"

:: == Country Selection (Only for Smart Mode) ==================
:ask_country
cls
call :print_header
echo   %E%[33m  Target Country (Smart Mode)%E%[0m
echo   %E%[36m--------------------------------------------------%E%[0m
echo.
echo   %E%[32m[1]%E%[37m US  [2]%E%[37m UK  [3]%E%[37m CA  [4]%E%[37m DE%E%[0m
echo   %E%[32m[5]%E%[37m FR  [6]%E%[37m IN  [7]%E%[37m BD  [8]%E%[37m RANDOM%E%[0m
echo   %E%[32m[9]%E%[33m AUTO %E%[90m(Detect via Number Prefix)%E%[0m
echo.
set "COUNTRY_CHOICE="
set /p "COUNTRY_CHOICE=  %E%[32m>%E%[37m Country [1-9] (Default 9): %E%[0m"
if "!COUNTRY_CHOICE!"=="" set "COUNTRY_CHOICE=9"

if "!COUNTRY_CHOICE!"=="1" set "PROXY_COUNTRY=us"
if "!COUNTRY_CHOICE!"=="2" set "PROXY_COUNTRY=gb"
if "!COUNTRY_CHOICE!"=="3" set "PROXY_COUNTRY=ca"
if "!COUNTRY_CHOICE!"=="4" set "PROXY_COUNTRY=de"
if "!COUNTRY_CHOICE!"=="5" set "PROXY_COUNTRY=fr"
if "!COUNTRY_CHOICE!"=="6" set "PROXY_COUNTRY=in"
if "!COUNTRY_CHOICE!"=="7" set "PROXY_COUNTRY=bd"
if "!COUNTRY_CHOICE!"=="8" set "PROXY_COUNTRY=random"
if "!COUNTRY_CHOICE!"=="9" set "PROXY_COUNTRY=auto"

goto proxy_done

:proxy_done

:: == STEP 2.5: Network Source =================================
:ask_network
cls
call :print_header
echo   %E%[33m  Step 2.5: Network Source (Mobile Data)%E%[0m
echo   %E%[36m--------------------------------------------------%E%[0m
echo.
echo   %E%[37m  Available Network Adapters:%E%[0m
set "NET_ADAPTER_COUNT=0"
for /f "tokens=1,2,3 delims=|" %%A in ('""!NODE_EXE!" "%~dp0network_bridge.js" list" 2^>nul') do (
    set "NET_INDEX=%%A"
    set "NET_NAME=%%B"
    set "NET_IP=%%C"
    echo   %E%[32m[!NET_INDEX!]%E%[37m !NET_NAME! %E%[90m(!NET_IP!)%E%[0m
    set "NET_ADAPTER_!NET_INDEX!=!NET_NAME!"
    set "NET_ADAPTER_COUNT=!NET_INDEX!"
)
if "!NET_ADAPTER_COUNT!"=="0" (
    echo   %E%[31m[!] No IPv4 network adapters found or script missing.%E%[0m
)
echo.
echo   %E%[32m[0]%E%[37m Skip (Use Default PC Network %E%[90m- Ethernet/Wi-Fi%E%[37m)%E%[0m
echo.
set "NETWORK_MODE="
set /p "NETWORK_MODE=  %E%[32m>%E%[37m Select adapter for EMULATORS [0-!NET_ADAPTER_COUNT!] (Default 0): %E%[0m"
if "!NETWORK_MODE!"=="" set "NETWORK_MODE=0"

set "NETWORK_NAME="
if "!NETWORK_MODE!" neq "0" (
    for /f "delims=" %%V in ("!NETWORK_MODE!") do set "NETWORK_NAME=!NET_ADAPTER_%%V!"
    if "!NETWORK_NAME!"=="" (
        echo  %E%[31m[~] Invalid selection.%E%[0m
        timeout /t 1 >nul
        goto ask_network
    )
    echo.
    echo   %E%[32m[+]%E%[37m Bound Emulators to: %E%[33m!NETWORK_NAME!%E%[0m
    timeout /t 1 >nul
) else (
    set "NETWORK_NAME="
)

goto ask_workers


:: == STEP 3: Workers ==========================================
:ask_workers
cls
call :print_header
echo   %E%[33m  Step 3: Concurrent Emulators%E%[0m
echo   %E%[36m--------------------------------------------------%E%[0m
echo.
echo   %E%[37m  Each emulator uses ~500MB RAM (Hardware Accelerated).%E%[0m
echo   %E%[37m  Recommended: 5 for 8GB RAM, 10 for 16GB RAM%E%[0m
echo.
set "WORKERS="
set /p "WORKERS=  %E%[32m>%E%[37m Emulator count (Default 3): %E%[0m"
if "!WORKERS!"=="" set "WORKERS=3"

:: == STEP 4: Language =========================================
:ask_language
cls
call :print_header
echo   %E%[33m  Step 4: FB Language%E%[0m
echo   %E%[36m--------------------------------------------------%E%[0m
echo.
echo   %E%[32m[1]%E%[37m Single Language Profile%E%[0m
echo   %E%[32m[2]%E%[37m Multi-Language Rotation%E%[0m
echo.
set "LANG_MODE="
set /p "LANG_MODE=  %E%[32m>%E%[37m Choice [1-2] (Default 1): %E%[0m"
if "!LANG_MODE!"=="" set "LANG_MODE=1"

if "!LANG_MODE!"=="2" goto multi_language

:single_language
cls
call :print_header
echo   %E%[33m  Step 4: Select Language%E%[0m
echo   %E%[36m--------------------------------------------------%E%[0m
echo.
echo   %E%[37m  1: EN   2: ES   3: FR   4: DE   5: PT   6: IT%E%[0m
echo   %E%[37m  7: AR   8: HI   9: BN  10: ID  11: RU  12: TR%E%[0m
echo   %E%[37m 13: VI  14: TH  15: KO  16: JA  17: ZH%E%[0m
echo.
set "FB_LANG="
set /p "FB_LANG=  %E%[32m>%E%[37m Language (1-17) [Default 1-EN]: %E%[0m"
if "!FB_LANG!"=="" set "FB_LANG=1"

if "!FB_LANG!"=="1" set "LANG_CODE=en"
if "!FB_LANG!"=="2" set "LANG_CODE=es"
if "!FB_LANG!"=="3" set "LANG_CODE=fr"
if "!FB_LANG!"=="4" set "LANG_CODE=de"
if "!FB_LANG!"=="5" set "LANG_CODE=pt"
if "!FB_LANG!"=="6" set "LANG_CODE=it"
if "!FB_LANG!"=="7" set "LANG_CODE=ar"
if "!FB_LANG!"=="8" set "LANG_CODE=hi"
if "!FB_LANG!"=="9" set "LANG_CODE=bn"
if "!FB_LANG!"=="10" set "LANG_CODE=id"
if "!FB_LANG!"=="11" set "LANG_CODE=ru"
if "!FB_LANG!"=="12" set "LANG_CODE=tr"
if "!FB_LANG!"=="13" set "LANG_CODE=vi"
if "!FB_LANG!"=="14" set "LANG_CODE=th"
if "!FB_LANG!"=="15" set "LANG_CODE=ko"
if "!FB_LANG!"=="16" set "LANG_CODE=ja"
if "!FB_LANG!"=="17" set "LANG_CODE=zh"
goto language_done

:multi_language
cls
call :print_header
echo   %E%[33m  Step 4: Multi-Language Selection%E%[0m
echo   %E%[36m--------------------------------------------------%E%[0m
echo.
echo   %E%[37m  Languages: 1:EN 2:ES 3:FR 4:DE 5:PT 6:IT 7:AR 8:HI 9:BN 10:ID 11:RU%E%[0m
echo   %E%[37m             12:TR 13:VI 14:TH 15:KO 16:JA 17:ZH%E%[0m
echo   %E%[37m  Example inputs: "1-3" or "1,2,5" or "1-17"%E%[0m
echo.
set "MULTI_LANG="
set /p "MULTI_LANG=  %E%[32m>%E%[37m Selection (Default 1-3): %E%[0m"
if "!MULTI_LANG!"=="" set "MULTI_LANG=1-3"

set "LANG_CODES="
:: Replace commas with spaces for the for loop
set "_tempLang_=!MULTI_LANG:,= !"

for %%a in (!_tempLang_!) do (
    set "token=%%a"
    set "isRange="
    for /f "tokens=1,2 delims=-" %%s in ("!token!") do (
        if "%%t" neq "" (
            set /a start=%%s, end=%%t
            for /l %%i in (!start!,1,!end!) do call :AddLanguage %%i
            set "isRange=1"
        )
    )
    if not defined isRange call :AddLanguage %%a
)

:: Remove trailing comma
if "!LANG_CODES!" neq "" set "LANG_CODES=!LANG_CODES:~0,-1!"
set "LANG_CODE=!LANG_CODES!"
if "!LANG_CODE!"=="" set "LANG_CODE=en"
goto language_done

:AddLanguage
set "idx=%~1"
if "!idx!"=="1" set "LANG_CODES=!LANG_CODES!en,"
if "!idx!"=="2" set "LANG_CODES=!LANG_CODES!es,"
if "!idx!"=="3" set "LANG_CODES=!LANG_CODES!fr,"
if "!idx!"=="4" set "LANG_CODES=!LANG_CODES!de,"
if "!idx!"=="5" set "LANG_CODES=!LANG_CODES!pt,"
if "!idx!"=="6" set "LANG_CODES=!LANG_CODES!it,"
if "!idx!"=="7" set "LANG_CODES=!LANG_CODES!ar,"
if "!idx!"=="8" set "LANG_CODES=!LANG_CODES!hi,"
if "!idx!"=="9" set "LANG_CODES=!LANG_CODES!bn,"
if "!idx!"=="10" set "LANG_CODES=!LANG_CODES!id,"
if "!idx!"=="11" set "LANG_CODES=!LANG_CODES!ru,"
if "!idx!"=="12" set "LANG_CODES=!LANG_CODES!tr,"
if "!idx!"=="13" set "LANG_CODES=!LANG_CODES!vi,"
if "!idx!"=="14" set "LANG_CODES=!LANG_CODES!th,"
if "!idx!"=="15" set "LANG_CODES=!LANG_CODES!ko,"
if "!idx!"=="16" set "LANG_CODES=!LANG_CODES!ja,"
if "!idx!"=="17" set "LANG_CODES=!LANG_CODES!zh,"
goto :eof

:language_done

:: == STEP 5: Resends ==========================================
:ask_resends
cls
call :print_header
echo   %E%[33m  Step 5: OTP Resends%E%[0m
echo   %E%[36m--------------------------------------------------%E%[0m
echo.
if "!LANG_CODE!"=="" set "LANG_CODE=en"
set "RESENDS="
set /p "RESENDS=  %E%[32m>%E%[37m Resends [0-5] (Default 0): %E%[0m"
if "!RESENDS!"=="" set "RESENDS=0"

:: == STEP 6: Display Mode ====================================
:ask_display
cls
call :print_header
echo   %E%[33m  Step 6: Display Mode%E%[0m
echo   %E%[36m--------------------------------------------------%E%[0m
echo.
echo   %E%[32m[1]%E%[37m Invisible (Headless, Fastest)%E%[0m
echo   %E%[32m[2]%E%[37m Visible (Watch emulators in small windows)%E%[0m
echo.
set "DISPLAY_MODE="
set /p "DISPLAY_MODE=  %E%[32m>%E%[37m Display Mode [1-2] (Default 1): %E%[0m"
if "!DISPLAY_MODE!"=="" set "DISPLAY_MODE=1"
set "VISIBLE_FLAG="
set "DISPLAY_TEXT=Headless (Invisible)"
if "!DISPLAY_MODE!"=="2" (
    set "VISIBLE_FLAG=--visible"
    set "DISPLAY_TEXT=Visible (Windowed)"
)

:: == CONFIRM ==================================================
cls
call :print_header
echo   %E%[33m  READY FOR LAUNCH%E%[0m
echo   %E%[36m--------------------------------------------------%E%[0m
echo.
echo   %E%[32m[+]%E%[37m Engine    : %E%[33mHeadless Android SDK (Burner Phones)%E%[0m
echo   %E%[32m[+]%E%[37m App       : %E%[33m!SELECTED_APK!%E%[0m
echo   %E%[32m[+]%E%[37m Targets   : %E%[33m!NUMBERS_FILE!%E%[0m
echo   %E%[32m[+]%E%[37m Emulators : %E%[33m!WORKERS! concurrent instances%E%[0m
echo   %E%[32m[+]%E%[37m Language  : %E%[33m!LANG_CODE!%E%[0m
echo   %E%[32m[+]%E%[37m Resends   : %E%[33m!RESENDS!%E%[0m
echo   %E%[32m[+]%E%[37m Display   : %E%[33m!DISPLAY_TEXT!%E%[0m
if "!PROXY_CHOICE!"=="1" (
echo   %E%[32m[+]%E%[37m Proxy     : %E%[33mDirect Connection%E%[0m
) else (
echo   %E%[32m[+]%E%[37m Proxy     : %E%[33m!PROXY_INPUT!%E%[0m
echo   %E%[32m[+]%E%[37m Protocol  : %E%[33m!PROXY_PROTOCOL!%E%[0m
if "!IS_GB_PROXY!"=="yes" (
echo   %E%[32m[+]%E%[37m Type      : %E%[33mGB Residential%E%[0m
echo   %E%[32m[+]%E%[37m Country   : %E%[33m!PROXY_COUNTRY!%E%[0m
echo   %E%[32m[+]%E%[37m Quota     : %E%[33m!PROXY_QUOTA_MB! MB%E%[0m
echo   %E%[32m[+]%E%[37m Pattern   : %E%[33m!PROXY_PATTERN!%E%[0m
) else (
echo   %E%[32m[+]%E%[37m Type      : %E%[33mStatic / Unlimited%E%[0m
)
)
if "!NETWORK_NAME!" neq "" (
echo   %E%[32m[+]%E%[37m Net Bound : %E%[33mMobile Data (!NETWORK_NAME!)%E%[0m
)
echo.
echo   %E%[36m==================================================%E%[0m
if "!DISPLAY_MODE!"=="2" (
echo   %E%[33m  VISIBLE MODE: Emulator windows will appear on screen.%E%[0m
) else (
echo   %E%[33m  HEADLESS MODE: Emulators run invisible in background.%E%[0m
)
echo   %E%[37m  Each instance is ephemeral (read-only snapshot).%E%[0m
echo   %E%[37m  All fingerprints are randomized per session.%E%[0m
echo   %E%[36m==================================================%E%[0m
echo.

set "FB_LANG_TOGGLE=auto"

set "DELAY_MULT="
set /p "DELAY_MULT=  %E%[32m>%E%[37m Custom Delay Multiplier (1.0 = Normal, 2.0 = Slower) [Default 1.0]: %E%[0m"
if "!DELAY_MULT!"=="" set "DELAY_MULT=1.0"
echo.

set "CONFIRM="
set /p "CONFIRM=  %E%[32m>%E%[37m Press ENTER to start or N to cancel: %E%[0m"
if /i "!CONFIRM!"=="N" goto ask_numbers

:: == RUN ======================================================
cls
echo.
echo   %E%[33m[*] Starting Headless Engine...%E%[0m
echo.
"!NODE_EXE!" "%~dp0index.js" !VISIBLE_FLAG! "!NUMBERS_FILE!" "!PROXY_INPUT!" "!WORKERS!" "!LANG_CODE!" "!RESENDS!" "!SELECTED_APK!" "!PROXY_PROTOCOL!" "!IS_GB_PROXY!" "!PROXY_COUNTRY!" "!PROXY_QUOTA_MB!" "!PROXY_PATTERN!" "!PROXY_METHOD!" "!FB_LANG_TOGGLE!" "!DELAY_MULT!" "!NETWORK_NAME!"

:: == DONE =====================================================
echo.
echo   %E%[36m==================================================%E%[0m
echo   %E%[92m  SCRAPER KING%E%[37m -- FINISHED%E%[0m
echo   %E%[36m==================================================%E%[0m
echo.
pause
exit /b

:: â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
::  Reusable branded header subroutine
:: â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
:print_header
echo   %E%[92m  ___  ___ ___    _   ___ ___ ___   _  _____ _  _  ___ %E%[0m
echo   %E%[92m / __^|/ __^| _ \  /_\ ^| _ \ __^| _ \ ^| ^|/ /_ _^| \^| ^|/ __^|%E%[0m
echo   %E%[92m \__ \ (__^|   / / _ \^|  _/ _^|^|   / ^| ' ^< ^| ^|^| .` ^| (__ %E%[0m
echo   %E%[92m ^|___/\___^|_^|_\/_/ \_\_^| ^|___^|_^|_\ ^|_^|\_\___^|_^|\_^|\___^|%E%[0m
echo.
echo   %E%[36m==================================================%E%[0m
echo   %E%[32m[+]%E%[37m FB Recovery OTP - Headless Engine V3%E%[0m
echo   %E%[32m[+]%E%[37m Developer  : %E%[33mScraper-King%E%[0m
echo   %E%[32m[+]%E%[37m Contact    : %E%[33mhttps://t.me/scraper_king%E%[0m
echo   %E%[32m[+]%E%[37m Version    : %E%[33m%VERSION%%E%[0m
echo   %E%[36m==================================================%E%[0m
echo.
goto :eof
