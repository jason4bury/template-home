@echo off
rem Starts a new Home tool from this template: asks for its name, tagline and About-box
rem description, then makes E:\Created\Home\<Name>\Source (the repo) and Builds.
rem For a private tool (Home\Private, unlock the vault first):   "New Home Tool.cmd" -Private
rem The execution-policy bypass applies to this run only; no Windows settings are changed.
set "PSModulePath="
powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File "%~dp0Initialize-Template.ps1" %*
