<# : batch part - runs the PowerShell part below. Just double-click this file.
@echo off
setlocal
set "BUILD_DIR=%~dp0"
set "BUILD_FILE=%~f0"
rem Started from PowerShell 7, PSModulePath points at PS7 modules that 5.1 can't load
set "PSModulePath="
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Invoke-Expression ([IO.File]::ReadAllText($env:BUILD_FILE))"
set "BUILD_RESULT=%ERRORLEVEL%"
echo.
if not defined NO_PAUSE pause
exit /b %BUILD_RESULT%
: end of batch part #>

# ===========================================================================
# Build-Exe.cmd - builds "..\Builds\<AppName> v<version>.exe" from build.json,
# e.g. "{{APP_NAME}} v1.00.exe".
#
# Interim: once E:\Created\_shared\Build-Tool.ps1 is in place it replaces this
# file (it reads the same build.json). Until then, this builds the same way.
# Nothing in here is tool-specific: it all comes from build.json.
#
# Double-click this file (no admin rights needed). It:
#   1. reads build.json (AppName, EntryScript, Icon, Description, EmbedAssets,
#      Ps2exe options),
#   2. checks the script has no syntax errors and that $script:AppVersion
#      matches the newest CHANGELOG entry,
#   3. runs PSScriptAnalyzer if it's installed (stops on errors, shows warnings),
#   4. pastes the EmbedAssets files into the script's BUNDLE-ASSETS region as
#      base64 (in a copy in %TEMP%), so the exe needs no other files,
#   5. installs ps2exe for the current user if it's missing, then compiles the
#      exe with the icon into the project's Builds folder (next to Source,
#      outside the repo). Older builds stay alongside.
#
# The exe is NOT signed here - the shared build script will do that. If
# antivirus flags the unsigned exe, report a false positive or add an
# exclusion rather than turning protection off.
# Everything shown on screen is also written to Build-Exe.log (gitignored).
# Set NO_PAUSE=1 to skip the "Press any key" at the end.
# ===========================================================================

$ErrorActionPreference = 'Stop'

# Windows PowerShell's own module folders, so the right PSScriptAnalyzer/ps2exe load.
$env:PSModulePath = @(
    (Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'WindowsPowerShell\Modules'),
    (Join-Path $env:ProgramFiles 'WindowsPowerShell\Modules'),
    [Environment]::GetEnvironmentVariable('PSModulePath', 'Machine')
) -join ';'

