@echo off
setlocal enabledelayedexpansion
title ScraperKing - FB Recovery OTP
chcp 437 >nul 2>nul

:: Generate real ESC character for ANSI colors
for /f %%a in ('echo prompt $E ^| cmd') do set "E=%%a"

cd /d "%~dp0"

:: ── Developer Mode (No License) ─────────────────────────
set "HARDWARE_ID=%~1"

:: ── ASCII Art Header ─────────────────────────────────────────
:show_header
cls
echo   %E%[92m  ___  ___ ___    _   ___ ___ ___   _  _____ _  _  ___ %E%[0m
echo   %E%[92m / __^|/ __^| _ \  /_\ ^| _ \ __^| _ \ ^| ^|/ /_ _^| \^| ^|/ __^|%E%[0m
echo   %E%[92m \__ \ (__^|   / / _ \^|  _/ _^|^|   / ^| ' ^< ^| ^|^| .` ^| (__ %E%[0m
echo   %E%[92m ^|___/\___^|_^|_\/_/ \_\_^| ^|___^|_^|_\ ^|_^|\_\___^|_^|\_^|\___^|%E%[0m
echo.
echo   %E%[36m==================================================%E%[0m
echo   %E%[32m[+]%E%[37m FB Recovery OTP Autofill Engine%E%[0m
echo   %E%[32m[+]%E%[37m Developer  : %E%[33mScraper-King%E%[0m
echo   %E%[32m[+]%E%[37m Contact    : %E%[33mhttps://t.me/scraper_king%E%[0m
echo   %E%[33m[~] Auto Logging : Under Development%E%[0m
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

set "NPM_CMD=npm.cmd"
where npm >nul 2>nul
if !errorlevel! neq 0 (
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

:: Install packages if missing
if not exist "%~dp0node_modules\playwright-extra" (
    cls
    echo.
    echo  %E%[33m[*] Installing required Node packages...%E%[0m
    echo.
    call "!NPM_CMD!" install playwright playwright-extra puppeteer-extra-plugin-stealth axios socks-proxy-agent
    if !errorlevel! neq 0 (
        echo  %E%[31m[~] Install failed. Check your internet connection.%E%[0m
        pause
        exit /b 1
    )
    echo  %E%[33m[*] Installing headless Chrome...%E%[0m
    call "!NODE_EXE!" "%~dp0node_modules\.bin\playwright" install chromium
    echo  %E%[32m[+] Setup complete.%E%[0m
    timeout /t 2 >nul
)

:: ── STEP 1: Numbers file ──────────────────────────────────────
:ask_numbers
cls
echo.
echo   %E%[36m==================================================%E%[0m
echo   %E%[92m  SCRAPER KING%E%[37m -- Step 1: Target List%E%[0m
echo   %E%[36m==================================================%E%[0m
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

:: Basic protection against passing the script as the input list
echo "!NUMBERS_FILE!" | findstr /i "\.bat$" >nul
if !errorlevel! equ 0 (
    echo  %E%[31m[~] ERROR: You dragged a batch script file instead of a numbers text file!%E%[0m
    timeout /t 2 >nul
    goto ask_numbers
)
echo "!NUMBERS_FILE!" | findstr /i "\.js$" >nul
if !errorlevel! equ 0 (
    echo  %E%[31m[~] ERROR: You dragged a JS file instead of a numbers text file!%E%[0m
    timeout /t 2 >nul
    goto ask_numbers
)

:: ── STEP 2: Proxy Configuration ────────────────────────────────
:ask_proxy
cls
echo.
echo   %E%[36m==================================================%E%[0m
echo   %E%[92m  SCRAPER KING%E%[37m -- Step 2: Proxy Method%E%[0m
echo   %E%[36m==================================================%E%[0m
echo.
    echo   %E%[32m[1]%E%[37m Auto Scraping (Proxies)%E%[0m
    echo   %E%[32m[2]%E%[37m VPN / Mobile Data (No Timeout)%E%[0m
    echo   %E%[32m[3]%E%[37m Custom File%E%[0m
    echo   %E%[32m[4]%E%[37m Direct Connection (No Proxy)%E%[0m
    echo.
    set "PROXY_CHOICE="
    set /p "PROXY_CHOICE=  %E%[32m>%E%[37m Choice [1-4] (Default 1): %E%[0m"
    if "!PROXY_CHOICE!"=="" set "PROXY_CHOICE=1"

    if "!PROXY_CHOICE!"=="1" goto auto_proxy
    if "!PROXY_CHOICE!"=="2" goto vpn_proxy
    if "!PROXY_CHOICE!"=="3" goto custom_proxy
    if "!PROXY_CHOICE!"=="4" goto direct_proxy
    goto ask_proxy

:auto_proxy
    set "PROXY_CHOICE=auto"
    set "PROXY_FILE="
    set "PROXY_STATUS=Auto (Public Proxies)"
    goto ask_proxy_protocol

:vpn_proxy
    set "PROXY_CHOICE=vpn"
    set "PROXY_FILE="
    set "PROXY_COUNTRY=none"
    set "PROXY_PROTOCOL=http"
    set "PROXY_STATUS=VPN / Mobile Data (No Timeout)"
    goto ask_workers

:ask_proxy_country
cls
echo.
echo   %E%[36m==================================================%E%[0m
echo   %E%[92m  SCRAPER KING%E%[37m -- Step 2.5: Proxy Country%E%[0m
echo   %E%[36m==================================================%E%[0m
echo.
echo   %E%[32m[1]%E%[37m Auto-Detect from Numbers File (Smartest)%E%[0m
echo   %E%[32m[2]%E%[37m All Countries (Fastest, max speed)%E%[0m
echo   %E%[32m[3]%E%[37m View Common Country Codes%E%[0m
echo   %E%[32m[4]%E%[37m Enter custom 2-Letter Code (e.g. US, BD)%E%[0m
echo.
set "COUNTRY_CHOICE="
set /p "COUNTRY_CHOICE=  %E%[32m>%E%[37m Choice [1-4] (Default 1): %E%[0m"
if "!COUNTRY_CHOICE!"=="" set "COUNTRY_CHOICE=1"

if "!COUNTRY_CHOICE!"=="1" (
    set "PROXY_COUNTRY=auto_detect"
    goto ask_proxy_timing
)
if "!COUNTRY_CHOICE!"=="2" (
    set "PROXY_COUNTRY=all"
    goto ask_proxy_timing
)
if "!COUNTRY_CHOICE!"=="3" (
    cls
    echo.
    echo   %E%[36m  COMMON COUNTRY CODES:%E%[0m
    echo   %E%[36m  ----------------------------------------%E%[0m
    echo   %E%[37m  US: United States   GB: United Kingdom%E%[0m
    echo   %E%[37m  CA: Canada          AU: Australia%E%[0m
    echo   %E%[37m  IN: India           BD: Bangladesh%E%[0m
    echo   %E%[37m  PK: Pakistan        ID: Indonesia%E%[0m
    echo   %E%[37m  PH: Philippines     VN: Vietnam%E%[0m
    echo   %E%[37m  BR: Brazil          MX: Mexico%E%[0m
    echo   %E%[37m  DE: Germany         FR: France%E%[0m
    echo   %E%[37m  ES: Spain           IT: Italy%E%[0m
    echo   %E%[37m  RU: Russia          NG: Nigeria%E%[0m
    echo   %E%[37m  EG: Egypt           ZA: South Africa%E%[0m
    echo   %E%[36m  ----------------------------------------%E%[0m
    echo.
    goto ask_proxy_country_code
)

:ask_proxy_country_code
set "PROXY_COUNTRY="
set /p "PROXY_COUNTRY=  %E%[32m>%E%[37m Enter 2-Letter Code: %E%[0m"
if "!PROXY_COUNTRY!"=="" set "PROXY_COUNTRY=auto_detect"
goto ask_proxy_timing

:custom_proxy
echo.
echo   %E%[33m[*]\x1b[37m Supported Formats for Single Proxy Strings:%E%[0m
echo       - %E%[36mip:port%E%[0m
echo       - %E%[36mip:port:user:pass%E%[0m
echo       - %E%[36muser:pass@ip:port%E%[0m
echo       - %E%[36mip:port@user:pass%E%[0m
echo.
set "PROXY_FILE="
set "PROXY_COUNTRY=all"
set /p "PROXY_FILE=  %E%[32m>%E%[37m Proxy string or file path: %E%[0m"
set "PROXY_FILE=!PROXY_FILE:"=!"

if "!PROXY_FILE!"=="" (
    set "PROXY_CHOICE=direct"
    set "PROXY_STATUS=Direct (No proxy provided)"
    set "PROXY_USE_LIMIT=1"
    goto ask_workers
)

:: If the input contains a colon, it's likely a raw proxy string, so bypass file check
echo !PROXY_FILE! | findstr /C:":" >nul
if !errorlevel! neq 0 (
    if not exist "!PROXY_FILE!" (
        set "PROXY_CHOICE=direct"
        set "PROXY_STATUS=Direct (File not found)"
        set "PROXY_USE_LIMIT=1"
        goto ask_workers
    )
)

set "PROXY_CHOICE=custom"
set "PROXY_STATUS=Custom File (!PROXY_FILE!)"

echo.
echo   %E%[37m  How many times should each proxy be used before moving to the next?%E%[0m
set "PROXY_USE_LIMIT="
set /p "PROXY_USE_LIMIT=  %E%[32m>%E%[37m Usages per proxy (Default 1): %E%[0m"
if "!PROXY_USE_LIMIT!"=="" set "PROXY_USE_LIMIT=1"

cls
echo.
echo   %E%[36m==================================================%E%[0m
echo   %E%[92m  SCRAPER KING%E%[37m -- Custom Proxy Protocol%E%[0m
echo   %E%[36m==================================================%E%[0m
echo.
echo   %E%[32m[1]%E%[37m HTTP / HTTPS  (Most premium proxies)%E%[0m
echo   %E%[32m[2]%E%[37m SOCKS4%E%[0m
echo   %E%[32m[3]%E%[37m SOCKS5        (OwlProxy, PIA, etc.)%E%[0m
echo.
set "CUSTOM_PROTO_CHOICE="
set /p "CUSTOM_PROTO_CHOICE=  %E%[32m>%E%[37m Protocol [1-3] (Default 1): %E%[0m"
if "!CUSTOM_PROTO_CHOICE!"=="" set "CUSTOM_PROTO_CHOICE=1"

set "PROXY_PROTOCOL=http"
if "!CUSTOM_PROTO_CHOICE!"=="2" set "PROXY_PROTOCOL=socks4"
if "!CUSTOM_PROTO_CHOICE!"=="3" set "PROXY_PROTOCOL=socks5"

cls
echo.
echo   %E%[36m==================================================%E%[0m
echo   %E%[92m  SCRAPER KING%E%[37m -- Custom Proxy Type%E%[0m
echo   %E%[36m==================================================%E%[0m
echo.
echo   %E%[32m[1]%E%[37m Datacenter / Static IPv4 (No location targeting)%E%[0m
echo   %E%[32m[2]%E%[37m Residential (Dynamic location targeting)%E%[0m
echo.
set "PROXY_TYPE_CHOICE="
set /p "PROXY_TYPE_CHOICE=  %E%[32m>%E%[37m Choice [1-2] (Default 1): %E%[0m"
if "!PROXY_TYPE_CHOICE!"=="" set "PROXY_TYPE_CHOICE=1"

if "!PROXY_TYPE_CHOICE!"=="1" (
    set "PROXY_TYPE=datacenter"
    set "PROXY_COUNTRY=none"
    goto ask_proxy_timing
)

set "PROXY_TYPE=residential"
cls
echo.
echo   %E%[36m==================================================%E%[0m
echo   %E%[92m  SCRAPER KING%E%[37m -- Custom Proxy Provider%E%[0m
echo   %E%[36m==================================================%E%[0m
echo.
echo   %E%[32m[1]%E%[37m Auto-Detect from String (Recommended)%E%[0m
echo   %E%[32m[2]%E%[37m BrightData%E%[0m
echo   %E%[32m[3]%E%[37m IPRoyal / SmartProxy%E%[0m
echo   %E%[32m[4]%E%[37m Webshare%E%[0m
echo   %E%[32m[5]%E%[37m ProxyRack%E%[0m
echo.
set "PROXY_PROVIDER_CHOICE="
set /p "PROXY_PROVIDER_CHOICE=  %E%[32m>%E%[37m Choice [1-5] (Default 1): %E%[0m"
if "!PROXY_PROVIDER_CHOICE!"=="" set "PROXY_PROVIDER_CHOICE=1"

set "PROXY_PROVIDER=auto"
if "!PROXY_PROVIDER_CHOICE!"=="2" set "PROXY_PROVIDER=brightdata"
if "!PROXY_PROVIDER_CHOICE!"=="3" set "PROXY_PROVIDER=iproyal"
if "!PROXY_PROVIDER_CHOICE!"=="4" set "PROXY_PROVIDER=webshare"
if "!PROXY_PROVIDER_CHOICE!"=="5" set "PROXY_PROVIDER=proxyrack"

goto ask_proxy_country

:direct_proxy
set "PROXY_CHOICE=direct"
set "PROXY_FILE="
set "PROXY_COUNTRY=all"
set "PROXY_PROTOCOL=http"
set "PROXY_STATUS=Direct Connection"
goto ask_workers

:: ── STEP 2.3: Proxy Protocol (Auto mode) ──────────────────────────
:ask_proxy_protocol
cls
echo.
echo   %E%[36m==================================================%E%[0m
echo   %E%[92m  SCRAPER KING%E%[37m -- Step 2.3: Proxy Protocol%E%[0m
echo   %E%[36m==================================================%E%[0m
echo.
echo   %E%[37m  Select the protocol to scrape from public proxy lists:%E%[0m
echo.
echo   %E%[32m[1]%E%[37m HTTP / HTTPS        (Classic, best compatibility)%E%[0m
echo   %E%[32m[2]%E%[37m SOCKS4              (Faster tunneling)%E%[0m
echo   %E%[32m[3]%E%[37m SOCKS5              (Most available free proxies)%E%[0m
echo.
set "PROTO_CHOICE="
set /p "PROTO_CHOICE=  %E%[32m>%E%[37m Protocol [1-3] (Default 3): %E%[0m"
if "!PROTO_CHOICE!"=="" set "PROTO_CHOICE=3"

set "PROXY_PROTOCOL=socks5"
if "!PROTO_CHOICE!"=="1" set "PROXY_PROTOCOL=http"
if "!PROTO_CHOICE!"=="2" set "PROXY_PROTOCOL=socks4"
if "!PROTO_CHOICE!"=="3" set "PROXY_PROTOCOL=socks5"

goto ask_proxy_country

:: ── STEP 2.8: Proxy Timing ────────────────────────────────────────
:ask_proxy_timing
cls
echo.
echo   %E%[36m==================================================%E%[0m
echo   %E%[92m  SCRAPER KING%E%[37m -- Step 2.8: When to connect proxy?%E%[0m
echo   %E%[36m==================================================%E%[0m
echo.
echo   %E%[32m[1]%E%[37m From the start (Browser is completely proxy covered)%E%[0m
echo   %E%[32m[2]%E%[37m When the SMS option is found (Fast, uses local IP first)%E%[0m
echo.
set "PROXY_TIMING_CHOICE="
set /p "PROXY_TIMING_CHOICE=  %E%[32m>%E%[37m Choice [1-2] (Default 1): %E%[0m"
if "!PROXY_TIMING_CHOICE!"=="" set "PROXY_TIMING_CHOICE=1"

if "!PROXY_TIMING_CHOICE!"=="1" set "PROXY_TIMING=early"
if "!PROXY_TIMING_CHOICE!"=="2" set "PROXY_TIMING=late"

goto ask_workers

:: ── STEP 3: Worker Configuration ────────────────────────────────
:ask_workers
cls
echo.
echo   %E%[36m==================================================%E%[0m
echo   %E%[92m  SCRAPER KING%E%[37m -- Step 3: Workers%E%[0m
echo   %E%[36m==================================================%E%[0m
echo.
echo   %E%[37m  Leave blank to auto-detect optimal limit based on PC hardware.%E%[0m
echo.
set "WORKERS="
set /p "WORKERS=  %E%[32m>%E%[37m Number of workers (Enter to auto-detect): %E%[0m"

:: ── STEP 4: Language Configuration ───────────────────────────
:ask_language
cls
echo.
echo   %E%[36m==================================================%E%[0m
echo   %E%[92m  SCRAPER KING%E%[37m -- Step 4: Languages%E%[0m
echo   %E%[36m==================================================%E%[0m
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
echo.
echo   %E%[36m==================================================%E%[0m
echo   %E%[92m  SCRAPER KING%E%[37m -- Select Language%E%[0m
echo   %E%[36m==================================================%E%[0m
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
echo.
echo   %E%[36m==================================================%E%[0m
echo   %E%[92m  SCRAPER KING%E%[37m -- Multi-Language Selection%E%[0m
echo   %E%[36m==================================================%E%[0m
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

:: ── STEP 5: URL Selection ─────────────────────────────────────
:ask_urls
cls
echo.
echo   %E%[36m==================================================%E%[0m
echo   %E%[92m  SCRAPER KING%E%[37m -- Step 5: Target URLs%E%[0m
echo   %E%[36m==================================================%E%[0m
echo.
echo   %E%[32m[1]%E%[37m Auto (All available URLs for selected language)%E%[0m
echo   %E%[32m[2]%E%[37m Select specific URLs%E%[0m
echo.
set "URL_MODE="
set /p "URL_MODE=  %E%[32m>%E%[37m Choice [1-2] (Default 1): %E%[0m"
if "!URL_MODE!"=="" set "URL_MODE=1"

if "!URL_MODE!"=="1" (
    set "CUSTOM_URLS="
    goto ask_resends
)

:select_urls
cls
echo.
echo   %E%[36m==================================================%E%[0m
echo   %E%[92m  SCRAPER KING%E%[37m -- Select Target URLs%E%[0m
echo   %E%[36m==================================================%E%[0m
echo.
echo   %E%[37m   1: www.facebook.com          (Desktop)%E%[0m
echo   %E%[37m   2: m.facebook.com            (Mobile)%E%[0m
echo   %E%[37m   3: mbasic.facebook.com       (Basic Mobile)%E%[0m
echo   %E%[37m   4: touch.facebook.com        (Touch Mobile)%E%[0m
echo   %E%[37m   5: free.facebook.com         (Free/Lite)%E%[0m
echo   %E%[37m   6: es-es.facebook.com        (Spanish Desktop)%E%[0m
echo   %E%[37m   7: fr-fr.facebook.com        (French Desktop)%E%[0m
echo   %E%[37m   8: de-de.facebook.com        (German Desktop)%E%[0m
echo   %E%[37m   9: pt-br.facebook.com        (Portuguese Desktop)%E%[0m
echo   %E%[37m  10: it-it.facebook.com        (Italian Desktop)%E%[0m
echo   %E%[37m  11: ar-ar.facebook.com        (Arabic Desktop)%E%[0m
echo   %E%[37m  12: hi-in.facebook.com        (Hindi Desktop)%E%[0m
echo   %E%[37m  13: id-id.facebook.com        (Indonesian Desktop)%E%[0m
echo   %E%[37m  14: ru-ru.facebook.com        (Russian Desktop)%E%[0m
echo.
echo   %E%[37m  Example: "1,2,3" or "1-5" or "2"%E%[0m
echo.
set "URL_SELECTION="
set /p "URL_SELECTION=  %E%[32m>%E%[37m Selection (Default: 1,2,3): %E%[0m"
if "!URL_SELECTION!"=="" set "URL_SELECTION=1,2,3"

set "CUSTOM_URLS="
set "_tempUrl_=!URL_SELECTION:,= !"

for %%a in (!_tempUrl_!) do (
    set "token=%%a"
    echo "!token!" | find "-" >nul
    if !errorlevel! equ 0 (
        for /f "tokens=1,2 delims=-" %%s in ("%%a") do (
            set "ustart=%%s"
            set "uend=%%t"
        )
        if "!ustart!"=="" set "ustart=!uend!"
        if "!uend!"=="" set "uend=!ustart!"
        for /l %%i in (!ustart!,1,!uend!) do (
            call :AddUrl %%i
        )
    ) else (
        call :AddUrl %%a
    )
)

if "!CUSTOM_URLS!" neq "" set "CUSTOM_URLS=!CUSTOM_URLS:~0,-1!"
goto ask_resends

:AddUrl
set "unum=%~1"
if "!unum!"=="1" set "CUSTOM_URLS=!CUSTOM_URLS!https://www.facebook.com,"
if "!unum!"=="2" set "CUSTOM_URLS=!CUSTOM_URLS!https://m.facebook.com,"
if "!unum!"=="3" set "CUSTOM_URLS=!CUSTOM_URLS!https://mbasic.facebook.com,"
if "!unum!"=="4" set "CUSTOM_URLS=!CUSTOM_URLS!https://touch.facebook.com,"
if "!unum!"=="5" set "CUSTOM_URLS=!CUSTOM_URLS!https://free.facebook.com,"
if "!unum!"=="6" set "CUSTOM_URLS=!CUSTOM_URLS!https://es-es.facebook.com,"
if "!unum!"=="7" set "CUSTOM_URLS=!CUSTOM_URLS!https://fr-fr.facebook.com,"
if "!unum!"=="8" set "CUSTOM_URLS=!CUSTOM_URLS!https://de-de.facebook.com,"
if "!unum!"=="9" set "CUSTOM_URLS=!CUSTOM_URLS!https://pt-br.facebook.com,"
if "!unum!"=="10" set "CUSTOM_URLS=!CUSTOM_URLS!https://it-it.facebook.com,"
if "!unum!"=="11" set "CUSTOM_URLS=!CUSTOM_URLS!https://ar-ar.facebook.com,"
if "!unum!"=="12" set "CUSTOM_URLS=!CUSTOM_URLS!https://hi-in.facebook.com,"
if "!unum!"=="13" set "CUSTOM_URLS=!CUSTOM_URLS!https://id-id.facebook.com,"
if "!unum!"=="14" set "CUSTOM_URLS=!CUSTOM_URLS!https://ru-ru.facebook.com,"
goto :eof

:: ── STEP 6: OTP Resend Configuration ──────────────────────────
:ask_resends
cls
echo.
echo   %E%[36m==================================================%E%[0m
echo   %E%[92m  SCRAPER KING%E%[37m -- Step 6: OTP Resends%E%[0m
echo   %E%[36m==================================================%E%[0m
echo.
echo   %E%[37m  How many additional times should the bot click re-send?%E%[0m
echo   %E%[37m  (0 = 1 total SMS, 1 = 2 total SMS, 2 = 3 total SMS)%E%[0m
echo.
set "RESENDS="
set /p "RESENDS=  %E%[32m>%E%[37m Number of resends [0-5] (Default 0): %E%[0m"
if "!RESENDS!"=="" set "RESENDS=0"

:: ── STEP 6.5: Bandwidth Saver ─────────────────────────────────
:ask_bandwidth
cls
echo.
echo   %E%[36m==================================================%E%[0m
echo   %E%[92m  SCRAPER KING%E%[37m -- Step 6.5: Bandwidth Saver%E%[0m
echo   %E%[36m==================================================%E%[0m
echo.
echo   %E%[37m  Reduce proxy data usage by blocking images, fonts ^& media.%E%[0m
echo   %E%[37m  CSS and JavaScript are NOT blocked (required for detection).%E%[0m
echo   %E%[37m  Recommended if using a GB-based premium proxy.%E%[0m
echo.
echo   %E%[32m[1]%E%[37m Off  ^(Normal mode, load everything^)%E%[0m
echo   %E%[32m[2]%E%[37m On   ^(Block images, fonts ^& media ~30-50%% less data^)%E%[0m
echo.
set "BW_CHOICE="
set /p "BW_CHOICE=  %E%[32m>%E%[37m Choice [1-2] (Default 1): %E%[0m"
if "!BW_CHOICE!"=="" set "BW_CHOICE=1"

set "BANDWIDTH_SAVER=0"
if "!BW_CHOICE!"=="2" set "BANDWIDTH_SAVER=1"


:: ── CONFIRM ───────────────────────────────────────────────────
cls
echo.
echo   %E%[36m==================================================%E%[0m
echo   %E%[92m  SCRAPER KING%E%[37m -- READY FOR LAUNCH%E%[0m
echo   %E%[36m==================================================%E%[0m
echo.
echo   %E%[32m[+]%E%[37m Targets   : %E%[33m!NUMBERS_FILE!%E%[0m
if "!BANDWIDTH_SAVER!"=="1" (
echo   %E%[32m[+]%E%[37m Bandwidth : %E%[33mSaver ON ^(images/fonts/media blocked^)%E%[0m
) else (
echo   %E%[32m[+]%E%[37m Bandwidth : %E%[33mNormal%E%[0m
)
echo   %E%[32m[+]%E%[37m Proxy     : %E%[33m!PROXY_STATUS!%E%[0m
echo   %E%[32m[+]%E%[37m Protocol  : %E%[33m!PROXY_PROTOCOL!%E%[0m
if "!PROXY_CHOICE!"=="auto" (
echo   %E%[32m[+]%E%[37m Country   : %E%[33m!PROXY_COUNTRY!%E%[0m
)
if defined PROXY_TIMING (
echo   %E%[32m[+]%E%[37m Connect   : %E%[33m!PROXY_TIMING!%E%[0m
)
if "!WORKERS!"=="" (
echo   %E%[32m[+]%E%[37m Workers   : %E%[33mAuto-Detect ^(Max hardware limit^)%E%[0m
) else (
echo   %E%[32m[+]%E%[37m Workers   : %E%[33m!WORKERS!%E%[0m
)
if defined LANG_CODE (
echo   %E%[32m[+]%E%[37m Language  : %E%[33m!LANG_CODE!%E%[0m
) else (
echo   %E%[32m[+]%E%[37m Languages : %E%[33m!LANG_CODES!%E%[0m
)
if defined CUSTOM_URLS (
echo   %E%[32m[+]%E%[37m URLs      : %E%[33m!CUSTOM_URLS!%E%[0m
) else (
echo   %E%[32m[+]%E%[37m URLs      : %E%[33mAuto ^(All for language^)%E%[0m
)
echo.
echo   %E%[36m==================================================%E%[0m
echo.
set "CONFIRM="
set /p "CONFIRM=  %E%[32m>%E%[37m Press ENTER to start or N to cancel: %E%[0m"
if /i "!CONFIRM!"=="N" goto ask_numbers

:: ── RUN ───────────────────────────────────────────────────────
cls
echo.
echo   %E%[33m[*] Starting Engine...%E%[0m
echo.
if defined LANG_CODE (
    set "RUN_LANG=!LANG_CODE!"
) else (
    set "RUN_LANG=!LANG_CODES!"
)

set "BANDWIDTH_SAVER=!BANDWIDTH_SAVER!"
"!NODE_EXE!" "%~dp0autofill.js" "!NUMBERS_FILE!" "!PROXY_FILE!" "!WORKERS!" "!RUN_LANG!" "!PROXY_CHOICE!" "!PROXY_COUNTRY!" "!RESENDS!" "!CUSTOM_URLS!" "!PROXY_TIMING!" "!PROXY_USE_LIMIT!" "!HARDWARE_ID!" "!PROXY_PROTOCOL!"

:: ── DONE ──────────────────────────────────────────────────────
echo.
echo   %E%[36m==================================================%E%[0m
echo   %E%[92m  SCRAPER KING%E%[37m -- FINISHED%E%[0m
echo   %E%[36m==================================================%E%[0m
echo.
for %%F in ("!NUMBERS_FILE!") do set "OUT_DIR=%%~dpF"
explorer "!OUT_DIR!"
pause
