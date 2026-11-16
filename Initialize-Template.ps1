<#
.SYNOPSIS
    Starts a new Home tool from template-home, in house style.

.DESCRIPTION
    Fills in the files in starter\ (README, CHANGELOG, LICENSE, build.json, launcher.json,
    Build.cmd, the starter script and its About box, the shortcut maker and the release's
    "<App Name>.cmd") with the tool's name and descriptions, and draws a placeholder icon.
    Home tools have no exe: Build.cmd makes a script release folder and a shortcut.

    Two ways to use it:

    1. New project on disk (the usual way). Run from this template folder, or double-click
       "New Home Tool.cmd":
           .\Initialize-Template.ps1 -AppName "Media Hub" -Tagline "..." -Description "PowerShell/WPF tool for ..."
       It makes E:\Created\Home\Media-Hub\Source\ (the new repo, with git init) and
       E:\Created\Home\Media-Hub\Builds\. Add -Private for E:\Created\Home\Private\<Name>\.
       The template folder itself isn't changed.

    2. In place, after "Use this template" on GitHub. Clone the new repo into
       <project>\Source\, then run this script from there with -InPlace. It moves starter\
       into the repo root, fills it in, and deletes starter\, this script and the template's
       own README and CHANGELOG. Review and commit the result.

    Nothing is ever overwritten in a project that already exists.

.PARAMETER AppName
    Display name with spaces, e.g. "Media Hub". Used for the window title, About box,
    %APPDATA% folder, shortcut and release folder ("Builds\Media Hub v1.00\").

.PARAMETER Tagline
    One line for the README under the title, e.g. "Browse and play everything on your NAS."

.PARAMETER Description
    The GitHub About-box description and the shortcut's comment, in the formula
    "<Language>/<UI> tool for <what it does>", e.g. "PowerShell/WPF tool for managing winget updates".

.PARAMETER Slug
    Folder, repo and main-script name. Defaults to the AppName in Title-Case-With-Hyphens.

.PARAMETER Category
    Launcher category for launcher.json (e.g. "Films and TV", "Music", "Windows"). Default "Tools".

.PARAMETER Private
    A private tool: goes under Home\Private\, keeps its data in <project>\Data (inside the vault)
    instead of %APPDATA%, and its README has no Last-commit badge (it can't read a private repo).

.NOTES
    Copyright (c) 2026 Jason Rhodes - MIT licence (see LICENSE)
#>

#Requires -Version 5.1
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'NoPause', Justification = 'Read by Exit-Script')]
[CmdletBinding()]
param(
    [string]$AppName,
    [string]$Tagline,
    [string]$Description,
    [string]$Slug,
    [string]$Category = 'Tools',
    [switch]$Private,
    [string]$HomeRoot = 'E:\Created\Home',
    [string]$GitHubUser = 'jason4bury',
    [switch]$InPlace,
    [switch]$NoGit,
    [switch]$NoPause
)

$ErrorActionPreference = 'Stop'
$templateDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$starterDir  = Join-Path $templateDir 'starter'

function Read-Value([string]$Prompt, [string]$Example) {
    Write-Host ''
    Write-Host $Prompt -ForegroundColor White
    if ($Example) { Write-Host "  e.g. $Example" -ForegroundColor DarkGray }
    return (Read-Host ' ').Trim()
}

function Exit-Script([int]$Code) {
    if (-not $NoPause -and [Environment]::UserInteractive -and $Host.Name -eq 'ConsoleHost') {
        Write-Host ''; [void](Read-Host 'Press Enter to close')
    }
    exit $Code
}

function Write-TextFile([string]$Path, [string]$Text) {
    # CRLF throughout (git's text=auto stores LF); scripts get a BOM so Windows PowerShell 5.1
    # reads non-ASCII characters (the About box middle dot) correctly.
    $Text = ($Text -replace "`r`n", "`n") -replace "`n", "`r`n"
    $bom  = [IO.Path]::GetExtension($Path) -in '.ps1', '.psd1', '.psm1'
    [IO.File]::WriteAllText($Path, $Text, (New-Object System.Text.UTF8Encoding($bom)))
}