$here       = if ($env:BUILD_DIR) { $env:BUILD_DIR.TrimEnd('\') } else { (Get-Location).Path }
$buildJson  = Join-Path $here 'build.json'
$changelog  = Join-Path $here 'CHANGELOG.md'
$license    = Join-Path $here 'LICENSE'
$buildsDir  = Join-Path (Split-Path -Parent $here) 'Builds'
$logPath    = Join-Path $here 'Build-Exe.log'
$bundlePath = $null
$old        = $null
$outputPath = $null
$failed     = $false

try { Start-Transcript -LiteralPath $logPath -Force | Out-Null } catch { Write-Verbose 'No transcript.' }

try {
    # Process scope = this build only; ps2exe's module won't load under "Restricted".
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
    $env:PSExecutionPolicyPreference = 'Bypass'

    # --- 1. build.json ---
    if (-not (Test-Path -LiteralPath $buildJson)) { throw "Missing build.json in $here." }
    $cfg = Get-Content -LiteralPath $buildJson -Raw -Encoding UTF8 | ConvertFrom-Json
    if (-not $cfg.AppName -or -not $cfg.EntryScript) { throw 'build.json needs at least AppName and EntryScript.' }
    $appName  = [string]$cfg.AppName
    $script   = Join-Path $here $cfg.EntryScript
    $iconPath = if ($cfg.Icon) { Join-Path $here $cfg.Icon } else { $null }
    $opts     = $cfg.Ps2exe
    function Get-Opt([string]$Name, [bool]$Default) {
        if ($opts -and $opts.PSObject.Properties[$Name]) { return [bool]$opts.$Name }
        return $Default
    }
    foreach ($f in $script, $changelog) {
        if (-not (Test-Path -LiteralPath $f)) { throw "Missing file: $f" }
    }

    # --- 2. Syntax and version ---
    $tokens = $null; $parseErrors = $null
    [void][System.Management.Automation.Language.Parser]::ParseFile($script, [ref]$tokens, [ref]$parseErrors)
    if ($parseErrors.Count -gt 0) {
        throw "$($cfg.EntryScript) has $($parseErrors.Count) syntax error(s). First, on line $($parseErrors[0].Extent.StartLineNumber): $($parseErrors[0].Message)"
    }
    $text = [IO.File]::ReadAllText($script)
    if ($text -notmatch "AppVersion\s*=\s*'(\d+\.\d{2})'") {
        throw "Couldn't find `$script:AppVersion = '<major>.<two-digit minor>' (e.g. '1.00') in $($cfg.EntryScript)."
    }
    $version = $Matches[1]
    if ($text -match "AppName\s*=\s*'([^']+)'" -and $Matches[1] -ne $appName) {
        Write-Warning "The script calls itself '$($Matches[1])' but build.json says '$appName'. The exe is named from build.json."
    }
    $logVersion = $null
    foreach ($line in [IO.File]::ReadAllLines($changelog)) {
        if ($line -match '^##\s*\[(\d+\.\d+)\]') { $logVersion = $Matches[1]; break }
    }
    if ($logVersion -ne $version) {
        throw "The script says v$version but the newest CHANGELOG entry is v$logVersion. Make them match first."
    }
    Write-Host "Building $appName v$version.exe" -ForegroundColor Cyan
    Write-Host ''

    # --- 3. PSScriptAnalyzer (if installed) ---
    if (Get-Module -ListAvailable -Name PSScriptAnalyzer) {
        Write-Host 'Running PSScriptAnalyzer...' -ForegroundColor Cyan
        $settings = Join-Path $here 'PSScriptAnalyzerSettings.psd1'
        $paArgs = @{ Path = $script }
        if (Test-Path -LiteralPath $settings) { $paArgs.Settings = $settings }
        $results = @(Invoke-ScriptAnalyzer @paArgs)
        if ($results.Count -gt 0) { $results | Format-Table -AutoSize Severity, RuleName, Line, Message | Out-String -Width 200 | Write-Host }
        if (@($results | Where-Object Severity -eq 'Error').Count -gt 0) { throw 'PSScriptAnalyzer found errors (see above).' }
        if ($results.Count -eq 0) { Write-Host '  No problems found.' }
        Write-Host ''
    } else {
        Write-Warning 'PSScriptAnalyzer is not installed - skipping static analysis. (Install-Module PSScriptAnalyzer -Scope CurrentUser)'
    }

    # --- 4. Embed assets ---
    $inputFile = $script
    $embed = @($cfg.EmbedAssets | Where-Object { $_ })
    if ($embed.Count -gt 0) {
        $startTag = '#region BUNDLE-ASSETS'; $endTag = '#endregion BUNDLE-ASSETS'
        $start = $text.IndexOf($startTag); $end = $text.IndexOf($endTag)
        if ($start -lt 0 -or $end -lt $start) { throw "build.json lists EmbedAssets but the script has no BUNDLE-ASSETS region." }
        $lines = @('# Embedded by Build-Exe.cmd', '$script:EmbeddedAssets = @{')
        foreach ($rel in $embed) {
            $p = Join-Path $here $rel
            if (-not (Test-Path -LiteralPath $p)) { Write-Warning "EmbedAssets: $rel not found - left out."; continue }
            $lines += "    '$([IO.Path]::GetFileName($p))' = '$([Convert]::ToBase64String([IO.File]::ReadAllBytes($p)))'"
        }
        $lines += '}'
        $bundle = $text.Substring(0, $start) + ($lines -join "`r`n") + $text.Substring($end + $endTag.Length)
        $bundlePath = Join-Path $env:TEMP ("$([IO.Path]::GetFileNameWithoutExtension($script)).bundle.ps1")
        [IO.File]::WriteAllText($bundlePath, $bundle, (New-Object System.Text.UTF8Encoding($true)))
        [void][System.Management.Automation.Language.Parser]::ParseFile($bundlePath, [ref]$tokens, [ref]$parseErrors)
        if ($parseErrors.Count -gt 0) { throw "The bundled script doesn't parse: $($parseErrors[0].Message) (line $($parseErrors[0].Extent.StartLineNumber) of $bundlePath)" }
        $inputFile = $bundlePath
    }

    # --- 5. Compile ---
    $parts = $version.Split('.')
    $fileVersion = '{0}.{1}.0.0' -f [int]$parts[0], [int]$parts[1]   # 1.00 -> 1.0.0.0, 1.10 -> 1.10.0.0
    if (-not (Test-Path -LiteralPath $buildsDir)) { New-Item -ItemType Directory -Path $buildsDir -Force | Out-Null }
    $outputPath = Join-Path $buildsDir "$appName v$version.exe"

    $running = @(Get-Process -ErrorAction SilentlyContinue | Where-Object { try { $_.Path -eq $outputPath } catch { $false } })
    if ($running.Count -gt 0) { throw "$appName v$version.exe is running. Close it, then build again." }

    $copyright = "Copyright (c) $((Get-Date).Year) Jason Rhodes"
    if (Test-Path -LiteralPath $license) {
        $m = Select-String -LiteralPath $license -Pattern '^Copyright \(c\) .+$' | Select-Object -First 1
        if ($m) { $copyright = $m.Line.Trim() }
    }

    if (-not (Get-Module -ListAvailable -Name ps2exe)) {
        Write-Host 'ps2exe module not found - installing for the current user (one-time)...' -ForegroundColor Cyan
        try {
            [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
        } catch { Write-Verbose 'TLS 1.2 already on.' }
        if (-not (Get-PackageProvider -ListAvailable -Name NuGet -ErrorAction SilentlyContinue |
                  Where-Object { $_.Version -ge [version]'2.8.5.201' })) {
            Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Scope CurrentUser -Force | Out-Null
        }
        Install-Module -Name ps2exe -Scope CurrentUser -Repository PSGallery -Force -AllowClobber
    }
    Import-Module ps2exe

    $appArgs = @{
        inputFile    = $inputFile
        outputFile   = $outputPath
        STA          = (Get-Opt 'STA' $true)
        noConsole    = (Get-Opt 'NoConsole' $true)
        noOutput     = (Get-Opt 'NoOutput' $false)
        noError      = (Get-Opt 'NoError' $false)
        noConfigFile = (Get-Opt 'NoConfigFile' $true)
        requireAdmin = (Get-Opt 'RequireAdmin' $false)
        title        = $appName
        description  = $(if ($cfg.Description) { [string]$cfg.Description } else { $appName })
        product      = $appName
        version      = $fileVersion
        company      = 'Jason Rhodes'
        copyright    = $copyright
    }
    if ($iconPath -and (Test-Path -LiteralPath $iconPath)) { $appArgs.iconFile = $iconPath }
    else { Write-Warning "No icon at '$($cfg.Icon)' - building with the standard icon." }

    $old = $null
    if (Test-Path -LiteralPath $outputPath) { $old = "$outputPath.old"; Move-Item -LiteralPath $outputPath -Destination $old -Force }
    Invoke-ps2exe @appArgs

    Start-Sleep -Seconds 2   # give the antivirus a moment to look at it
    if (-not (Test-Path -LiteralPath $outputPath)) {
        if ($old -and (Test-Path -LiteralPath $old)) { Move-Item -LiteralPath $old -Destination $outputPath -Force }
        throw "The exe wasn't made, or it was made and then disappeared (antivirus quarantine?). Check Windows Security > Protection history."
    }
    if ($old) { Remove-Item -LiteralPath $old -Force -ErrorAction SilentlyContinue }
    Write-Host ''
    Write-Host "Done: $outputPath" -ForegroundColor Green
} catch {
    $failed = $true
    if ($old -and (Test-Path -LiteralPath $old) -and -not (Test-Path -LiteralPath $outputPath)) {
        Move-Item -LiteralPath $old -Destination $outputPath -Force   # put the previous build back
    }
    Write-Host ''
    Write-Host "Build failed: $($_.Exception.Message)" -ForegroundColor Red
} finally {
    if ($bundlePath) { Remove-Item -LiteralPath $bundlePath -Force -ErrorAction SilentlyContinue }
}

try { Stop-Transcript | Out-Null } catch { Write-Verbose 'No transcript.' }

if ($failed) { [Environment]::Exit(1) }
