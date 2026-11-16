@echo off
rem {{APP_NAME}} - double-click to start it.
rem Each time, this makes (or refreshes) the {{APP_NAME}} shortcut in this folder and in the Start menu,
rem then starts {{APP_NAME}} from it. After the first run you can use the shortcut, the Start menu or
rem a pinned taskbar button instead: they start {{APP_NAME}} without a console window.
rem The execution-policy bypass applies to {{APP_NAME}}'s own run only; no Windows settings are changed.
rem If {{APP_NAME}} doesn't open, run   "{{APP_NAME}}.cmd" debug   to start it in this window and see any errors.
setlocal
set "PS=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
if /i "%~1"=="debug" (
    "%PS%" -NoProfile -ExecutionPolicy Bypass -STA -File "%~dp0{{APP_SLUG}}.ps1"
    pause
    exit /b
)
"%PS%" -NoProfile -ExecutionPolicy Bypass -File "%~dp0{{SHORTCUT_SCRIPT}}" -Launch
if errorlevel 1 pause
