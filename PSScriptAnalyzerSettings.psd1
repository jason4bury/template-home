# PSScriptAnalyzer settings for Initialize-Template.ps1.
#   Invoke-ScriptAnalyzer -Path .\Initialize-Template.ps1 -Settings .\PSScriptAnalyzerSettings.psd1
# (The starter has its own copy, which goes into each new tool.)
@{
    Severity     = @('Error', 'Warning')
    ExcludeRules = @(
        # A one-off console script: Write-Host is the output, and its helpers
        # aren't exported cmdlets.
        'PSAvoidUsingWriteHost',
        'PSUseShouldProcessForStateChangingFunctions',
        'PSUseSingularNouns'
    )
}
