::[Bat To Exe Converter]
::
::YAwzoRdxOk+EWAjk
::fBw5plQjdCuDJG6rxmkMGBhrbwiNMm6GNpYj6+T04e/HlHEtV90cdIDV3/S4cbcvy3Dweqkr32JfnPcKDQ1RfR2lIAY3pg4=
::YAwzuBVtJxjWCl3EqQJgSA==
::ZR4luwNxJguZRRnk
::Yhs/ulQjdF+5
::cxAkpRVqdFKZSDk=
::cBs/ulQjdF+5
::ZR41oxFsdFKZSDk=
::eBoioBt6dFKZSDk=
::cRo6pxp7LAbNWATEpCI=
::egkzugNsPRvcWATEpCI=
::dAsiuh18IRvcCxnZtBJQ
::cRYluBh/LU+EWAnk
::YxY4rhs+aU+JeA==
::cxY6rQJ7JhzQF1fEqQJQ
::ZQ05rAF9IBncCkqN+0xwdVs0
::ZQ05rAF9IAHYFVzEqQJQ
::eg0/rx1wNQPfEVWB+kM9LVsJDGQ=
::fBEirQZwNQPfEVWB+kM9LVsJDGQ=
::cRolqwZ3JBvQF1fEqQJQ
::dhA7uBVwLU+EWDk=
::YQ03rBFzNR3SWATElA==
::dhAmsQZ3MwfNWATElA==
::ZQ0/vhVqMQ3MEVWAtB9wSA==
::Zg8zqx1/OA3MEVWAtB9wSA==
::dhA7pRFwIByZRRnk
::Zh4grVQjdCuDJG6rxmkMGBhrbwiNMm6GNpYj6+T04e/HlHEtV90cdIDV3/S4cbcvy3Dweqkr32JfnPc/DwlZbhe5USQ9p2kMs3yAVw==
::YB416Ek+ZW8=
::
::
::978f952a14a936cc963da21a135fa983
::[Bat To Exe Converter]
::
::YAwzoRdxOk+EWAjk
::fBw5plQjdCuDJG6rxmkMGBhrbwiNMm6GNpYj6+T04e/HlHEtV90cdIDV3/S4cbcvy3Dweqkr32JfnPcKDQ1RfR2lIAY3pg4=
::YAwzuBVtJxjWCl3EqQJgSA==
::ZR4luwNxJguZRRnk
::Yhs/ulQjdF+5
::cxAkpRVqdFKZSDk=
::cBs/ulQjdF+5
::ZR41oxFsdFKZSDk=
::eBoioBt6dFKZSDk=
::cRo6pxp7LAbNWATEpCI=
::egkzugNsPRvcWATEpCI=
::dAsiuh18IRvcCxnZtBJQ
::cRYluBh/LU+EWAnk
::YxY4rhs+aU+JeA==
::cxY6rQJ7JhzQF1fEqQJQ
::ZQ05rAF9IBncCkqN+0xwdVs0
::ZQ05rAF9IAHYFVzEqQJQ
::eg0/rx1wNQPfEVWB+kM9LVsJDGQ=
::fBEirQZwNQPfEVWB+kM9LVsJDGQ=
::cRolqwZ3JBvQF1fEqQJQ
::dhA7uBVwLU+EWDk=
::YQ03rBFzNR3SWATElA==
::dhAmsQZ3MwfNWATElA==
::ZQ0/vhVqMQ3MEVWAtB9wSA==
::Zg8zqx1/OA3MEVWAtB9wSA==
::dhA7pRFwIByZRRnk
::Zh4grVQjdCuDJG6rxmkMGBhrbwiNMm6GNpYj6+T04e/HlHEtV90cdIDV3/S4cbcvy3Dweqkr32JfnPc/DwlZbhe5USQ9p2kMs3yAVw==
::YB416Ek+ZW8=
::
::
::978f952a14a936cc963da21a135fa983
@echo off
setlocal enabledelayedexpansion
title ScraperKing Launcher
chcp 437 >nul 2>nul

:: Generate real ESC character for ANSI colors
for /f %%a in ('echo prompt $E ^| cmd') do set "E=%%a"

:: Go directly to main (compatible with EXE wrappers)
goto :main

:main
set "INSTALL_DIR=%APPDATA%\ScraperKing"
set "KEY_FILE=%APPDATA%\ScraperKing\license.key"
set "VERSION=1.0"
set "PREMIUM_STATUS=TRIAL"

