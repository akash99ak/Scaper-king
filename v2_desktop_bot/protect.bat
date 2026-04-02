@echo off
title ScraperKing V2 - Developer Protector
cd /d "%~dp0"
echo [*] Securing V2 Developer Files...
node protect.js
echo.
echo [*] Compilation complete. The root folder now contains the protected release.
pause
