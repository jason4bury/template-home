# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), with versions numbered
`<major>.<minor>` and a two-digit minor (v1.00, v1.01 ... v1.10).

## [Unreleased]

## [1.03] - 2026-11-21

### Changed
- **Works for anyone.** New tools go in the folder that holds `_templates` (or `-HomeRoot`), not a
  fixed drive and folder.
- **Your own names.** The GitHub user name comes from your copy of this template's repo (or git's
  `github.user`, or it asks), and the author's name for the LICENSE, README and script headers from
  git's `user.name` (or it asks). New `-Author` and a `{{AUTHOR}}` placeholder in the starter.

## [1.02] - 2026-11-16

### Added
- `starter\Build.cmd`: optional `VersionFile` in `build.json`, for a tool that keeps its version
  in a file of its own. Build.cmd then reads `$script:<Name>Version` (e.g. `$script:ToolkitVersion`)
  from that file. Same as the other Home tools. Tools without
  `VersionFile` build exactly as before.

### Fixed
- `starter\src\New-AppShortcut.ps1`: the default script path is worked out in the body, because
  PowerShell 5.1 leaves `$PSScriptRoot` empty in `param()` defaults under `-File`.
- `starter\Build.cmd` runs the shortcut maker with `powershell.exe -File`, the way the release's
  .cmd does, so a build fails if that .cmd would.

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
