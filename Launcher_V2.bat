@echo off
setlocal enabledelayedexpansion
title ScraperKing V2 - FB Recovery OTP
chcp 437 >nul 2>nul

:: Generate real ESC character for ANSI colors
for /f %%a in ('echo prompt $E ^| cmd') do set "E=%%a"

cd /d "%~dp0"

:: ── ASCII Art Header ─────────────────────────────────────────
:show_header
cls
echo   %E%[92m  ___  ___ ___    _   ___ ___ ___   _  _____ _  _  ___ %E%[0m
echo   %E%[92m / __^|/ __^| _ \  /_\ ^| _ \ __^| _ \ ^| ^|/ /_ _^| \^| ^|/ __^|%E%[0m
echo   %E%[92m \__ \ (__^|   / / _ \^|  _/ _^|^|   / ^| ' ^< ^| ^|^| .` ^| (__ %E%[0m
echo   %E%[92m ^|___/\___^|_^|_\/_/ \_\_^| ^|___^|_^|_\ ^|_^|\_\___^|_^|\_^|\___^|%E%[0m
echo.
echo   %E%[36m==================================================%E%[0m
echo   %E%[32m[+]%E%[37m FB Recovery OTP - Emulator Engine V2%E%[0m
echo   %E%[32m[+]%E%[37m Developer  : %E%[33mScraper-King%E%[0m
echo   %E%[32m[+]%E%[37m Contact    : %E%[33mhttps://t.me/scraper_king%E%[0m
echo   %E%[36m==================================================%E%[0m
echo.
timeout /t 1 >nul

:: Find Node.js
set "NODE_EXE=node"
where node >nul 2>nul
if !errorlevel! neq 0 (
    set "NODE_EXE=C:\Program Files\nodejs\node.exe"
    if not exist "!NODE_EXE!" set "NODE_EXE=C:\Program Files (x86)\nodejs\node.exe"
    if not exist "!NODE_EXE!" set "NODE_EXE=%LOCALAPPDATA%\Programs\nodejs\node.exe"
)

set "NPM_CMD="
:: Find the absolute path to the real global npm.cmd
for /f "delims=" %%P in ('where npm.cmd 2^>nul') do (
    echo %%P | findstr /i "ScraperKing" >nul || (
        set "NPM_CMD=%%P"
        goto :found_npm
    )
)
:found_npm
if "!NPM_CMD!"=="" (
    set "NPM_CMD=C:\Program Files\nodejs\npm.cmd"
    if not exist "!NPM_CMD!" set "NPM_CMD=C:\Program Files (x86)\nodejs\npm.cmd"
    if not exist "!NPM_CMD!" set "NPM_CMD=%LOCALAPPDATA%\Programs\nodejs\npm.cmd"
)

if "!NODE_EXE!" neq "node" if not exist "!NODE_EXE!" (
    echo.
    echo  %E%[31m[~] Node.js not found! Please install from https://nodejs.org%E%[0m
    echo.
    pause
    exit /b 1
)

:: Install deps if missing (locked versions)
if not exist "%~dp0node_modules\log-update" (
    echo.
    echo  %E%[33m[*] Installing Emulator Engine dependencies...%E%[0m
    call "!NPM_CMD!" install --save log-update@4.0.0 chalk@4.1.2 fast-xml-parser
    if !errorlevel! neq 0 (
        echo  %E%[31m[~] Install failed. Check your internet connection.%E%[0m
        pause
        exit /b 1
    )
    echo  %E%[32m[+] Dependencies installed.%E%[0m
    timeout /t 1 >nul
)

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
echo   %E%[32m[+]%E%[37m Targets   : %E%[33m!NUMBERS_FILE!%E%[0m
echo   %E%[32m[+]%E%[37m Language  : %E%[33m!LANG_CODE!%E%[0m
echo   %E%[32m[+]%E%[37m Resends   : %E%[33m!RESENDS!%E%[0m
if not defined PROXY_FILE echo   %E%[32m[+]%E%[37m Proxy     : %E%[33mNone (Local IP)%E%[0m
if defined PROXY_FILE echo   %E%[32m[+]%E%[37m Proxy     : %E%[33m!PROXY_FILE!%E%[0m
echo   %E%[32m[+]%E%[37m Detection : %E%[33mAuto (MEmu/LDPlayer TCP Scan)%E%[0m
echo.
echo   %E%[36m==================================================%E%[0m
echo.
set "CONFIRM="
set /p "CONFIRM=  %E%[32m>%E%[37m Press ENTER to start or N to cancel: %E%[0m"
if /i "!CONFIRM!"=="N" goto ask_numbers

:: ── COPY NUMBERS FILE ─────────────────────────────────────────
copy /Y "!NUMBERS_FILE!" "%~dp0..\Number_List.txt" >nul

:: ── RUN ───────────────────────────────────────────────────────
cls
echo.
echo   %E%[33m[*] Starting V2 Emulator Engine...%E%[0m
echo   %E%[33m[*] Scanning for ADB devices on local network...%E%[0m
echo.

"!NODE_EXE!" "%~dp0index.js" "!NUMBERS_FILE!" "!RESENDS!" "!LANG_CODE!" "!PROXY_FILE!"

:: ── DONE ──────────────────────────────────────────────────────
echo.
echo   %E%[36m==================================================%E%[0m
echo   %E%[92m  SCRAPER KING V2%E%[37m -- FINISHED%E%[0m
echo   %E%[36m==================================================%E%[0m
echo.
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
echo   %E%[92m ^|___/\___^|_^|_\/_/ \_\_^| ^|___^|_^|_\ ^|_^|\_\___^|_^|\_^|\___^|%E%[0m
echo.
echo   %E%[36m==================================================%E%[0m
echo   %E%[32m[+]%E%[37m FB Recovery OTP - Emulator Engine V2%E%[0m
echo   %E%[32m[+]%E%[37m Developer  : %E%[33mScraper-King%E%[0m
echo   %E%[32m[+]%E%[37m Contact    : %E%[33mhttps://t.me/scraper_king%E%[0m
echo   %E%[36m==================================================%E%[0m
echo.
goto :eof
