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

**Exe:** download `{{APP_NAME}} v1.00.exe` from the [latest release](../../releases/latest) and run it. Nothing else to install.

**Script:** clone the repo, or download it as a zip. If you download a zip, right-click it, choose **Properties** and tick **Unblock** *before* unzipping, so Windows doesn't block the scripts. Then double-click **Start {{APP_NAME}}.cmd**.

### Build the exe

Double-click **Build-Exe.cmd** in the repo folder. It reads `build.json`, checks that `$script:AppVersion` in the script matches the newest `CHANGELOG.md` entry, runs PSScriptAnalyzer if it's installed, and compiles the exe with [PS2EXE](https://github.com/MScholtes/PS2EXE) (installed for your user account the first time). The exe is saved to the project's `Builds\` folder, outside the repo, as `{{APP_NAME}} v<version>.exe`. Older builds stay alongside.

Once the standard build script is in place, it replaces `Build-Exe.cmd`:

```powershell
E:\Created\_shared\Build-Tool.ps1 -Project "E:\Created\Home\{{APP_SLUG}}"
```

Some antivirus programs flag PS2EXE executables by mistake. If the exe disappears straight after building, restore it from quarantine and add an exclusion for the `Builds` folder.

## 🚀 Usage

1. Start {{APP_NAME}} (the exe, or **Start {{APP_NAME}}.cmd**).
2. ...

## ⚙️ Configuration

**Where settings live:** {{DATA_LOCATION}}

Secrets such as API keys and NAS paths go in `config.local.json` (gitignored). `config.example.json` shows its shape.

## 📝 Changelog

See [CHANGELOG.md](CHANGELOG.md).

## 📄 Licence

[MIT](LICENSE). Copyright (c) {{YEAR}} Jason Rhodes.

Created by Jason Rhodes, built with Claude (Anthropic).
