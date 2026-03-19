@echo off
setlocal enabledelayedexpansion
title FB Recovery OTP Autofill
color 0B

cd /d "%~dp0"

echo.
echo   =========================================
echo    FB RECOVERY OTP AUTOFILL
echo   =========================================
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
    color 0C
    cls
    echo.
    echo  [ERROR] Node.js not found! Please install from https://nodejs.org
    echo.
    pause
    exit /b 1
)

:: Set stable install directory
set "SK_HOME=%APPDATA%\ScraperKing"
if not exist "!SK_HOME!" mkdir "!SK_HOME!"

:: ── CRITICAL: Clear npm prefix env vars that cause npm to load from wrong location ──
set "NPM_CONFIG_PREFIX="
set "NPM_CONFIG_GLOBALCONFIG="
set "NPM_CONFIG_USERCONFIG="
set "APPDATA_BACKUP=%APPDATA%"

:: Remove any leftover broken node_modules that confuse npm
if exist "%~dp0node_modules\npm" (
    echo  [CLEANUP] Removing old packages from app folder...
    rmdir /s /q "%~dp0node_modules" 2>nul
)

:: Install packages if missing
if not exist "!SK_HOME!\node_modules\playwright-extra" (
    cls
    echo.
    echo  [SETUP] Installing required Node packages to: !SK_HOME!
    echo.
    call "!NPM_CMD!" install playwright playwright-extra puppeteer-extra-plugin-stealth --prefix "!SK_HOME!" --no-fund --no-audit
    if !errorlevel! neq 0 (
        color 0C
        echo  [ERROR] Install failed. Check your internet connection.
        pause
        exit /b 1
    )
    echo  [SETUP] Installing headless Chrome...
    call "!NODE_EXE!" "!SK_HOME!\node_modules\playwright\cli.js" install chromium
    if !errorlevel! neq 0 (
        echo  [WARN] Trying alternate Chromium install...
        call "!NODE_EXE!" -e "require('!SK_HOME!\node_modules\playwright\index.js')" 2>nul
        call "!NPM_CMD!" exec playwright install chromium --prefix "!SK_HOME!" 2>nul
    )
    echo  [SETUP] Complete.
    timeout /t 2 >nul
)

:: Set NODE_PATH so autofill.js can require modules from SK_HOME
set "NODE_PATH=!SK_HOME!\node_modules"



:: ── STEP 1: Numbers file ──────────────────────────────────────
:ask_numbers
cls
echo.
echo   FB RECOVERY AUTOFILL
echo   -----------------------------------------
echo   Step 1: Target List
echo.
set "NUMBERS_FILE="
set /p "NUMBERS_FILE=  > Numbers file path (or drag/drop): "
set "NUMBERS_FILE=!NUMBERS_FILE:"=!"

if "!NUMBERS_FILE!"=="" (
    echo  [!] Required.
    timeout /t 1 >nul
    goto ask_numbers
)
if not exist "!NUMBERS_FILE!" (
    echo  [!] File not found. 
    timeout /t 1 >nul
    goto ask_numbers
)

:: Basic protection against passing the script as the input list
echo "!NUMBERS_FILE!" | findstr /i "\.bat$" >nul
if !errorlevel! equ 0 (
    echo  [!] ERROR: You dragged a batch script file instead of a numbers text file!
    timeout /t 2 >nul
    goto ask_numbers
)
echo "!NUMBERS_FILE!" | findstr /i "\.js$" >nul
if !errorlevel! equ 0 (
    echo  [!] ERROR: You dragged a JS file instead of a numbers text file!
    timeout /t 2 >nul
    goto ask_numbers
)

:: ── STEP 2: Proxy Configuration ────────────────────────────────
:ask_proxy
cls
echo.
echo   FB RECOVERY AUTOFILL
echo   -----------------------------------------
echo   Step 2: Proxy Method
echo.
echo   [1] Auto Scraping (Recommended, High Success)
echo   [2] Custom File 
echo   [3] Direct Connection (No Proxy)
echo.
set "PROXY_CHOICE="
set /p "PROXY_CHOICE=  > Choice [1-3] (Default 1): "
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
set /p "PROXY_FILE=  > Proxy file path: "
set "PROXY_FILE=!PROXY_FILE:"=!"

