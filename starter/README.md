<p align="center">
  <img src="assets/{{APP_SLUG}}.png" alt="{{APP_NAME}} icon" width="128">
</p>

# {{APP_NAME}}

{{TAGLINE}}

![Version](https://img.shields.io/badge/version-v1.00-blue) ![Platform](https://img.shields.io/badge/platform-Windows-0078D6) ![PowerShell](https://img.shields.io/badge/PowerShell-5.1-5391FE) ![Licence](https://img.shields.io/badge/licence-MIT-green) ![Last commit](https://img.shields.io/github/last-commit/{{GITHUB_USER}}/{{APP_SLUG}})

<!--
  House style (delete this comment once the README is filled in):
  - Sections stay in this order. Leave out any that don't apply; never reorder them.
  - Every H2 starts with its emoji, the same one in every repo.
  - One badge row, directly under the tagline: version, platform, language, licence, last commit.
    Bump the version badge with every release. PowerShell 5.1 and 7: use PowerShell-5.1%20%7C%207.
    Private repos: drop the Last-commit badge (shields.io can't read a private repo, so it shows "repo not found").
-->

## ✨ Features

{{APP_NAME}} is a PowerShell/WPF tool that ...

- **First feature**: what it does for you.
- **Second feature**: what it does for you.

## 🖼️ Screenshots

![{{APP_NAME}} main window](docs/screenshots/main-window.png)

## 📋 Requirements

- Windows 10 or 11.
- Windows PowerShell 5.1 (built into Windows) with .NET Framework 4.7.2 or later.

## 📦 Installation

1. Download `{{APP_SLUG}}-v1.00.zip` from the [latest release](../../releases/latest) and unzip it wherever you like to keep it.
2. Double-click **{{APP_NAME}}.cmd** in the unzipped folder. It makes a **{{APP_NAME}}** shortcut there and in the Start menu, and starts the tool. From then on, use the shortcut, the Start menu or a pinned taskbar button.

Nothing is installed and no Windows settings are changed. The shortcut runs the script with PowerShell's execution policy bypassed for that run only.

**From the repo:** clone it and double-click **Start {{APP_NAME}}.cmd**.

### Why no exe

Home tools used to ship as PS2EXE exes, and antivirus programs (ESET among them) kept flagging those exes as generic trojans by mistake. A plain script and a shortcut give the same one-click start without the false alarms, and you can read exactly what runs.

### Build a release

Double-click **Build.cmd** in the repo folder. It reads `build.json`, checks every script for syntax errors and that `$script:AppVersion` matches the newest `CHANGELOG.md` entry (if the version lives in a file of its own, add `"VersionFile": "src\\<file>.ps1"` to `build.json`; that file can call it `$script:<Name>Version`), runs PSScriptAnalyzer if it's installed, copies the release files into `..\Builds\{{APP_NAME}} v<version>\`, zips that folder for the GitHub release, refreshes `..\Builds\{{APP_NAME}}.lnk` (what the Home Launcher starts) and scans the result with ESET's command-line scanner if it's installed.

## 🚀 Usage

1. Start {{APP_NAME}} (the shortcut, the Start menu, or **{{APP_NAME}}.cmd**).
2. ...

## ⚙️ Configuration

**Where settings live:** {{DATA_LOCATION}}

Secrets such as API keys and NAS paths go in `config.local.json` (gitignored). `config.example.json` shows its shape.

## 📝 Changelog

See [CHANGELOG.md](CHANGELOG.md).

## 📄 Licence

[MIT](LICENSE). Copyright (c) {{YEAR}} Jason Rhodes.

Created by Jason Rhodes, built with Claude (Anthropic).
