<p align="center">
  <img src="assets/template-home.png" alt="template-home icon" width="128">
</p>

# template-home

The starter for every new Home tool: house-style README, changelog, licence, build and launcher files, ready to fill in.

![Version](https://img.shields.io/badge/version-v1.00-blue) ![Platform](https://img.shields.io/badge/platform-Windows-0078D6) ![PowerShell](https://img.shields.io/badge/PowerShell-5.1-5391FE) ![Licence](https://img.shields.io/badge/licence-MIT-green) ![Last commit](https://img.shields.io/github/last-commit/jason4bury/template-home)

## ✨ Features

One command turns this template into a new tool's project folder, laid out and written the way every Home repo is:

- **Folder layout**: `<Name>\Source\` (the git repo) and `<Name>\Builds\` (exes, never committed), under `E:\Created\Home\` or `Home\Private\`.
- **README** with the house section order, an emoji at the start of every H2 and the badge row (version, platform, language, licence, last commit). Private tools get the row without the Last-commit badge, which can't read a private repo.
- **CHANGELOG.md** in Keep a Changelog format, starting at `[1.00]` with today's date.
- **MIT LICENSE**, `Copyright (c) <year> Jason Rhodes`.
- **.gitignore and .gitattributes**: exes, `Builds\`, `Data\`, `config.local.json`, `.env`, logs; CRLF for `.ps1`, `.psd1` and `.cmd`. `config.example.json` shows the shape of the gitignored config.
- **build.json** for the standard build script, and **Build-Exe.cmd**, which builds from `build.json` alone until `E:\Created\_shared\Build-Tool.ps1` exists: it checks the version against the CHANGELOG, runs PSScriptAnalyzer (with the repo's `PSScriptAnalyzerSettings.psd1`), embeds the icon and logo, and saves `..\Builds\<App Name> v1.00.exe`.
- **launcher.json** with the tool's category, so the Home Launcher files it in the right group.
- **Starter script** `src\<Name>.ps1`: version and name in one place, settings in `%APPDATA%\<App Name>` (or `<project>\Data` for private tools), assets that work from the script and from the exe, a log, and the **About box** (logo, name, version, About-box description, data folder, repo link, copyright and MIT licence). The window is a placeholder: house style sets what the About box says, never how the app looks.
- **Issue templates** for bug reports and feature requests, and a placeholder icon drawn from the tool's initials.

## 📋 Requirements

- Windows 10 or 11 with Windows PowerShell 5.1.
- [Git](https://git-scm.com/) to start the repo, and the [GitHub CLI](https://cli.github.com/) (`gh`) to publish it.

## 📦 Installation

The working copy lives in `E:\Created\Home\_templates\template-home\`. The Home Launcher skips folders that start with `_`, so it never shows up as a tool.

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

That makes `E:\Created\Home\Media-Hub\Source\` (a new git repo, nothing committed yet) and `E:\Created\Home\Media-Hub\Builds\`. Add `-Private` for a tool under `Home\Private\` (unlock the vault first). It stops without changing anything if the project folder already exists. The template folder is never changed.

| Parameter | What it's for |
| --- | --- |
| `-AppName` | Display name with spaces. Window title, About box, `%APPDATA%` folder and exe name (`Media Hub v1.00.exe`). |
| `-Tagline` | The README's one line under the title. The launcher shows it too. |
| `-Description` | About-box formula: `<Language>/<UI> tool for <what it does>`. Also the exe's description. |
| `-Slug` | Folder, repo and script name. Defaults to the name in Title-Case-With-Hyphens (`Media-Hub`). |
| `-Category` | Launcher group, e.g. `Films and TV`, `Music`, `Windows`. Default `Tools`. |
| `-Private` | `Home\Private\`, data in `<project>\Data`, no Last-commit badge, `gh repo create --private`. |

### From GitHub (Use this template)

1. On GitHub, **Use this template → Create a new repository**, named in Title-Case-With-Hyphens.
2. Clone it into `E:\Created\Home\<Name>\Source\`.
3. In that folder: `.\Initialize-Template.ps1 -InPlace -AppName "..." -Tagline "..." -Description "..."`. It moves `starter\` into place, fills it in, makes `..\Builds\` and deletes the template-only files.

### Then

1. Write the tool in `src\<Name>.ps1`. Keep `$script:AppVersion` in step with the newest CHANGELOG entry.
2. Replace the placeholder icon, fill in the README sections (leave out any that don't apply; never reorder them) and add a screenshot.
3. Run the pre-upload review: code, GUI and graphics, improvements.
4. Double-click **Build-Exe.cmd**.
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
| `{{GITHUB_USER}}` | `jason4bury` (`-GitHubUser`) |
| `{{YEAR}}`, `{{DATE}}` | today |
| `{{DATA_LOCATION}}` | where settings live, public or private |
| `{{PRIVATE}}` | `true` or `false` in the starter script |

`starter\Start App.cmd` and `starter\src\App.ps1` are renamed to `Start <App Name>.cmd` and `src\<Name>.ps1`.

## 📝 Changelog

See [CHANGELOG.md](CHANGELOG.md).

## 📄 Licence

[MIT](LICENSE). Copyright (c) 2026 Jason Rhodes.

Created by Jason Rhodes, built with Claude (Anthropic).