if "!PROXY_FILE!"=="" (
    set "PROXY_CHOICE=direct"
    set "PROXY_STATUS=Direct (No file provided)"
    goto ask_workers
)
if not exist "!PROXY_FILE!" (
    set "PROXY_CHOICE=direct"
    set "PROXY_STATUS=Direct (File not found)"
    goto ask_workers
)

set "PROXY_CHOICE=custom"
set "PROXY_STATUS=Custom File (!PROXY_FILE!)"
goto ask_workers

:direct_proxy
set "PROXY_CHOICE=direct"
set "PROXY_FILE="
set "PROXY_STATUS=Direct Connection"
goto ask_workers

:: ── STEP 3: Worker Configuration ────────────────────────────────
:ask_workers
cls
echo.
echo   FB RECOVERY AUTOFILL
echo   -----------------------------------------
echo   Step 3: Workers
echo.
echo   Leave blank to auto-detect optimal limit based on PC hardware.
echo.
set "WORKERS="
set /p "WORKERS=  > Number of workers (Enter to auto-detect): "

:: ── STEP 4: Language Configuration ───────────────────────────
:ask_language
cls
echo.
echo   FB RECOVERY AUTOFILL
echo   -----------------------------------------
echo   Step 4: Languages
echo.
echo   [1] Single Language Profile
echo   [2] Multi-Language Rotation
echo.
set "LANG_MODE="
set /p "LANG_MODE=  > Choice [1-2] (Default 1): "
if "!LANG_MODE!"=="" set "LANG_MODE=1"

if "!LANG_MODE!"=="2" goto multi_language

:single_language
cls
echo.
echo   FB RECOVERY AUTOFILL
echo   -----------------------------------------
echo   Select Language:
echo.
echo   1: EN   2: ES   3: FR   4: DE   5: PT   6: IT
echo   7: AR   8: HI   9: BN  10: ID  11: RU  12: TR  13: VI
echo.
set "FB_LANG="
set /p "FB_LANG=  > Language (1-13) [Default 1-EN]: "
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
goto language_done

:multi_language
cls
echo.
echo   FB RECOVERY AUTOFILL
echo   -----------------------------------------
echo   Multi-Language Selection
echo.
echo   Languages: 1:EN 2:ES 3:FR 4:DE 5:PT 6:IT 7:AR 8:HI 9:BN 10:ID 11:RU 12:TR 13:VI
echo   Example inputs: "1-3" or "1,2,5" or "1-13"
echo.
set "MULTI_LANG="
set /p "MULTI_LANG=  > Selection (Default 1-3): "
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
if !num! geq 1 if !num! leq 13 (
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
    if "!num!"=="13" set "LANG_CODES=!LANG_CODES!vi,"
)
goto :eof

:language_done

:: ── CONFIRM ───────────────────────────────────────────────────
cls
echo.
echo   READY FOR LAUNCH
echo   =========================================
echo   Targets   : !NUMBERS_FILE!
echo   Proxy     : !PROXY_STATUS!
if "!WORKERS!"=="" (
echo   Workers   : Auto-Detect (Max hardware limit)
) else (
echo   Workers   : !WORKERS!
)
if defined LANG_CODE (
echo   Language  : !LANG_CODE!
) else (
echo   Languages : !LANG_CODES!
)
echo   =========================================
echo.
set "CONFIRM="
set /p "CONFIRM=  > Press ENTER to start or N to cancel: "
if /i "!CONFIRM!"=="N" goto ask_numbers

:: ── RUN ───────────────────────────────────────────────────────
cls
echo.
echo   Starting Engine...
echo.
if defined LANG_CODE (
    call "!NODE_EXE!" "%~dp0autofill.js" "!NUMBERS_FILE!" "!PROXY_FILE!" "!WORKERS!" "!LANG_CODE!" "!PROXY_CHOICE!"
) else (
    call "!NODE_EXE!" "%~dp0autofill.js" "!NUMBERS_FILE!" "!PROXY_FILE!" "!WORKERS!" "!LANG_CODES!" "!PROXY_CHOICE!"
)

:: ── DONE ──────────────────────────────────────────────────────
echo.
echo   =========================================
echo   FINISHED
echo   =========================================
echo.
for %%F in ("!NUMBERS_FILE!") do set "OUT_DIR=%%~dpF"
explorer "!OUT_DIR!"
pause
