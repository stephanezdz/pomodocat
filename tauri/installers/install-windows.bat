@echo off
REM install-windows.bat — installeur PomodoCat (point d'entree).
REM
REM Telecharge la derniere version de install-windows.ps1 depuis GitHub
REM Releases puis l'execute. Aucun fichier compagnon necessaire.
REM
REM Double-clic dans l'Explorateur. Pre-requis : Windows 10/11.

setlocal
set "TMPDIR=%TEMP%\pomodocat-install"
set "PS1_URL=https://github.com/stephanezdz/pomodocat/releases/latest/download/install-windows.ps1"
set "PS1_PATH=%TMPDIR%\install-windows.ps1"

echo.
echo ==========================================
echo   Installation de PomodoCat
echo ==========================================
echo.

if not exist "%TMPDIR%" mkdir "%TMPDIR%"

echo Telechargement du script d'installation...
powershell -ExecutionPolicy Bypass -NoProfile -Command ^
  "try { Invoke-WebRequest -Uri '%PS1_URL%' -OutFile '%PS1_PATH%' -UseBasicParsing } catch { Write-Host '[X] Echec du telechargement :' $_.Exception.Message -ForegroundColor Red; exit 1 }"

if not exist "%PS1_PATH%" (
  echo.
  echo [X] Le script d'installation n'a pas pu etre telecharge.
  echo     Verifie ta connexion internet et reessaie.
  echo.
  pause
  exit /b 1
)

echo.
powershell -ExecutionPolicy Bypass -NoProfile -File "%PS1_PATH%"
set "EXITCODE=%ERRORLEVEL%"

REM Cleanup.
del /q "%PS1_PATH%" 2>nul
rmdir "%TMPDIR%" 2>nul

echo.
if %EXITCODE% NEQ 0 (
  echo [X] L'installation a echoue ^(code %EXITCODE%^).
) else (
  echo [V] Installation terminee.
)

pause
exit /b %EXITCODE%