function New-PlaceholderIcon {
    <# A plain rounded square with the tool's initials, as assets\<Slug>.png (256 px) and
       assets\<Slug>.ico (16-256 px). Only a stand-in: replace both with the tool's own icon. #>
    param([string]$Name, [string]$AssetsDir, [string]$FileBase)
    Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase
    $words = @($Name -split '[\s\-_]+' | Where-Object { $_ })
    $initials = (($words | Select-Object -First 2 | ForEach-Object { $_.Substring(0, 1).ToUpper() }) -join '')
    $palette = '#1E3A5F', '#2E6B4F', '#7A3E65', '#8A4B12', '#3E4C8A', '#5B5F66'
    $sum = 0; foreach ($ch in $Name.ToCharArray()) { $sum += [int]$ch }
    $fill = [Windows.Media.BrushConverter]::new().ConvertFromString($palette[$sum % $palette.Count])

    $render = {
        param([int]$Size)
        $dv = New-Object Windows.Media.DrawingVisual
        $dc = $dv.RenderOpen()
        $r = $Size * 0.18
        $dc.DrawRoundedRectangle($fill, $null, (New-Object Windows.Rect 0, 0, $Size, $Size), $r, $r)
        $tf = New-Object Windows.Media.Typeface (New-Object Windows.Media.FontFamily 'Segoe UI'), ([Windows.FontStyles]::Normal), ([Windows.FontWeights]::SemiBold), ([Windows.FontStretches]::Normal)
        $em = $Size * $(if ($initials.Length -gt 1) { 0.42 } else { 0.55 })
        $ft = New-Object Windows.Media.FormattedText $initials, ([Globalization.CultureInfo]::InvariantCulture), ([Windows.FlowDirection]::LeftToRight), $tf, $em, ([Windows.Media.Brushes]::White), 1.0
        $dc.DrawText($ft, (New-Object Windows.Point (($Size - $ft.Width) / 2), (($Size - $ft.Height) / 2)))
        $dc.Close()
        $bmp = New-Object Windows.Media.Imaging.RenderTargetBitmap $Size, $Size, 96, 96, ([Windows.Media.PixelFormats]::Pbgra32)
        $bmp.Render($dv)
        $enc = New-Object Windows.Media.Imaging.PngBitmapEncoder
        [void]$enc.Frames.Add([Windows.Media.Imaging.BitmapFrame]::Create($bmp))
        $ms = New-Object IO.MemoryStream; $enc.Save($ms); $b = $ms.ToArray(); $ms.Dispose()
        , $b
    }

    $sizes = 16, 20, 24, 32, 40, 48, 64, 96, 128, 256
    $pngs = foreach ($sz in $sizes) { , (& $render $sz) }
    [IO.File]::WriteAllBytes((Join-Path $AssetsDir "$FileBase.png"), $pngs[-1])

    $fs = [IO.File]::Create((Join-Path $AssetsDir "$FileBase.ico")); $bw = New-Object IO.BinaryWriter $fs
    try {
        $bw.Write([uint16]0); $bw.Write([uint16]1); $bw.Write([uint16]$sizes.Count)   # ICONDIR
        $offset = 6 + 16 * $sizes.Count
        for ($i = 0; $i -lt $sizes.Count; $i++) {                                         # ICONDIRENTRY per size
            $d = $(if ($sizes[$i] -ge 256) { 0 } else { $sizes[$i] })
            $bw.Write([byte]$d); $bw.Write([byte]$d); $bw.Write([byte]0); $bw.Write([byte]0)
            $bw.Write([uint16]1); $bw.Write([uint16]32); $bw.Write([uint32]$pngs[$i].Length); $bw.Write([uint32]$offset)
            $offset += $pngs[$i].Length
        }
        foreach ($p in $pngs) { $bw.Write([byte[]]$p) }
    } finally { $bw.Close() }
}

