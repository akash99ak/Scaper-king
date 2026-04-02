@echo off
title ScraperKing V1 - Developer Protector
cd /d "%~dp0"
echo [*] Securing V1 Developer Files...
node protect.js
echo.
echo [*] Compilation complete. The root folder now contains the protected release.
pause
