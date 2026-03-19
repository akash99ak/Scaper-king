@echo off
setlocal enabledelayedexpansion
title SCRAPER-KING - FB Recovery Engine
color 0B
mode con: cols=65 lines=40

cd /d "%~dp0"

:: ── Find Node.js ──────────────────────────────────────────
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
    color 0C
    cls
    echo.
    echo   ERROR: Node.js not found!
    echo   Install from https://nodejs.org
    echo.
    pause
    exit /b 1
)

:: ── Install packages if missing ───────────────────────────
if not exist "%~dp0node_modules\playwright-extra" (
    cls
    echo.
    echo   Setting up first-time dependencies...
    echo.
    call "!NPM_CMD!" install playwright playwright-extra puppeteer-extra-plugin-stealth
    if !errorlevel! neq 0 (
        color 0C
        echo   Install failed. Check your internet.
        pause
        exit /b 1
    )
    echo   Installing headless Chrome...
    call "!NODE_EXE!" "%~dp0node_modules\.bin\playwright" install chromium
    echo   Setup complete.
    timeout /t 2 >nul
)

:: ══════════════════════════════════════════════════════════
::  STEP 1: Numbers file
:: ══════════════════════════════════════════════════════════
:ask_numbers
cls
echo.
echo   ========================================================
echo.
echo       ____                                _  __ _
echo      / ___^|  ___ _ __ __ _ _ __   ___ _ _^| ^|/ /(_^)_ __   __ _
echo      \___ \ / __^| '__/ _` ^| '_ \ / _ \ '__^| ' / ^| ^| '_ \ / _` ^|
echo       ___^) ^| (__^| ^| ^| (_^| ^| ^|_^) ^|  __/ ^|  ^| . \ ^| ^| ^| ^| ^| (_^| ^|
echo      ^|____/ \___^|_^|  \__,_^| .__/ \___^|_^|  ^|_^|\_\^|_^|_^| ^|_^|\__, ^|
echo                            ^|_^|                           ^|___/
echo.
echo   ========================================================
echo             FB OTP Recovery Engine
echo   ========================================================
echo.
echo   STEP 1 : Target Number List
echo   --------------------------------------------------------
echo.
set "NUMBERS_FILE="
set /p "NUMBERS_FILE=   Drag your numbers.txt here: "
set "NUMBERS_FILE=!NUMBERS_FILE:"=!"

if "!NUMBERS_FILE!"=="" (
    echo   Required!
    timeout /t 1 >nul
    goto ask_numbers
)
if not exist "!NUMBERS_FILE!" (
    echo   File not found.
    timeout /t 1 >nul
    goto ask_numbers
)

echo "!NUMBERS_FILE!" | findstr /i "\.bat$" >nul
if !errorlevel! equ 0 (
    echo   ERROR: Drag a .txt file, not a .bat script!
    timeout /t 2 >nul
    goto ask_numbers
)
echo "!NUMBERS_FILE!" | findstr /i "\.js$" >nul
if !errorlevel! equ 0 (
    echo   ERROR: Drag a .txt file, not a .js file!
    timeout /t 2 >nul
    goto ask_numbers
)

:: ══════════════════════════════════════════════════════════
::  STEP 2: Proxy Configuration
:: ══════════════════════════════════════════════════════════
:ask_proxy
cls
echo.
echo   ========================================================
echo             SCRAPER-KING - FB OTP Recovery Engine
echo   ========================================================
echo.
echo   STEP 2 : Proxy Configuration
echo   --------------------------------------------------------
echo.
echo     [1]  Auto Scraping   - Recommended, High Success
echo     [2]  Custom File     - Use your own proxy list
echo     [3]  Direct          - No proxy, risky
echo.
set "PROXY_CHOICE="
set /p "PROXY_CHOICE=   Choice [1-3] - Default 1: "
if "!PROXY_CHOICE!"=="" set "PROXY_CHOICE=1"

if "!PROXY_CHOICE!"=="1" goto auto_proxy
if "!PROXY_CHOICE!"=="2" goto custom_proxy
if "!PROXY_CHOICE!"=="3" goto direct_proxy
goto ask_proxy

:auto_proxy
set "PROXY_CHOICE=auto"
set "PROXY_FILE="
set "PROXY_STATUS=Auto Scraping"
goto ask_workers

:custom_proxy
echo.
set "PROXY_FILE="
set /p "PROXY_FILE=   Proxy file path: "
set "PROXY_FILE=!PROXY_FILE:"=!"

if "!PROXY_FILE!"=="" (
    set "PROXY_CHOICE=direct"
    set "PROXY_STATUS=Direct - No file provided"
    goto ask_workers
)
if not exist "!PROXY_FILE!" (
    set "PROXY_CHOICE=direct"
    set "PROXY_STATUS=Direct - File not found"
    goto ask_workers
)

set "PROXY_CHOICE=custom"
set "PROXY_STATUS=Custom File"
goto ask_workers

:direct_proxy
set "PROXY_CHOICE=direct"
set "PROXY_FILE="
set "PROXY_STATUS=Direct Connection"
goto ask_workers

:: ══════════════════════════════════════════════════════════
::  STEP 3: Worker Configuration
:: ══════════════════════════════════════════════════════════
:ask_workers
cls
echo.
echo   ========================================================
echo             SCRAPER-KING - FB OTP Recovery Engine
echo   ========================================================
echo.
echo   STEP 3 : Worker Threads
echo   --------------------------------------------------------
echo.
echo   Leave blank to auto-detect optimal limit
echo   based on your PC hardware.
echo.
set "WORKERS="
set /p "WORKERS=   Workers - Enter to Auto-Detect: "

:: ══════════════════════════════════════════════════════════
::  STEP 4: Language Configuration
:: ══════════════════════════════════════════════════════════
:ask_language
cls
echo.
echo   ========================================================
echo             SCRAPER-KING - FB OTP Recovery Engine
echo   ========================================================
echo.
echo   STEP 4 : Language Selection
echo   --------------------------------------------------------
echo.
echo     [1]  Single Language
echo     [2]  Multi-Language Rotation  - Higher Success
echo     [3]  Random Per Account       - Best Anti-Detection
echo.
set "LANG_MODE="
set /p "LANG_MODE=   Choice [1-3] - Default 1: "
if "!LANG_MODE!"=="" set "LANG_MODE=1"

if "!LANG_MODE!"=="2" goto multi_language
if "!LANG_MODE!"=="3" goto random_language

:single_language
cls
echo.
echo   ========================================================
echo             SCRAPER-KING - FB OTP Recovery Engine
echo   ========================================================
echo.
echo   STEP 4 : Choose Language
echo   --------------------------------------------------------
echo.
echo    1: EN   2: ES   3: FR   4: DE   5: PT   6: IT   7: AR
echo    8: HI   9: BN  10: ID  11: RU  12: TR  13: JA  14: KO
echo   15: TH  16: VI  17: PL  18: NL  19: ZH  20: MS
echo.
set "FB_LANG="
set /p "FB_LANG=   Language 1-20 - Default EN: "
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
if "!FB_LANG!"=="13" set "LANG_CODE=ja"
if "!FB_LANG!"=="14" set "LANG_CODE=ko"
if "!FB_LANG!"=="15" set "LANG_CODE=th"
if "!FB_LANG!"=="16" set "LANG_CODE=vi"
if "!FB_LANG!"=="17" set "LANG_CODE=pl"
if "!FB_LANG!"=="18" set "LANG_CODE=nl"
if "!FB_LANG!"=="19" set "LANG_CODE=zh"
if "!FB_LANG!"=="20" set "LANG_CODE=ms"
goto language_done

:random_language
set "LANG_CODE=random"
goto language_done

:multi_language
cls
echo.
echo   ========================================================
echo             SCRAPER-KING - FB OTP Recovery Engine
echo   ========================================================
echo.
echo   STEP 4 : Multi-Language Rotation
echo   --------------------------------------------------------
echo.
echo    1: EN   2: ES   3: FR   4: DE   5: PT   6: IT   7: AR
echo    8: HI   9: BN  10: ID  11: RU  12: TR  13: JA  14: KO
echo   15: TH  16: VI  17: PL  18: NL  19: ZH  20: MS
echo.
echo   Examples: "1-3" or "1,2,5" or "1-20"
echo.
set "MULTI_LANG="
set /p "MULTI_LANG=   Selection - Default 1-3: "
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
if !num! geq 1 if !num! leq 20 (
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
    if "!num!"=="12" set "LANG_CODES=!LANG_CODES!tr,"
    if "!num!"=="13" set "LANG_CODES=!LANG_CODES!ja,"
    if "!num!"=="14" set "LANG_CODES=!LANG_CODES!ko,"
    if "!num!"=="15" set "LANG_CODES=!LANG_CODES!th,"
    if "!num!"=="16" set "LANG_CODES=!LANG_CODES!vi,"
    if "!num!"=="17" set "LANG_CODES=!LANG_CODES!pl,"
    if "!num!"=="18" set "LANG_CODES=!LANG_CODES!nl,"
    if "!num!"=="19" set "LANG_CODES=!LANG_CODES!zh,"
    if "!num!"=="20" set "LANG_CODES=!LANG_CODES!ms,"
)
goto :eof

:language_done

:: ══════════════════════════════════════════════════════════
::  CONFIRMATION SCREEN
:: ══════════════════════════════════════════════════════════
cls
echo.
echo   ========================================================
echo.
echo       ____                                _  __ _
echo      / ___^|  ___ _ __ __ _ _ __   ___ _ _^| ^|/ /(_^)_ __   __ _
echo      \___ \ / __^| '__/ _` ^| '_ \ / _ \ '__^| ' / ^| ^| '_ \ / _` ^|
echo       ___^) ^| (__^| ^| ^| (_^| ^| ^|_^) ^|  __/ ^|  ^| . \ ^| ^| ^| ^| ^| (_^| ^|
echo      ^|____/ \___^|_^|  \__,_^| .__/ \___^|_^|  ^|_^|\_\^|_^|_^| ^|_^|\__, ^|
echo                            ^|_^|                           ^|___/
echo.
echo   ========================================================
echo                   READY TO LAUNCH
echo   ========================================================
echo.
echo   Targets   : !NUMBERS_FILE!
echo   Proxy     : !PROXY_STATUS!
if "!WORKERS!"=="" (
echo   Workers   : Auto-Detect
) else (
echo   Workers   : !WORKERS!
)
if defined LANG_CODE (
echo   Language  : !LANG_CODE!
) else (
echo   Languages : !LANG_CODES!
)
echo.
echo   ========================================================
echo.
set "CONFIRM="
set /p "CONFIRM=   Press ENTER to start or N to cancel: "
if /i "!CONFIRM!"=="N" goto ask_numbers

:: ══════════════════════════════════════════════════════════
::  RUN
:: ══════════════════════════════════════════════════════════
cls
echo.
echo   Starting SCRAPER-KING Engine...
echo.
if defined LANG_CODE (
    call "!NODE_EXE!" "%~dp0autofill.js" "!NUMBERS_FILE!" "!PROXY_FILE!" "!WORKERS!" "!LANG_CODE!" "!PROXY_CHOICE!"
) else (
    call "!NODE_EXE!" "%~dp0autofill.js" "!NUMBERS_FILE!" "!PROXY_FILE!" "!WORKERS!" "!LANG_CODES!" "!PROXY_CHOICE!"
)

:: ══════════════════════════════════════════════════════════
::  DONE
:: ══════════════════════════════════════════════════════════
echo.
echo   ========================================================
echo              SESSION COMPLETE
echo   ========================================================
echo.
echo   Results saved. Opening output folder...
echo.
for %%F in ("!NUMBERS_FILE!") do set "OUT_DIR=%%~dpF"
explorer "!OUT_DIR!"
pause