:: Create install dir if needed
if not exist "!INSTALL_DIR!" mkdir "!INSTALL_DIR!"

:: Read dynamic version from downloaded repo if it exists
if exist "!INSTALL_DIR!\version.json" (
    for /f "usebackq tokens=*" %%V in (`powershell -NoProfile -Command "(Get-Content '!INSTALL_DIR!\version.json' -ErrorAction SilentlyContinue | ConvertFrom-Json).version"`) do (
        set "VERSION=%%V"
    )
)

:: ── GENERATE HARDWARE ID (EXE-wrapper safe) ──────────────────
:: Uses PowerShell to read Machine GUID and format it, writes to temp file
set "HWID_TMP=%TEMP%\sk_hwid_%RANDOM%.tmp"
powershell -NoProfile -Command "$g = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Cryptography' -Name MachineGuid -ErrorAction SilentlyContinue).MachineGuid; if (-not $g) { $g = (Get-CimInstance Win32_ComputerSystemProduct).UUID }; if ($g) { $clean = $g -replace '-',''; $id = 'SKING-' + $clean.Substring(0,8) + '-' + $clean.Substring(8,4) + '-' + $clean.Substring(12,4); $id.ToUpper() } else { '' }" > "!HWID_TMP!"
set /p HARDWARE_ID=<"!HWID_TMP!"
del /f /q "!HWID_TMP!" 2>nul

