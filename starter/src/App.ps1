<#
.SYNOPSIS
    {{APP_NAME}} - {{TAGLINE}}

.DESCRIPTION
    {{DESCRIPTION}}.

    Project layout (house style):
        <project>\Source\               the git repo (this script is in Source\src\)
        <project>\Source\assets\        icon (.ico) and logo (.png)
        <project>\Builds\               "{{APP_NAME}} v<version>\" release folders, their zips and
                                        "{{APP_NAME}}.lnk", made by Build.cmd (no exe)
    Settings and data: {{DATA_LOCATION_PLAIN}}

.NOTES
    Author:    {{AUTHOR}}
    Copyright: (c) {{YEAR}} {{AUTHOR}} - MIT licence (see LICENSE)
    Version:   see $script:AppVersion below and CHANGELOG.md
    Runs in Windows PowerShell 5.1 on an STA thread (WPF needs it).
#>

#Requires -Version 5.1

$ErrorActionPreference = 'Stop'

# The version lives here and in CHANGELOG.md; Build.cmd stops if they disagree.
# Two-digit minor: 1.00, 1.01 ... 1.10. The release folder is "{{APP_NAME}} v<version>".
$script:AppName     = '{{APP_NAME}}'
$script:AppVersion  = '1.00'
$script:Description = '{{DESCRIPTION}}'
$script:Copyright   = 'Copyright (c) {{YEAR}} {{AUTHOR}}'
$script:RepoUrl     = 'https://github.com/{{GITHUB_USER}}/{{APP_SLUG}}'
$script:IsPrivate   = ${{PRIVATE}}   # private tools keep their data in <project>\Data, inside the vault
$script:AppId       = '{{APP_ID}}'   # taskbar ID; the shortcut made by {{SHORTCUT_SCRIPT}} uses the same one

# ---------------------------------------------------------------------------
#  Where is everything? No exe: this script runs from Source\src\ (while
#  developing) or from a release folder, Builds\{{APP_NAME}} v<version>\ (or
#  wherever the release zip was unpacked), with assets\ beside it.
# ---------------------------------------------------------------------------
# WPF needs an STA thread. Started any other way, restart in Windows PowerShell with -STA.
if ([Threading.Thread]::CurrentThread.GetApartmentState() -ne 'STA') {
    $ps = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
    Start-Process -FilePath $ps -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-STA', '-WindowStyle', 'Hidden', '-File', "`"$PSCommandPath`"")
    return
}

# One taskbar button with the tool's own icon (not PowerShell's), and pinning it pins the tool.
try {
    Add-Type -Namespace 'HomeTool' -Name 'Shell' -MemberDefinition '[DllImport("shell32.dll", CharSet = CharSet.Unicode)] public static extern int SetCurrentProcessExplicitAppUserModelID(string appId);'
    [void][HomeTool.Shell]::SetCurrentProcessExplicitAppUserModelID($script:AppId)
} catch { Write-Verbose "No taskbar ID: $($_.Exception.Message)" }

$script:ProgramDir = Split-Path -Parent $PSCommandPath
$script:AssetsDir  = @((Join-Path $script:ProgramDir 'assets'), (Join-Path (Split-Path -Parent $script:ProgramDir) 'assets')) |
    Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
if (-not $script:AssetsDir) { $script:AssetsDir = Join-Path $script:ProgramDir 'assets' }

