@echo off
title ScraperKing V3 - Developer Protector
cd /d "%~dp0"
echo [*] Securing V3 Developer Files...
node protect.js
echo.
echo [*] Compilation complete. The root folder now contains the protected release.
pause
