@echo off
REM install-windows.bat — installeur PomodoCat pour testeur sans toolchain.
REM
REM Double-clic dans l'Explorateur. Le script :
REM   1. Telecharge le .exe d'install depuis la derniere GitHub Release
REM   2. Telecharge les videos de chats (.webm)
REM   3. Lance l'installeur
REM   4. Pose les chats dans %APPDATA%\PomodoCat\cats\
REM
REM Pre-requis : Windows 10/11 + WebView2 runtime (deja installe par defaut).

setlocal enabledelayedexpansion

echo.
echo ==========================================
echo   Installation de PomodoCat
echo ==========================================
echo.

REM Lance la version PowerShell pour la logique (plus simple que batch pur).
powershell -ExecutionPolicy Bypass -NoProfile -File "%~dp0install-windows.ps1"

echo.
pause