function Get-DataDir {
    <# Public tools: %APPDATA%\<App Name>. Private tools: <project>\Data, beside Source\ and
       Builds\, so nothing is written to the unencrypted drive. Never inside Source\ (keeps
       personal data out of git) or a release folder (each version has its own, so data kept
       there would be left behind by the next version). #>
    if (-not $script:IsPrivate) { return (Join-Path $env:APPDATA $script:AppName) }
    $up = Split-Path -Parent $script:ProgramDir
    # Source\src\<script> or Builds\<App> v<x.yy>\<script>: <project> is two levels up.
    if (@('Source', 'Builds') -contains (Split-Path -Leaf $up)) { return (Join-Path (Split-Path -Parent $up) 'Data') }
    return (Join-Path $script:ProgramDir 'Data')   # an unpacked release zip somewhere else
}
$script:DataDir      = Get-DataDir
$script:SettingsPath = Join-Path $script:DataDir 'settings.json'
$script:LogPath      = Join-Path $script:DataDir "$($script:AppName).log"
if (-not (Test-Path -LiteralPath $script:DataDir)) { New-Item -ItemType Directory -Path $script:DataDir -Force | Out-Null }

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

# ---------------------------------------------------------------------------
#  Small helpers
# ---------------------------------------------------------------------------
function Write-AppLog {
    param([string]$Message)
    try { Add-Content -LiteralPath $script:LogPath -Value ('{0}  {1}' -f (Get-Date).ToString('yyyy-MM-dd HH:mm:ss'), $Message) -Encoding UTF8 }
    catch { Write-Verbose "Couldn't write the log: $($_.Exception.Message)" }
}

function Get-AssetBytes {
    <# An asset by file name, from assets\ (beside the script in a release, Source\assets\ in the repo). #>
    param([string]$Name)
    $path = Join-Path $script:AssetsDir $Name
    if (Test-Path -LiteralPath $path) { return [IO.File]::ReadAllBytes($path) }
    return $null
}

function Get-AssetImage {
    <# A frozen BitmapImage for a WPF Image or window Icon, or $null if the asset is missing. #>
    param([string]$Name)
    $bytes = Get-AssetBytes $Name
    if (-not $bytes) { return $null }
    $img = New-Object Windows.Media.Imaging.BitmapImage
    $img.BeginInit()
    $img.StreamSource = New-Object IO.MemoryStream (, $bytes)
    $img.CacheOption  = 'OnLoad'
    $img.EndInit(); $img.Freeze()
    return $img
}

function Get-AppSetting {
    <# Settings from settings.json in the data folder; $null where unset. #>
    if (Test-Path -LiteralPath $script:SettingsPath) {
        try { return (Get-Content -LiteralPath $script:SettingsPath -Raw -Encoding UTF8 | ConvertFrom-Json) }
        catch { Write-AppLog "settings.json couldn't be read: $($_.Exception.Message)" }
    }
    return [pscustomobject]@{}
}

function Save-AppSetting {
    param([Parameter(Mandatory)][object]$Settings)
    $Settings | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $script:SettingsPath -Encoding UTF8
}

function New-XamlWindow {
    param([Parameter(Mandatory)][string]$Xaml)
    $reader = New-Object System.Xml.XmlNodeReader ([xml]$Xaml)
    return [Windows.Markup.XamlReader]::Load($reader)
}

#region ABOUT-BOX
# ---------------------------------------------------------------------------
#  About box (house style)
#  Every Home tool's About shows: logo, name, version, the one-line description,
#  the copyright and MIT licence, the repo link and where settings live.
#  House style sets WHAT it says, not how it looks: restyle the XAML to match the
#  app's own window (colours, fonts, buttons), or move these lines onto an existing
#  About tab. Keep the wording.
# ---------------------------------------------------------------------------
$script:AboutXaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        SizeToContent="WidthAndHeight" ResizeMode="NoResize" ShowInTaskbar="False"
        WindowStartupLocation="CenterOwner" FontFamily="Segoe UI" FontSize="13">
    <StackPanel Margin="22" MaxWidth="440">
        <StackPanel Orientation="Horizontal">
            <Image x:Name="AboutLogo" Width="64" Height="64" Margin="0,0,16,0" RenderOptions.BitmapScalingMode="HighQuality"/>
            <StackPanel VerticalAlignment="Center">
                <TextBlock x:Name="AboutName" FontSize="20" FontWeight="SemiBold"/>
                <TextBlock x:Name="AboutVersion" Opacity="0.75"/>
            </StackPanel>
        </StackPanel>
        <TextBlock x:Name="AboutDescription" TextWrapping="Wrap" Margin="0,14,0,0"/>
        <TextBlock x:Name="AboutData" TextWrapping="Wrap" Margin="0,10,0,0" Opacity="0.75"/>
        <TextBlock Margin="0,10,0,0"><Hyperlink x:Name="AboutRepo"><Run x:Name="AboutRepoText"/></Hyperlink></TextBlock>
        <TextBlock x:Name="AboutCopyright" Margin="0,4,0,0" Opacity="0.75"/>
        <Button x:Name="AboutClose" Content="Close" HorizontalAlignment="Right" MinWidth="80" Padding="10,4" Margin="0,16,0,0" IsDefault="True" IsCancel="True"/>
    </StackPanel>