if "%HARDWARE_ID%"=="" (
    echo   %E%[31m[-] Could not detect Hardware ID. Contact support.%E%[0m
    pause
    exit /b 1
)

:: ── SHOW SPLASH SCREEN ──────────────────────────────────
:show_splash
cls
echo.
echo   %E%[92m  ___  ___ ___    _   ___ ___ ___   _  _____ _  _  ___ %E%[0m
echo   %E%[92m / __^|/ __^| _ \  /_\ ^| _ \ __^| _ \ ^| ^|/ /_ _^| \^| ^|/ __^|%E%[0m
echo   %E%[92m \__ \ (__^|   / / _ \^|  _/ _^|^|   / ^| ' ^< ^| ^|^| .` ^| (__ %E%[0m
echo   %E%[92m ^|___/\___^|_^|_\/_/ \_\_^| ^|___^|_^|_\ ^|_^|\_\___^|_^|\_^|\___^|%E%[0m
echo.
echo   %E%[32m[+]%E%[37m DEVELOPER  : %E%[33mScraper-King%E%[0m
echo   %E%[32m[+]%E%[37m CONTACT    : %E%[33mhttps://t.me/scraper_king%E%[0m
echo   %E%[32m[+]%E%[37m VERSION    : %E%[33m%VERSION%%E%[0m
echo   %E%[32m[+]%E%[37m PREMIUM    : %E%[33m%PREMIUM_STATUS%%E%[0m
echo   %E%[36m=========================================================%E%[0m
echo.
echo   %E%[33m[-] Auto Logging : Under Development%E%[0m
echo.
echo   %E%[36m--------------------------------------------------%E%[0m
echo   %E%[32m  YOUR HARDWARE ID:%E%[0m
echo   %E%[33m  %HARDWARE_ID%%E%[0m
echo   %E%[36m--------------------------------------------------%E%[0m
echo.
echo   %E%[33m[*] Validating license with server...%E%[0m
echo.

:: â”€â”€ VALIDATE AGAINST GIST (OBFUSCATED URL) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
:: Write PowerShell validation script to temp file to avoid CMD escaping issues
set "PS_SCRIPT=%TEMP%\sk_validate.ps1"
>"!PS_SCRIPT!" echo.$ErrorActionPreference='SilentlyContinue'
>>"!PS_SCRIPT!" echo.[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
>>"!PS_SCRIPT!" echo.$p1 = [char[]]@(104,116,116,112,115,58,47,47,103,105,115,116,46,103,105,116,104,117,98,117,115,101,114,99,111,110,116,101,110,116,46,99,111,109,47) -join ''
>>"!PS_SCRIPT!" echo.$p2 = [char[]]@(97,107,97,115,104,57,57,97,107,47) -join ''
>>"!PS_SCRIPT!" echo.$p3 = [char[]]@(56,102,50,56,55,54,57,97,100,98,57,54,53,50,52,50,52,102,49,99,98,55,48,51,99,101,97,49,55,99,53,56,47,114,97,119,47,107,101,121,115,46,106,115,111,110) -join ''
>>"!PS_SCRIPT!" echo.$url = $p1 + $p2 + $p3 + '?t=' + [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
>>"!PS_SCRIPT!" echo.try {
>>"!PS_SCRIPT!" echo.    $raw = curl.exe -4 --connect-timeout 3 -m 5 -s -f "$url" 2^>$null
>>"!PS_SCRIPT!" echo.    if (-not $raw) {
>>"!PS_SCRIPT!" echo.        $wc = New-Object System.Net.WebClient
>>"!PS_SCRIPT!" echo.        $raw = $wc.DownloadString($url)
>>"!PS_SCRIPT!" echo.    }
>>"!PS_SCRIPT!" echo.    if (-not $raw) { throw 'Fetch failed' }
>>"!PS_SCRIPT!" echo.    $json = $raw ^| ConvertFrom-Json
>>"!PS_SCRIPT!" echo.    $hwid = '!HARDWARE_ID!'
>>"!PS_SCRIPT!" echo.    $entry = $json.keys.PSObject.Properties ^| Where-Object { $_.Name -eq $hwid }
>>"!PS_SCRIPT!" echo.    if ($entry) {
>>"!PS_SCRIPT!" echo.        $u = $entry.Value.user
>>"!PS_SCRIPT!" echo.        $e = $entry.Value.expires
>>"!PS_SCRIPT!" echo.        $today = Get-Date -Format 'yyyy-MM-dd'
>>"!PS_SCRIPT!" echo.        if ($e -ge $today) {
>>"!PS_SCRIPT!" echo.            Write-Host ('1' + [char]124 + $u + [char]124 + $e)
>>"!PS_SCRIPT!" echo.        } else {
>>"!PS_SCRIPT!" echo.            Write-Host ('2' + [char]124 + $u + [char]124 + $e)
>>"!PS_SCRIPT!" echo.        }
>>"!PS_SCRIPT!" echo.    } else {
>>"!PS_SCRIPT!" echo.        Write-Host ('0' + [char]124 + 'NotFound' + [char]124)
>>"!PS_SCRIPT!" echo.    }
>>"!PS_SCRIPT!" echo.} catch {
>>"!PS_SCRIPT!" echo.    Write-Host ('3' + [char]124 + 'Error' + [char]124)
>>"!PS_SCRIPT!" echo.}

set "KEY_VALID=0"
set "KEY_USER=Unknown"
set "KEY_EXPIRES="
set "VALIDATION_CODE=0"

for /f "tokens=1,2,3 delims=|" %%A in ('powershell -NoProfile -ExecutionPolicy Bypass -File "!PS_SCRIPT!"') do (
    set "VALIDATION_CODE=%%A"
    set "KEY_USER=%%B"
    set "KEY_EXPIRES=%%C"
)

:: Clean up temp script
del /f /q "!PS_SCRIPT!" >nul 2>nul

:: Handle validation result
if "!VALIDATION_CODE!"=="1" (
    set "KEY_VALID=1"
    echo   %E%[32m[+] License APPROVED!%E%[0m
    echo   %E%[32m[+] User    : %E%[33m!KEY_USER!%E%[0m
    echo   %E%[32m[+] Expires : %E%[33m!KEY_EXPIRES!%E%[0m
    echo.
    timeout /t 2 >nul
    goto :setup_and_launch
)

if "!VALIDATION_CODE!"=="2" (
    echo   %E%[31m[-] License EXPIRED!%E%[0m
    echo   %E%[31m    User    : !KEY_USER!%E%[0m
    echo   %E%[31m    Expired : !KEY_EXPIRES!%E%[0m
    echo.
    echo   %E%[33m    Contact https://t.me/scraper_king to renew.%E%[0m
    echo.
    echo   %E%[36m  Your Hardware ID: %E%[33m!HARDWARE_ID!%E%[0m
    echo.
    pause
    exit /b 1
)

if "!VALIDATION_CODE!"=="3" (
    echo   %E%[31m[-] Could not reach license server!%E%[0m
    echo   %E%[31m    Check your internet connection and try again.%E%[0m
    echo.
    pause
    exit /b 1
)

:: VALIDATION_CODE is 0 or anything else = Not Approved
echo   %E%[31m[!] License NOT APPROVED%E%[0m
echo.
echo   %E%[33m  Your Hardware ID is:%E%[0m
echo   %E%[36m  %HARDWARE_ID%%E%[0m
echo.
echo   %E%[33m  Send this ID to the developer for activation:%E%[0m
echo   %E%[32m  https://t.me/scraper_king%E%[0m
echo.
pause
exit /b 1

:: â”€â”€ SETUP & LAUNCH â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
:setup_and_launch
cls
echo.
echo   %E%[92m  ___  ___ ___    _   ___ ___ ___   _  _____ _  _  ___ %E%[0m
echo   %E%[92m / __^|/ __^| _ \  /_\ ^| _ \ __^| _ \ ^| ^|/ /_ _^| \^| ^|/ __^|%E%[0m
echo   %E%[92m \__ \ (__^|   / / _ \^|  _/ _^|^|   / ^| ' ^< ^| ^|^| .` ^| (__ %E%[0m
echo   %E%[92m ^|___/\___^|_^|_\/_/ \_\_^| ^|___^|_^|_\ ^|_^|\_\___^|_^|\_^|\___^|%E%[0m
echo.
echo   %E%[36m=========================================================%E%[0m
echo   %E%[32m  SCRAPER KING - SYSTEM SETUP%E%[0m
echo   %E%[36m=========================================================%E%[0m
echo.

:: â”€â”€ Build REPO_URL at runtime (obfuscated) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
set "REPO_SCRIPT=%TEMP%\sk_repo.ps1"
>"!REPO_SCRIPT!" echo.$r = [char[]]@(104,116,116,112,115,58,47,47,103,105,116,104,117,98,46,99,111,109,47,97,107,97,115,104,57,57,97,107,47,83,99,97,112,101,114,45,107,105,110,103,46,103,105,116) -join ''
>>"!REPO_SCRIPT!" echo.Write-Host $r
for /f "delims=" %%R in ('powershell -NoProfile -ExecutionPolicy Bypass -File "!REPO_SCRIPT!"') do set "REPO_URL=%%R"
del /f /q "!REPO_SCRIPT!" >nul 2>nul

:: â”€â”€ STEP 1: Node.js â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
echo   %E%[32m[1/4]%E%[37m Checking Node.js...%E%[0m
node --version >nul 2>nul
if !errorlevel! equ 0 (
    for /f %%V in ('node --version') do echo   %E%[32m[OK]%E%[37m Node.js %%V%E%[0m
    goto :check_git
)

echo   %E%[33m[*]%E%[37m Node.js not found. Downloading v20 LTS (Please wait for progress)...%E%[0m
powershell -NoProfile -Command "$ErrorActionPreference='Stop'; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; try { Start-BitsTransfer -Source 'https://nodejs.org/dist/v20.11.1/node-v20.11.1-x64.msi' -Destination '%TEMP%\node_setup.msi' -Description 'Downloading Node.js' } catch { Invoke-WebRequest -Uri 'https://nodejs.org/dist/v20.11.1/node-v20.11.1-x64.msi' -OutFile '%TEMP%\node_setup.msi' -UseBasicParsing }"
if not exist "%TEMP%\node_setup.msi" (
    echo   %E%[31m[-] Could not download Node.js. Check your internet.%E%[0m
    goto :fail
)
echo   %E%[33m[*]%E%[37m Installing Node.js (please wait)...%E%[0m
start /wait msiexec /i "%TEMP%\node_setup.msi" /qn /norestart ADDLOCAL=ALL
del /f /q "%TEMP%\node_setup.msi" >nul 2>nul

:: Refresh PATH from registry
call :refresh_path
node --version >nul 2>nul
if !errorlevel! neq 0 (
    echo   %E%[31m[-] Node.js installation failed.%E%[0m
    goto :fail
)
for /f %%V in ('node --version') do echo   %E%[32m[OK]%E%[37m Node.js %%V installed.%E%[0m

:: â”€â”€ STEP 2: Git â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
:check_git
echo.
echo   %E%[32m[2/4]%E%[37m Checking Git...%E%[0m
git --version >nul 2>nul
if !errorlevel! equ 0 (
    for /f "tokens=1-3" %%A in ('git --version') do echo   %E%[32m[OK]%E%[37m %%A %%B %%C%E%[0m
    goto :check_repo
)

echo   %E%[33m[*]%E%[37m Git not found. Installing...%E%[0m

:: Method 1: Try winget (most reliable on Windows 10/11)
winget --version >nul 2>nul
if !errorlevel! equ 0 (
    echo   %E%[33m[*]%E%[37m Using winget to install Git...%E%[0m
    winget install --id Git.Git -e --source winget --accept-package-agreements --accept-source-agreements
    call :refresh_path
    git --version >nul 2>nul
    if !errorlevel! equ 0 (
        for /f "tokens=1-3" %%A in ('git --version') do echo   %E%[32m[OK]%E%[37m %%A %%B %%C installed via winget.%E%[0m
        goto :check_repo
    )
    echo   %E%[33m[*]%E%[37m winget install did not succeed, trying direct download...%E%[0m
)

:: Method 2: Direct download with Invoke-WebRequest (handles GitHub redirects)
echo   %E%[33m[*]%E%[37m Downloading Git installer (Please wait for progress)...%E%[0m
set "GIT_DL_SCRIPT=%TEMP%\sk_gitdl.ps1"
>"!GIT_DL_SCRIPT!" echo.$ErrorActionPreference='Stop'
>>"!GIT_DL_SCRIPT!" echo.[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
>>"!GIT_DL_SCRIPT!" echo.$url = 'https://github.com/git-for-windows/git/releases/download/v2.47.1.windows.1/Git-2.47.1-64-bit.exe'
>>"!GIT_DL_SCRIPT!" echo.try { Start-BitsTransfer -Source $url -Destination "$env:TEMP\git_setup.exe" -Description 'Downloading Git' } catch { Invoke-WebRequest -Uri $url -OutFile "$env:TEMP\git_setup.exe" -UseBasicParsing }

:: Run the script visibly so the user sees the progress bar
powershell -NoProfile -ExecutionPolicy Bypass -File "!GIT_DL_SCRIPT!"
del /f /q "!GIT_DL_SCRIPT!" >nul 2>nul

if not exist "%TEMP%\git_setup.exe" (
        echo   %E%[31m[-] Could not download Git.%E%[0m
        echo   %E%[33m    Install manually: https://git-scm.com/download/win%E%[0m
        echo   %E%[33m    Or run: winget install Git.Git%E%[0m
        goto :fail
    )
echo   %E%[33m[*]%E%[37m Installing Git (please wait)...%E%[0m
start /wait "" "%TEMP%\git_setup.exe" /VERYSILENT /NORESTART /NOCANCEL /SP-
del /f /q "%TEMP%\git_setup.exe" >nul 2>nul

:: Refresh PATH from registry
call :refresh_path
git --version >nul 2>nul
if !errorlevel! neq 0 (
    echo   %E%[31m[-] Git installation failed.%E%[0m
    echo   %E%[33m    Install manually: https://git-scm.com/download/win%E%[0m
    echo   %E%[33m    Or run: winget install Git.Git%E%[0m
    goto :fail
)
for /f "tokens=1-3" %%A in ('git --version') do echo   %E%[32m[OK]%E%[37m %%A %%B %%C installed.%E%[0m

:: â”€â”€ STEP 3: Clone or Pull â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
:check_repo
echo.
echo   %E%[32m[3/4]%E%[37m Syncing from GitHub...%E%[0m
if not exist "!INSTALL_DIR!\.git" (
    echo   %E%[33m[*]%E%[37m First run - cloning repository...%E%[0m
    git clone "!REPO_URL!" "!INSTALL_DIR!"
    if !errorlevel! neq 0 (
        echo   %E%[31m[-] git clone failed.%E%[0m
        goto :fail
    )
    echo   %E%[32m[OK]%E%[37m Cloned successfully!%E%[0m
) else (
    echo   %E%[33m[*]%E%[37m Updating to latest version...%E%[0m
    cd /d "!INSTALL_DIR!"
    git pull
    if !errorlevel! neq 0 (
        echo   %E%[31m[-] Update conflict detected. Healing repository...%E%[0m
        cd /d "%TEMP%"
        rd /s /q "!INSTALL_DIR!"
        git clone "!REPO_URL!" "!INSTALL_DIR!"
        if !errorlevel! neq 0 (
            echo   %E%[31m[-] Auto-heal failed. Check your internet.%E%[0m
            goto :fail
        )
        echo   %E%[32m[OK]%E%[37m Repository repaired & updated!%E%[0m
    ) else (
        echo   %E%[32m[OK]%E%[37m Up to date!%E%[0m
    )
)

:: ── Packages are checked per-engine now ─────────────────────────

:: ── LAUNCH MENU ──
:launch_menu
cls
echo.
echo   %E%[92m  ___  ___ ___    _   ___ ___ ___   _  _____ _  _  ___ %E%[0m
echo   %E%[92m / __^|/ __^| _ \  /_\ ^| _ \ __^| _ \ ^| ^|/ /_ _^| \^| ^|/ __^|%E%[0m
echo   %E%[92m \__ \ (__^|   / / _ \^|  _/ _^|^|   / ^| ' ^< ^| ^|^| .` ^| (__ %E%[0m
echo   %E%[92m ^|___/\___^|_^|_\/_/ \_\_^| ^|___^|_^|_\ ^|_^|\_\___^|_^|\_^|\___^|%E%[0m
echo.
echo   %E%[36m=========================================================%E%[0m
echo   %E%[32m  SCRAPER KING - ENGINE SELECTION%E%[0m
echo   %E%[36m=========================================================%E%[0m
echo.
echo   %E%[33m[1]%E%[37m Web Browser Mode (Chrome / Proxies)%E%[0m
echo   %E%[33m[2]%E%[37m Emulator Mode (FB Lite V2 - MEmu/LDPlayer)%E%[0m
echo   %E%[33m[3]%E%[37m Headless Mode (Burner Phones V3 - No Emulator App)%E%[0m
echo.
set "ENGINE_CHOICE="
set /p "ENGINE_CHOICE=  %E%[32m>%E%[37m Choice [1-3] (Default 1): %E%[0m"
if "!ENGINE_CHOICE!"=="" set "ENGINE_CHOICE=1"

echo.
echo   %E%[36m==================================================%E%[0m
echo   %E%[32m  All set! Launching ScraperKing...%E%[0m
echo   %E%[36m==================================================%E%[0m
echo.
cd /d "!INSTALL_DIR!"

if "!ENGINE_CHOICE!"=="1" (
    :: --- Launch V1 ---
    if exist "!INSTALL_DIR!\v1_browser_bot\autofill.bat" (
        call "!INSTALL_DIR!\v1_browser_bot\autofill.bat" "!HARDWARE_ID!"
    ) else if exist "!INSTALL_DIR!\autofill.bat" (
        call "!INSTALL_DIR!\autofill.bat" "!HARDWARE_ID!"
    ) else (
        echo.
        echo   %E%[31m[-] Error: Web Browser engine not found!%E%[0m
        echo   %E%[33m    Make sure the v1_browser_bot folder is pushed to Github.%E%[0m
        echo.
        pause
        goto :launch_menu
    )
) else if "!ENGINE_CHOICE!"=="2" (
    :: Check both nested and flat folder structures
    if exist "!INSTALL_DIR!\v2_desktop_bot\Launcher_V2.bat" (
        call "!INSTALL_DIR!\v2_desktop_bot\Launcher_V2.bat"
    ) else if exist "!INSTALL_DIR!\Launcher_V2.bat" (
        call "!INSTALL_DIR!\Launcher_V2.bat"
    ) else (
        echo.
        echo   %E%[31m[-] Error: Emulator engine not found!%E%[0m
        echo   %E%[33m    Make sure Launcher_V2.bat is pushed to Github.%E%[0m
        echo.
        pause
        goto :launch_menu
    )
) else if "!ENGINE_CHOICE!"=="3" (
    :: V3 Headless Burner Phone Engine
    if exist "!INSTALL_DIR!\v3_headless_bot\Launcher_V3.bat" (
        call "!INSTALL_DIR!\v3_headless_bot\Launcher_V3.bat"
    ) else if exist "!INSTALL_DIR!\Launcher_V3.bat" (
        call "!INSTALL_DIR!\Launcher_V3.bat"
    ) else (
        echo.
        echo   %E%[31m[-] Error: Headless engine not found!%E%[0m
        echo   %E%[33m    Make sure the v3_headless_bot folder is pushed to Github.%E%[0m
        echo.
        pause
        goto :launch_menu
    )
) else (
    goto :launch_menu
)

:: Exit the launcher properly when the script finishes
exit /b

:fail
echo.
echo   %E%[36m==================================================%E%[0m
echo   %E%[31m  SETUP FAILED - See error above%E%[0m
echo   %E%[36m==================================================%E%[0m
echo.
pause
goto :show_splash

:: â”€â”€ SUBROUTINE: Refresh PATH from registry â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
:refresh_path
set "SYS_PATH="
set "USR_PATH="
for /f "tokens=2*" %%A in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v "Path" 2^>nul') do set "SYS_PATH=%%B"
for /f "tokens=2*" %%A in ('reg query "HKCU\Environment" /v "Path" 2^>nul') do set "USR_PATH=%%B"
set "PATH=C:\Program Files\nodejs;C:\Program Files\Git\cmd;!SYS_PATH!;!USR_PATH!"
goto :eof