try {
    if (-not (Test-Path -LiteralPath $starterDir)) { throw "starter\ wasn't found in $templateDir. Has this template already been used in place?" }

    Write-Host ''
    Write-Host '  N E W   H O M E   T O O L   -   from template-home' -ForegroundColor Cyan

    # ---- What the tool is called and what it does ----
    if (-not $AppName)     { $AppName     = Read-Value 'Display name, with spaces (used for the shortcut and release folder: "<name> v1.00")' 'Media Hub' }
    if (-not $Tagline)     { $Tagline     = Read-Value 'One-line tagline for the README' 'Browse and play everything on your NAS.' }
    if (-not $Description) { $Description = Read-Value 'GitHub About-box description: "<Language>/<UI> tool for <what it does>"' 'PowerShell/WPF tool for managing winget updates' }
    if (-not $AppName -or -not $Tagline -or -not $Description) { throw 'A name, tagline and description are all needed.' }
    if ($AppName -notmatch '^[A-Za-z0-9][A-Za-z0-9 ]*$') { throw "Use letters, digits and spaces only in the name ('$AppName')." }
    if ($Description.Contains("'")) { throw "Leave apostrophes out of the description (it goes inside quotes in the scripts)." }
    if ($Description -notmatch '^\S+/\S+ tool for ') { Write-Warning "The About-box formula is '<Language>/<UI> tool for <what it does>' (e.g. 'PowerShell/WPF tool for ...')." }
    $Description = $Description.TrimEnd('.')
    if (-not $Slug) { $Slug = (($AppName -split '\s+' | Where-Object { $_ } | ForEach-Object { $_.Substring(0, 1).ToUpper() + $_.Substring(1) }) -join '-') }
    if ($Slug -notmatch '^[A-Za-z0-9]+(-[A-Za-z0-9]+)*$') { throw "The folder/repo name '$Slug' should be Title-Case-With-Hyphens." }

    # ---- Where it goes ----
    if ($InPlace) {
        $sourceDir = $templateDir
        $projectDir = Split-Path -Parent $sourceDir
        if ((Split-Path -Leaf $sourceDir) -ne 'Source') { Write-Warning "House style keeps the repo in <project>\Source\. This repo is in $sourceDir." }
    } else {
        $root = if ($Private) { Join-Path $HomeRoot 'Private' } else { $HomeRoot }
        if (-not (Test-Path -LiteralPath $root)) {
            if ($Private) { throw "$root isn't there. Unlock the Private vault first (Home Launcher, Ctrl+Shift+U)." }
            throw "$root isn't there. Use -HomeRoot to say where the Home folder is."
        }
        $projectDir = Join-Path $root $Slug
        $sourceDir  = Join-Path $projectDir 'Source'
        if (Test-Path -LiteralPath $projectDir) { throw "$projectDir already exists. Nothing was changed." }
    }

    $today = (Get-Date).ToString('yyyy-MM-dd')
    $shortcutScript = "New-$($Slug -replace '-', '')Shortcut.ps1"
    $year  = (Get-Date).Year
    $dataMd    = if ($Private) { "everything $AppName stores is in the project's ``Data\`` folder, beside ``Source\`` and ``Builds\``, inside the encrypted Private folder. Nothing is written to ``%APPDATA%``, and it is never inside the repo." }
                 else          { "everything $AppName stores is in ``%APPDATA%\$AppName\``. It stays on your PC and is never inside the repo or the ``Builds\`` folder, so rebuilding or updating can't touch it." }
    $dataPlain = if ($Private) { '<project>\Data, inside the encrypted Private folder (never %APPDATA%)' }
                 else          { "%APPDATA%\$AppName" }
    $values = [ordered]@{
        '{{APP_NAME}}'            = $AppName
        '{{APP_SLUG}}'            = $Slug
        '{{TAGLINE}}'             = $Tagline
        '{{DESCRIPTION}}'         = $Description
        '{{CATEGORY}}'            = $Category
        '{{GITHUB_USER}}'         = $GitHubUser
        '{{YEAR}}'                = "$year"
        '{{DATE}}'                = $today
        '{{DATA_LOCATION}}'       = $dataMd
        '{{DATA_LOCATION_PLAIN}}' = $dataPlain
        '{{PRIVATE}}'             = $(if ($Private) { 'true' } else { 'false' })
        '{{APP_ID}}'              = "$GitHubUser.$Slug"
        '{{SHORTCUT_SCRIPT}}'     = $shortcutScript
    }

    # ---- Copy and fill in ----
    Write-Host ''
    Write-Host "Making $AppName in $projectDir" -ForegroundColor White
    if (-not (Test-Path -LiteralPath $sourceDir)) { New-Item -ItemType Directory -Path $sourceDir -Force | Out-Null }
    $renames = @{ 'Start App.cmd' = "Start $AppName.cmd"; 'App.ps1' = "$Slug.ps1"; 'App.cmd' = "$AppName.cmd"; 'New-AppShortcut.ps1' = $shortcutScript }
    $textExt = '.md', '.json', '.ps1', '.psd1', '.cmd', '.txt', '', '.gitignore', '.gitattributes'
    $files = Get-ChildItem -LiteralPath $starterDir -Recurse -File -Force
    foreach ($f in $files) {
        $rel = $f.FullName.Substring($starterDir.Length).TrimStart('\')
        $leaf = Split-Path -Leaf $rel
        if ($renames.ContainsKey($leaf)) {
            $parent = Split-Path -Parent $rel
            $rel = if ($parent) { Join-Path $parent $renames[$leaf] } else { $renames[$leaf] }
        }
        $dest = Join-Path $sourceDir $rel
        $destDir = Split-Path -Parent $dest
        if (-not (Test-Path -LiteralPath $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
        if ($f.Extension -in $textExt) {
            $text = [IO.File]::ReadAllText($f.FullName)
            foreach ($k in $values.Keys) { $text = $text.Replace($k, $values[$k]) }
            if ($leaf -eq 'README.md' -and $Private) {
                $text = $text -replace ' !\[Last commit\]\([^)]*\)', ''
                $text = $text.Replace('    Private repos: drop the Last-commit badge', '    Private repo: the Last-commit badge is left out')
            }
            Write-TextFile $dest $text
        } else {
            Copy-Item -LiteralPath $f.FullName -Destination $dest -Force
        }
        Write-Host "  + $rel" -ForegroundColor DarkGray
    }
    $left = @(Get-ChildItem -LiteralPath $sourceDir -Recurse -File -Force | Where-Object { $_.FullName -notmatch '\\\.git\\' -and -not $_.FullName.StartsWith($starterDir + '\') -and $_.Extension -in $textExt } |
              Select-String -Pattern '\{\{[A-Z_]+\}\}' -List)
    if ($left.Count) { Write-Warning ("Placeholders left in: " + (($left | ForEach-Object { $_.Path.Substring($sourceDir.Length + 1) }) -join ', ')) }

    # ---- Placeholder icon ----
    $assets = Join-Path $sourceDir 'assets'
    if (-not (Test-Path -LiteralPath (Join-Path $assets "$Slug.ico"))) {
        try {
            if ([Threading.Thread]::CurrentThread.GetApartmentState() -ne 'STA') { throw 'drawing needs an STA thread (use Windows PowerShell or New Home Tool.cmd)' }
            New-PlaceholderIcon -Name $AppName -AssetsDir $assets -FileBase $Slug
            Remove-Item -LiteralPath (Join-Path $assets '.gitkeep') -Force -ErrorAction SilentlyContinue
            Write-Host "  + assets\$Slug.ico and .png (placeholder: replace with the tool's own icon)" -ForegroundColor DarkGray
        } catch { Write-Warning "No placeholder icon: $($_.Exception.Message). Add assets\$Slug.ico and .png yourself." }
    }

    # ---- Builds\ beside Source\ ----
    $builds = Join-Path $projectDir 'Builds'
    if (-not (Test-Path -LiteralPath $builds)) { New-Item -ItemType Directory -Path $builds -Force | Out-Null; Write-Host "  + ..\Builds\" -ForegroundColor DarkGray }

    # ---- In place: remove the template's own files ----
    if ($InPlace) {
        Remove-Item -LiteralPath $starterDir -Recurse -Force
        foreach ($n in 'New Home Tool.cmd', 'Initialize-Template.ps1', 'assets\template-home.png', 'assets\template-home.ico') {
            $p = Join-Path $sourceDir $n
            if (Test-Path -LiteralPath $p) { Remove-Item -LiteralPath $p -Force }
        }
        Write-Host '  - starter\, Initialize-Template.ps1 and New Home Tool.cmd (template only)' -ForegroundColor DarkGray
    }

    # ---- git ----
    if (-not $NoGit -and -not (Test-Path -LiteralPath (Join-Path $sourceDir '.git'))) {
        if (Get-Command git -ErrorAction SilentlyContinue) {
            & git -C $sourceDir init -b main 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) { Write-Host '  + git repo (branch main), nothing committed yet' -ForegroundColor DarkGray }
            else { Write-Warning 'git init failed; run it yourself in Source\.' }
        } else { Write-Warning 'git not found; run git init yourself in Source\.' }
    }

    Write-Host ''
    Write-Host "Done: $sourceDir" -ForegroundColor Green
    Write-Host ''
    Write-Host 'Next:' -ForegroundColor White
    Write-Host "  1. Write the tool in src\$Slug.ps1 (keep `$script:AppVersion = '1.00' in step with CHANGELOG.md)."
    Write-Host '  2. Replace the placeholder icon in assets\, fill in the README sections and add a screenshot.'
    Write-Host '  3. Pre-upload review: code, GUI/graphics, improvements.'
    Write-Host "  4. Double-click Build.cmd: it makes ..\Builds\$AppName v1.00\, its zip and $AppName.lnk."
    $vis = if ($Private) { '--private' } else { '--public' }
    if ($InPlace) { Write-Host '  5. Commit and push (the GitHub repo already exists), then set its About description and topics.' }
    else { Write-Host "  5. Commit, then: gh repo create $GitHubUser/$Slug $vis --source `"$sourceDir`" --description `"$Description`" --push" }
    Exit-Script 0
} catch {
    Write-Host ''
    Write-Host "Stopped: $($_.Exception.Message)" -ForegroundColor Red
    Exit-Script 1
}
