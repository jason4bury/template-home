<p align="center">
  <img src="assets/template-home.png" alt="template-home icon" width="128">
</p>

# template-home

The starter for every new Home tool: house-style README, changelog, licence, build and launcher files, ready to fill in.

![Version](https://img.shields.io/badge/version-v1.04-blue) ![Platform](https://img.shields.io/badge/platform-Windows-0078D6) ![PowerShell](https://img.shields.io/badge/PowerShell-5.1-5391FE) ![Licence](https://img.shields.io/badge/licence-MIT-green) ![Last commit](https://img.shields.io/github/last-commit/jason4bury/template-home)

## ✨ Features

One command turns this template into a new tool's project folder, laid out and written the way every Home repo is:

- **Folder layout**: `<Name>\Source\` (the git repo) and `<Name>\Builds\` (release folders and zips, never committed), under your Home folder or `Home\Private\`.
- **README** with the house section order, an emoji at the start of every H2 and the badge row (version, platform, language, licence, last commit). Private tools get the row without the Last-commit badge, which can't read a private repo.
- **CHANGELOG.md** in Keep a Changelog format, starting at `[1.00]` with today's date.
- **MIT LICENSE**, `Copyright (c) <year> <your name>`.
- **.gitignore and .gitattributes**: exes, shortcuts, `Builds\`, `Data\`, `config.local.json`, `.env`, logs; CRLF for `.ps1`, `.psd1` and `.cmd`. `config.example.json` shows the shape of the gitignored config.
- **No exe.** PS2EXE exes kept being flagged by antivirus as false positives, so a Home tool ships as its script. **build.json** lists the release files, and **Build.cmd** checks the scripts' syntax and the version against the CHANGELOG (read from `$script:AppVersion` in the main script, or from build.json's optional `VersionFile`), runs PSScriptAnalyzer (with the repo's `PSScriptAnalyzerSettings.psd1`), copies the release into `..\Builds\<App Name> v1.00\`, zips it for GitHub, refreshes `..\Builds\<App Name>.lnk` for the Home Launcher and scans it all with ESET's command-line scanner if it's there.
- **`<App Name>.cmd` and `New-<Name>Shortcut.ps1`** in every release: double-clicking the .cmd makes a shortcut beside it and in the Start menu that starts the tool with no console window, its own icon and its own taskbar button.
- **launcher.json** with the tool's category, so the Home Launcher files it in the right group.
- **Starter script** `src\<Name>.ps1`: version and name in one place, settings in `%APPDATA%\<App Name>` (or `<project>\Data` for private tools), assets that work from the repo and from a release folder, its own taskbar ID, a log, and the **About box** (logo, name, version, About-box description, data folder, repo link, copyright and MIT licence). The window is a placeholder: house style sets what the About box says, never how the app looks.
- **Issue templates** for bug reports and feature requests, and a placeholder icon drawn from the tool's initials.

## 📋 Requirements

- Windows 10 or 11 with Windows PowerShell 5.1.
- [Git](https://git-scm.com/) to start the repo, and the [GitHub CLI](https://cli.github.com/) (`gh`) to publish it.

## 📦 Installation

Keep it in `<Home>\_templates\template-home\`, where `<Home>` is the folder that holds your tools. The Home Launcher skips folders that start with `_`, so it never shows up as a tool.

On GitHub it's marked as a template repository, so **Use this template** starts a new repo from it.

## 🚀 Usage

### New tool on disk (the usual way)

Double-click **New Home Tool.cmd** and answer three questions, or run:

```powershell
.\Initialize-Template.ps1 -AppName "Media Hub" `
    -Tagline "Browse and play everything on your NAS." `
    -Description "PowerShell/WPF tool for browsing and playing the media on a NAS" `
    -Category "Films and TV"
```

That makes `<Home>\Media-Hub\Source\` (a new git repo, nothing committed yet) and `<Home>\Media-Hub\Builds\`. Add `-Private` for a tool under `Home\Private\` (unlock the vault first). It stops without changing anything if the project folder already exists. The template folder is never changed.

| Parameter | What it's for |
| --- | --- |
| `-AppName` | Display name with spaces. Window title, About box, `%APPDATA%` folder, shortcut and release folder (`Media Hub v1.00`). |
| `-Tagline` | The README's one line under the title. The launcher shows it too. |
| `-Description` | About-box formula: `<Language>/<UI> tool for <what it does>`. Also the shortcut's comment. No apostrophes. |
| `-Slug` | Folder, repo and script name. Defaults to the name in Title-Case-With-Hyphens (`Media-Hub`). |
| `-Category` | Launcher group, e.g. `Films and TV`, `Music`, `Windows`. Default `Tools`. |
| `-Private` | `Home\Private\`, data in `<project>\Data`, no Last-commit badge, `gh repo create --private`. |

### From GitHub (Use this template)

1. On GitHub, **Use this template → Create a new repository**, named in Title-Case-With-Hyphens.
2. Clone it into `<Home>\<Name>\Source\`.
3. In that folder: `.\Initialize-Template.ps1 -InPlace -AppName "..." -Tagline "..." -Description "..."`. It moves `starter\` into place, fills it in, makes `..\Builds\` and deletes the template-only files.

### Then

1. Write the tool in `src\<Name>.ps1`. Keep `$script:AppVersion` in step with the newest CHANGELOG entry. If the tool keeps its version in a separate file, add `"VersionFile": "src\\<file>.ps1"` to `build.json`; that file can name it `$script:<Name>Version`.
2. Replace the placeholder icon, fill in the README sections (leave out any that don't apply; never reorder them) and add a screenshot.
3. Run the pre-upload review: code, GUI and graphics, improvements.
4. Double-click **Build.cmd**.
5. Commit, then publish with the command the script prints (`gh repo create ... --source ... --push`), and set the About-box description and topics.

## ⚙️ Configuration

Everything that changes per tool is a placeholder in `starter\`:

| Placeholder | Filled with |
| --- | --- |
| `{{APP_NAME}}` | `-AppName` |
| `{{APP_SLUG}}` | `-Slug` (folder, repo and script name) |
| `{{TAGLINE}}` | `-Tagline` |
| `{{DESCRIPTION}}` | `-Description` |
| `{{CATEGORY}}` | `-Category` |
| `{{GITHUB_USER}}` | your GitHub user name (`-GitHubUser`; by default the owner of your copy of this template, else git's `github.user`) |
| `{{AUTHOR}}` | your name (`-Author`; by default git's `user.name`) |
| `{{YEAR}}`, `{{DATE}}` | today |
| `{{DATA_LOCATION}}` | where settings live, public or private |
| `{{PRIVATE}}` | `true` or `false` in the starter script |
| `{{APP_ID}}` | the taskbar ID, `<GitHub user>.<Name>` |
| `{{SHORTCUT_SCRIPT}}` | `New-<Name without hyphens>Shortcut.ps1` |

`starter\Start App.cmd`, `starter\src\App.ps1`, `starter\src\New-AppShortcut.ps1` and `starter\release\App.cmd` are renamed to `Start <App Name>.cmd`, `src\<Name>.ps1`, `src\New-<Name>Shortcut.ps1` and `release\<App Name>.cmd`.

## 📝 Changelog

See [CHANGELOG.md](CHANGELOG.md).

## 📄 Licence

[MIT](LICENSE). Copyright (c) 2026 Jason Rhodes.

Created by Jason Rhodes, built with Claude (Anthropic).
