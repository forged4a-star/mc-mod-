@echo off
setlocal

powershell -ExecutionPolicy Bypass -File "%~dp0install_to_curseforge.ps1" %*
if errorlevel 1 (
  echo.
  echo Install failed.
  exit /b 1
)

echo.
echo Install complete.
endlocal