</Window>
'@

function Show-About {
    param([Windows.Window]$Owner)
    $w = New-XamlWindow $script:AboutXaml
    if ($Owner) { $w.Owner = $Owner; $w.Icon = $Owner.Icon }
    $w.Title = "About $script:AppName"
    $w.FindName('AboutLogo').Source       = Get-AssetImage '{{APP_SLUG}}.png'
    $w.FindName('AboutName').Text         = $script:AppName
    $w.FindName('AboutVersion').Text      = "Version $script:AppVersion"
    $w.FindName('AboutDescription').Text  = $script:Description
    $w.FindName('AboutData').Text         = "Settings and data: $script:DataDir"
    $w.FindName('AboutRepoText').Text     = $script:RepoUrl
    $w.FindName('AboutRepo').NavigateUri  = [Uri]$script:RepoUrl
    $w.FindName('AboutRepo').Add_RequestNavigate({ param($s, $e) Start-Process $e.Uri.AbsoluteUri; $e.Handled = $true })
    $w.FindName('AboutCopyright').Text    = "$script:Copyright  ·  MIT licence"
    $w.FindName('AboutClose').Add_Click({ [Windows.Window]::GetWindow($this).Close() })
    [void]$w.ShowDialog()
}
#endregion ABOUT-BOX

# ---------------------------------------------------------------------------
#  Main window (a placeholder: replace with the app's own design)
# ---------------------------------------------------------------------------
$mainXaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Width="720" Height="460" MinWidth="480" MinHeight="320"
        WindowStartupLocation="CenterScreen" FontFamily="Segoe UI" FontSize="13">
    <DockPanel Margin="16">
        <StackPanel DockPanel.Dock="Bottom" Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,12,0,0">
            <Button x:Name="BtnAbout" Content="About" MinWidth="80" Padding="10,4" Margin="0,0,8,0"/>
            <Button x:Name="BtnClose" Content="Close" MinWidth="80" Padding="10,4" IsCancel="True"/>
        </StackPanel>
        <TextBlock x:Name="TxtHello" TextWrapping="Wrap" VerticalAlignment="Center" HorizontalAlignment="Center" FontSize="16"/>
    </DockPanel>
</Window>
'@

try {
    $window = New-XamlWindow $mainXaml
    $window.Title = $script:AppName
    $icon = Get-AssetImage '{{APP_SLUG}}.ico'
    if ($icon) { $window.Icon = $icon }
    $window.FindName('TxtHello').Text = "$script:AppName v$script:AppVersion`n`nReplace this window with your tool."
    $window.FindName('BtnAbout').Add_Click({ Show-About -Owner $window })
    $window.FindName('BtnClose').Add_Click({ $window.Close() })
    Write-AppLog "Started v$script:AppVersion from $script:ProgramDir"
    [void]$window.ShowDialog()
} catch {
    Write-AppLog "Error: $($_.Exception.Message)"
    [void][Windows.MessageBox]::Show("$script:AppName couldn't start:`n`n$($_.Exception.Message)`n`nDetails are in $script:LogPath", $script:AppName, 'OK', 'Error')
    exit 1
}
