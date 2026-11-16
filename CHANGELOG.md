# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), with versions numbered
`<major>.<minor>` and a two-digit minor (v1.00, v1.01 ... v1.10).

## [Unreleased]

## [1.01] - 2026-11-15
No more exes: PS2EXE builds kept being flagged by antivirus (ESET "Generik" trojans) by mistake.

### Added
- `starter\Build.cmd`: makes `..\Builds\<App Name> v<x.yy>\` (the script release), its zip
  for GitHub and `..\Builds\<App Name>.lnk` for the Home Launcher, then scans them with ESET's
  command-line scanner if it's installed.
- `starter\src\New-AppShortcut.ps1` and `starter\release\App.cmd`: in every release,
  `<App Name>.cmd` makes a shortcut (beside it and in the Start menu) that starts the script with
  no console window, the tool's icon and its own taskbar ID.
- `{{APP_ID}}` and `{{SHORTCUT_SCRIPT}}` placeholders.

### Changed
- `build.json` lists the release files (`Release.Files`, `Release.Shortcut`) instead of PS2EXE
  options. The starter script sets its taskbar ID, finds `assets\` beside itself in a release,
  and keeps a private tool's data in `<project>\Data` from a release folder too.
- README Installation explains the zip, the .cmd and why there's no exe.
- `Initialize-Template.ps1` refuses an apostrophe in the description.

### Removed
- `starter\Build-Exe.cmd` and the embedded-assets region of the starter script.

## [1.00] - 2026-11-13
First release.

### Added
- `starter\`: README (house section order, emoji H2s, badge row), CHANGELOG, MIT LICENSE,
  .gitignore, .gitattributes, PSScriptAnalyzerSettings.psd1, config.example.json, build.json,
  launcher.json, Build-Exe.cmd (builds from build.json), a start launcher, issue templates and
  a starter PowerShell/WPF script with the house-style About box.
- `Initialize-Template.ps1` and `New Home Tool.cmd`: make `Home\<Name>\Source` and `Builds`
  (or `Home\Private\<Name>` with `-Private`) from the starter, or fill in a repo made with
  GitHub's **Use this template** (`-InPlace`). Draws a placeholder icon from the initials.
