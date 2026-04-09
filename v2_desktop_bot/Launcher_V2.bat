@echo off
setlocal enabledelayedexpansion
title ScraperKing V2 - FB Recovery OTP
chcp 437 >nul 2>nul

:: Generate real ESC character for ANSI colors
for /f %%a in ('echo prompt $E ^| cmd') do set "E=%%a"

cd /d "%~dp0"

set "VERSION=1.0"
set "PREMIUM_STATUS=TRIAL"

if "!SKING_MASTER_AUTH_PASSED!"=="1" goto :auth_passed

:: ── GENERATE HARDWARE ID ──────────────────────────────────────
set "HWID_TMP=%TEMP%\sk_hwid_%RANDOM%.tmp"
powershell -NoProfile -Command "$g = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Cryptography' -Name MachineGuid -ErrorAction SilentlyContinue).MachineGuid; if (-not $g) { $g = (Get-CimInstance Win32_ComputerSystemProduct).UUID }; if ($g) { $clean = $g -replace '-',''; $id = 'SKING-' + $clean.Substring(0,8) + '-' + $clean.Substring(8,4) + '-' + $clean.Substring(12,4); $id.ToUpper() } else { '' }" >"!HWID_TMP!"
set /p HARDWARE_ID=<"!HWID_TMP!"
del /f /q "!HWID_TMP!" 2>nul

if "%HARDWARE_ID%"=="" (
    echo   %E%[31m[-] Could not detect Hardware ID. Contact support.%E%[0m
    pause
    exit /b 1
)

:: ── FETCH VERSION FROM GITHUB (Obfuscated) ───────────────────
set "VER_SCRIPT=%TEMP%\sk_ver_%RANDOM%.ps1"
>"!VER_SCRIPT!" echo.$ErrorActionPreference='SilentlyContinue'
>>"!VER_SCRIPT!" echo.[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
>>"!VER_SCRIPT!" echo.$u1 = [char[]]@(104,116,116,112,115,58,47,47,114,97,119,46,103,105,116,104,117,98,117,115,101,114,99,111,110,116,101,110,116,46,99,111,109,47) -join ''
>>"!VER_SCRIPT!" echo.$u2 = [char[]]@(97,107,97,115,104,57,57,97,107,47) -join ''
>>"!VER_SCRIPT!" echo.$u3 = [char[]]@(83,99,97,112,101,114,45,107,105,110,103,47,109,97,105,110,47,118,101,114,115,105,111,110,46,106,115,111,110) -join ''
>>"!VER_SCRIPT!" echo.try { $r = (New-Object System.Net.WebClient).DownloadString($u1+$u2+$u3); $v = ($r ^| ConvertFrom-Json).version; Write-Host $v } catch { Write-Host '1.0' }
for /f "delims=" %%V in ('powershell -NoProfile -ExecutionPolicy Bypass -File "!VER_SCRIPT!"') do set "VERSION=%%V"
del /f /q "!VER_SCRIPT!" >nul 2>nul

:: ── SHOW SPLASH + VALIDATE LICENSE ──────────────────────────
cls
echo   %E%[92m  ___  ___ ___    _   ___ ___ ___   _  _____ _  _  ___ %E%[0m
echo   %E%[92m / __^|/ __^| _ \  /_\ ^| _ \ __^| _ \ ^| ^|/ /_ _^| \^| ^|/ __^|%E%[0m
echo   %E%[92m \__ \ (__^|   / / _ \^|  _/ _^|^|   / ^| ' ^< ^| ^|^| .` ^| (__ %E%[0m
echo   %E%[92m ^|___/\___^|_^|_\/_/ \_\_^| ^|___^|_^|_\ ^|_^|\_\___^|_^|\_\___^|%E%[0m
echo.
echo   %E%[32m[+]%E%[37m DEVELOPER  : %E%[33mScraper-King%E%[0m
echo   %E%[32m[+]%E%[37m CONTACT    : %E%[33mhttps://t.me/scraper_king%E%[0m
echo   %E%[32m[+]%E%[37m VERSION    : %E%[33m%VERSION%%E%[0m
echo   %E%[32m[+]%E%[37m PREMIUM    : %E%[33m%PREMIUM_STATUS%%E%[0m
echo   %E%[36m=========================================================%E%[0m
echo.
echo   %E%[36m--------------------------------------------------%E%[0m
echo   %E%[32m  YOUR HARDWARE ID:%E%[0m
echo   %E%[33m  %HARDWARE_ID%%E%[0m
echo   %E%[36m--------------------------------------------------%E%[0m
echo.
echo   %E%[33m[*] Validating license with server...%E%[0m
echo.

:: ── VALIDATE AGAINST GIST (OBFUSCATED URL) ──────────────────
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
set "KEY_USER=Unknown"
set "KEY_EXPIRES="
for /f "tokens=1,2,3 delims=|" %%A in ('powershell -NoProfile -ExecutionPolicy Bypass -File "!PS_SCRIPT!"') do (
    set "VALIDATION_CODE=%%A"
    set "KEY_USER=%%B"
    set "KEY_EXPIRES=%%C"
)
del /f /q "!PS_SCRIPT!" >nul 2>nul

if "!VALIDATION_CODE!"=="1" (
    echo   %E%[32m[+] License APPROVED!%E%[0m
    echo   %E%[32m[+] User    : %E%[33m!KEY_USER!%E%[0m
    echo   %E%[32m[+] Expires : %E%[33m!KEY_EXPIRES!%E%[0m
    echo.
    timeout /t 2 >nul
    goto :auth_passed
)
if "!VALIDATION_CODE!"=="2" (
    echo   %E%[31m[-] License EXPIRED! User: !KEY_USER! Expired: !KEY_EXPIRES!%E%[0m
    echo   %E%[33m    Contact https://t.me/scraper_king to renew.%E%[0m
    pause & exit /b 1
)
if "!VALIDATION_CODE!"=="3" (
    echo   %E%[31m[-] Could not reach license server! Check internet.%E%[0m
    pause & exit /b 1
)
echo   %E%[31m[!] License NOT APPROVED%E%[0m
echo   %E%[33m  Your Hardware ID: %E%[36m%HARDWARE_ID%%E%[0m
echo   %E%[33m  Send to: %E%[32mhttps://t.me/scraper_king%E%[0m
pause & exit /b 1

:: ══════════════════════════════════════════════════════════════
::  AUTH PASSED — Setup & Steps
:: ══════════════════════════════════════════════════════════════
:auth_passed

:: Find Node.js (with auto-download for new users)
set "NODE_EXE=node"
where node >nul 2>nul
if !errorlevel! neq 0 (
    set "NODE_EXE=%~dp0bin\node\node.exe"
    if not exist "!NODE_EXE!" set "NODE_EXE=C:\Program Files\nodejs\node.exe"
    if not exist "!NODE_EXE!" set "NODE_EXE=C:\Program Files (x86)\nodejs\node.exe"
    if not exist "!NODE_EXE!" set "NODE_EXE=%LOCALAPPDATA%\Programs\nodejs\node.exe"
)

:: Auto-Download Portable Node.js if completely missing
if "!NODE_EXE!" neq "node" if not exist "!NODE_EXE!" (
    cls
    call :print_header
    echo   %E%[33m  FIRST-TIME SETUP: Node.js Runtime%E%[0m
    echo   %E%[36m--------------------------------------------------%E%[0m
    echo.
    echo   %E%[37m  Node.js is not installed. Downloading portable runtime...%E%[0m
    echo.
    mkdir "%~dp0bin" 2>nul
    powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://nodejs.org/dist/v20.11.1/node-v20.11.1-win-x64.zip' -OutFile '%~dp0bin\node.zip'"
    if exist "%~dp0bin\node.zip" (
        echo   %E%[33m  Extracting...%E%[0m
        powershell -Command "Expand-Archive -Path '%~dp0bin\node.zip' -DestinationPath '%~dp0bin' -Force"
        rename "%~dp0bin\node-v20.11.1-win-x64" "node"
        del /q "%~dp0bin\node.zip"
        set "NODE_EXE=%~dp0bin\node\node.exe"
        set "PATH=%~dp0bin\node;!PATH!"
        echo  %E%[32m[+] Portable Runtime installed!%E%[0m
        timeout /t 2 >nul
    ) else (
        echo  %E%[31m[!] Failed to download Node.js.%E%[0m
        pause & exit /b 1
    )
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

:: Install deps if missing (check ALL critical packages)
set "DEPS_MISSING=0"
if not exist "%~dp0node_modules\log-update" set "DEPS_MISSING=1"
if not exist "%~dp0node_modules\chalk" set "DEPS_MISSING=1"
if not exist "%~dp0node_modules\fast-xml-parser" set "DEPS_MISSING=1"
if "!DEPS_MISSING!"=="1" (
    echo.
    echo  %E%[33m[*] Installing Emulator Engine dependencies...%E%[0m

    :: Auto-generate package.json if missing (user downloaded without it)
    if not exist "%~dp0package.json" (
        echo  %E%[33m[*] Generating package manifest...%E%[0m
        >"%~dp0package.json" echo {
        >>"%~dp0package.json" echo   "name": "v2_desktop_bot",
        >>"%~dp0package.json" echo   "version": "1.0.0",
        >>"%~dp0package.json" echo   "type": "commonjs",
        >>"%~dp0package.json" echo   "dependencies": {
        >>"%~dp0package.json" echo     "chalk": "^4.1.2",
        >>"%~dp0package.json" echo     "cli-progress": "^3.12.0",
        >>"%~dp0package.json" echo     "fast-xml-parser": "^5.5.9",
        >>"%~dp0package.json" echo     "log-update": "^4.0.0",
        >>"%~dp0package.json" echo     "node-fetch": "^2.7.0",
        >>"%~dp0package.json" echo     "unzipper": "^0.12.3"
        >>"%~dp0package.json" echo   }
        >>"%~dp0package.json" echo }
    )

    call "!NPM_CMD!" install --production --no-fund
    if !errorlevel! neq 0 (
        echo  %E%[31m[~] Setup failed: Could not install node packages. Please manually open CMD here and run: npm install%E%[0m
        pause
        exit /b 1
    )
    :: Verify critical packages actually installed
    if not exist "%~dp0node_modules\fast-xml-parser" (
        echo  %E%[31m[~] Critical package 'fast-xml-parser' missing after install! Run: npm install%E%[0m
        pause
        exit /b 1
    )
    echo  %E%[32m[+] Dependencies installed.%E%[0m
    timeout /t 1 >nul
)

:: ── STEP 0: App Selection ───────────────────────────────────────
:ask_app
cls
call :print_header
echo   %E%[33m  Step 0: Select App%E%[0m
echo   %E%[36m--------------------------------------------------%E%[0m
echo.
echo   %E%[37m  [%E%[33m1%E%[37m] Facebook Lite         %E%[90m(com.facebook.lite)%E%[0m
echo   %E%[37m  [%E%[33m2%E%[37m] KKH Facebook Lite Pro %E%[90m(app.kkh.pro)%E%[0m
echo   %E%[37m  [%E%[33m3%E%[37m] LiteX Facebook        %E%[90m(com.facebook.litx)%E%[0m
echo   %E%[37m  [%E%[33m4%E%[37m] Custom Package Name   %E%[90m(enter manually)%E%[0m
echo.
set "APP_CHOICE=1"
set /p "APP_CHOICE=  %E%[32m>%E%[37m Select app [1-4] (default 1): %E%[0m"

if "!APP_CHOICE!"=="1" (
    set "APP_KEY=fb_lite"
    set "APP_DISPLAY=Facebook Lite"
) else if "!APP_CHOICE!"=="2" (
    set "APP_KEY=kkh_lite"
    set "APP_DISPLAY=KKH Lite Pro"
) else if "!APP_CHOICE!"=="3" (
    set "APP_KEY=litex"
    set "APP_DISPLAY=LiteX Facebook"
) else if "!APP_CHOICE!"=="4" (
    set "CUSTOM_PKG="
    set /p "CUSTOM_PKG=  %E%[32m>%E%[37m Enter package name: %E%[0m"
    if "!CUSTOM_PKG!"=="" (
        echo  %E%[31m[~] Package name required.%E%[0m
        timeout /t 1 >nul
        goto ask_app
    )
    set "APP_KEY=custom:!CUSTOM_PKG!"
    set "APP_DISPLAY=Custom (!CUSTOM_PKG!)"
) else (
    set "APP_KEY=fb_lite"
    set "APP_DISPLAY=Facebook Lite"
)
echo   %E%[32m[+]%E%[37m Selected: %E%[33m!APP_DISPLAY!%E%[0m
timeout /t 1 >nul

:: ── STEP 1: Numbers file ──────────────────────────────────────
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

echo "!NUMBERS_FILE!" | findstr /i "\.bat$" >nul
if !errorlevel! equ 0 (
    echo  %E%[31m[~] ERROR: You dragged a batch script instead of a numbers file!%E%[0m
    timeout /t 2 >nul
    goto ask_numbers
)
echo "!NUMBERS_FILE!" | findstr /i "\.js$" >nul
if !errorlevel! equ 0 (
    echo  %E%[31m[~] ERROR: You dragged a JS file instead of a numbers file!%E%[0m
    timeout /t 2 >nul
    goto ask_numbers
)

:: ── STEP 2: Language Configuration ───────────────────────────
:ask_language
cls
call :print_header
echo   %E%[33m  Step 2: Language%E%[0m
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
echo   %E%[33m  Step 2: Select Language%E%[0m
echo   %E%[36m--------------------------------------------------%E%[0m
echo.
echo   %E%[37m  1: EN   2: ES   3: FR   4: DE   5: PT   6: IT%E%[0m
echo   %E%[37m  7: AR   8: HI   9: BN  10: ID  11: RU%E%[0m
echo.
set "FB_LANG="
set /p "FB_LANG=  %E%[32m>%E%[37m Language (1-11) [Default 1-EN]: %E%[0m"
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
goto language_done

:multi_language
cls
call :print_header
echo   %E%[33m  Step 2: Multi-Language Selection%E%[0m
echo   %E%[36m--------------------------------------------------%E%[0m
echo.
echo   %E%[37m  Languages: 1:EN 2:ES 3:FR 4:DE 5:PT 6:IT 7:AR 8:HI 9:BN 10:ID 11:RU%E%[0m
echo   %E%[37m  Example inputs: "1-3" or "1,2,5" or "1-11"%E%[0m
echo.
set "MULTI_LANG="
set /p "MULTI_LANG=  %E%[32m>%E%[37m Selection (Default 1-3): %E%[0m"
if "!MULTI_LANG!"=="" set "MULTI_LANG=1-3"

set "LANG_CODES="
set "_tempLang_=!MULTI_LANG:,= !"

for %%a in (!_tempLang_!) do (
    set "token=%%a"
    echo "!token!" | find "-" >nul
    if !errorlevel! equ 0 (
        for /f "tokens=1,2 delims=-" %%s in ("%%a") do (
            set "start=%%s"
            set "end=%%t"
        )
        if "!start!"=="" set "start=!end!"
        if "!end!"=="" set "end=!start!"
        for /l %%i in (!start!,1,!end!) do (
            call :AddLanguage %%i
        )
    ) else (
        call :AddLanguage %%a
    )
)

if "!LANG_CODES!" neq "" set "LANG_CODES=!LANG_CODES:~0,-1!"
set "LANG_CODE=!LANG_CODES!"
goto language_done

:AddLanguage
set "num=%~1"
if !num! geq 1 if !num! leq 11 (
    if "!num!"=="1" set "LANG_CODES=!LANG_CODES!en,"
    if "!num!"=="2" set "LANG_CODES=!LANG_CODES!es,"
    if "!num!"=="3" set "LANG_CODES=!LANG_CODES!fr,"
    if "!num!"=="4" set "LANG_CODES=!LANG_CODES!de,"
    if "!num!"=="5" set "LANG_CODES=!LANG_CODES!pt,"
    if "!num!"=="6" set "LANG_CODES=!LANG_CODES!it,"
    if "!num!"=="7" set "LANG_CODES=!LANG_CODES!ar,"
    if "!num!"=="8" set "LANG_CODES=!LANG_CODES!hi,"
    if "!num!"=="9" set "LANG_CODES=!LANG_CODES!bn,"
    if "!num!"=="10" set "LANG_CODES=!LANG_CODES!id,"
    if "!num!"=="11" set "LANG_CODES=!LANG_CODES!ru,"
)
goto :eof

:language_done

:: ── STEP 3: Proxy Configuration ──────────────────────────
:ask_proxy
cls
call :print_header
echo   %E%[33m  Step 3: Proxy Configuration%E%[0m
echo   %E%[36m--------------------------------------------------%E%[0m
echo.
echo   %E%[32m[1]%E%[37m No Proxy (use local IP)%E%[0m
echo   %E%[32m[2]%E%[37m Load SOCKS5 proxy list%E%[0m
echo.
set "PROXY_MODE="
set /p "PROXY_MODE=  %E%[32m>%E%[37m Choice [1-2] (Default 1): %E%[0m"
if "!PROXY_MODE!"=="" set "PROXY_MODE=1"

set "PROXY_FILE="
if "!PROXY_MODE!"=="1" goto skip_proxy

set /p "PROXY_FILE=  %E%[32m>%E%[37m Proxy file path (or drag/drop): %E%[0m"
set "PROXY_FILE=!PROXY_FILE:"=!"

if "!PROXY_FILE!"=="" (
    echo  %E%[31m[~] No file provided. Running without proxies.%E%[0m
    timeout /t 1 >nul
    goto skip_proxy
)
if not exist "!PROXY_FILE!" (
    echo  %E%[31m[~] File not found. Running without proxies.%E%[0m
    set "PROXY_FILE="
    timeout /t 1 >nul
    goto skip_proxy
)
echo  %E%[32m[+] Proxy file loaded.%E%[0m

:skip_proxy

:: ── STEP 4: OTP Resend Configuration ──────────────────────────
:ask_resends
cls
call :print_header
echo   %E%[33m  Step 4: OTP Resends%E%[0m
echo   %E%[36m--------------------------------------------------%E%[0m
echo.
echo   %E%[37m  How many additional times should the bot re-send?%E%[0m
echo   %E%[37m  (0 = 1 total SMS, 1 = 2 total SMS, 2 = 3 total SMS)%E%[0m
echo.
set "RESENDS="
set /p "RESENDS=  %E%[32m>%E%[37m Resends [0-5] (Default 0): %E%[0m"
if "!RESENDS!"=="" set "RESENDS=0"

:: ── CONFIRM ───────────────────────────────────────────────────
cls
call :print_header
echo   %E%[33m  READY FOR LAUNCH%E%[0m
echo   %E%[36m--------------------------------------------------%E%[0m
echo.
echo   %E%[32m[+]%E%[37m Engine    : %E%[33mAndroid Emulator (ADB)%E%[0m
echo   %E%[32m[+]%E%[37m App       : %E%[33m!APP_DISPLAY!%E%[0m
echo   %E%[32m[+]%E%[37m Targets   : %E%[33m!NUMBERS_FILE!%E%[0m
echo   %E%[32m[+]%E%[37m Language  : %E%[33m!LANG_CODE!%E%[0m
echo   %E%[32m[+]%E%[37m Resends   : %E%[33m!RESENDS!%E%[0m
if not defined PROXY_FILE echo   %E%[32m[+]%E%[37m Proxy     : %E%[33mNone (Local IP)%E%[0m
if defined PROXY_FILE echo   %E%[32m[+]%E%[37m Proxy     : %E%[33m!PROXY_FILE!%E%[0m
echo   %E%[32m[+]%E%[37m Detection : %E%[33mAuto (MEmu/LDPlayer TCP Scan)%E%[0m
echo.
echo   %E%[36m==================================================%E%[0m
echo   %E%[33m  EMULATOR SETUP INSTRUCTIONS:%E%[0m
echo   %E%[37m  1. Open your Android Emulator (MEmu, LDPlayer, etc.)%E%[0m
echo   %E%[37m  2. Create as many emulator instances as you need (workers).%E%[0m
echo   %E%[37m  3. Ensure %E%[33m!APP_DISPLAY!%E%[37m is installed on all of them.%E%[0m
echo   %E%[37m  4. Close the app and leave them on the home screen.%E%[0m
echo   %E%[36m==================================================%E%[0m
echo.
set "CONFIRM="
set /p "CONFIRM=  %E%[32m>%E%[37m Press ENTER to start or N to cancel: %E%[0m"
if /i "!CONFIRM!"=="N" goto ask_numbers

:: ── RUN ───────────────────────────────────────────────────────
cls
echo.
echo   %E%[33m[*] Starting V2 Emulator Engine...%E%[0m
echo   %E%[33m[*] App: !APP_DISPLAY!%E%[0m
echo   %E%[33m[*] Scanning for ADB devices on local network...%E%[0m
echo.

"!NODE_EXE!" "%~dp0index.js" "!NUMBERS_FILE!" "!RESENDS!" "!LANG_CODE!" "!PROXY_FILE!" "!APP_KEY!"
set "ENGINE_EXIT=!errorlevel!"

:: ── DONE ──────────────────────────────────────────────────────
echo.
if "!ENGINE_EXIT!" neq "0" (
    echo   %E%[31m==================================================%E%[0m
    echo   %E%[31m  ENGINE CRASHED ^(Exit Code: !ENGINE_EXIT!^)%E%[0m
    echo   %E%[31m==================================================%E%[0m
    echo.
    echo   %E%[33m  Check these files for details:%E%[0m
    echo   %E%[37m    - %~dp0debug_emu.txt%E%[0m
    echo   %E%[37m    - %~dp0fatal_error.log%E%[0m
    echo.
    echo   %E%[33m  Common fixes:%E%[0m
    echo   %E%[37m    1. Run: npm install   ^(in this folder^)%E%[0m
    echo   %E%[37m    2. Make sure Node.js is installed%E%[0m
    echo   %E%[37m    3. Contact https://t.me/scraper_king%E%[0m
    echo.
) else (
    echo   %E%[36m==================================================%E%[0m
    echo   %E%[92m  SCRAPER KING V2%E%[37m -- FINISHED%E%[0m
    echo   %E%[36m==================================================%E%[0m
    echo.
)
for %%F in ("!NUMBERS_FILE!") do set "OUT_DIR=%%~dpF"
explorer "!OUT_DIR!"
pause
goto :eof

:: ═══════════════════════════════════════════════════════════════
::  Reusable branded header subroutine
:: ═══════════════════════════════════════════════════════════════
:print_header
echo   %E%[92m  ___  ___ ___    _   ___ ___ ___   _  _____ _  _  ___ %E%[0m
echo   %E%[92m / __^|/ __^| _ \  /_\ ^| _ \ __^| _ \ ^| ^|/ /_ _^| \^| ^|/ __^|%E%[0m
echo   %E%[92m \__ \ (__^|   / / _ \^|  _/ _^|^|   / ^| ' ^< ^| ^|^| .` ^| (__ %E%[0m
echo   %E%[92m ^|___/\___^|_^|_\/_/ \_\_^| ^|___^|_^|_\ ^|_^|\_\___^|_^|\_\___^|%E%[0m
echo.
echo   %E%[36m==================================================%E%[0m
echo   %E%[32m[+]%E%[37m FB Recovery OTP - Emulator Engine V2%E%[0m
echo   %E%[32m[+]%E%[37m Developer  : %E%[33mScraper-King%E%[0m
echo   %E%[32m[+]%E%[37m Contact    : %E%[33mhttps://t.me/scraper_king%E%[0m
echo   %E%[32m[+]%E%[37m Version    : %E%[33m%VERSION%%E%[0m
echo   %E%[36m==================================================%E%[0m
echo.
goto :eof
