[CmdletBinding(SupportsShouldProcess=$true)]
param([string]$GamePath,[string]$SteamPath,[switch]$Elevated)
$ErrorActionPreference='Stop'
try {
    . (Join-Path $PSScriptRoot 'Installer.Common.ps1')
    $target=Resolve-DideGamePath -GamePath $GamePath -SteamPath $SteamPath
    Write-Host "Game folder: $target"
    try { $result=Uninstall-DidePackage -GamePath $target -WhatIf:$WhatIfPreference }
    catch [UnauthorizedAccessException] {
        if($Elevated) { throw }
        Write-Host 'Administrator access is required. Approve the Windows UAC prompt to continue.'
        $code=Invoke-DideElevatedRetry -ScriptPath $PSCommandPath -GamePath $target
        if($code -ne 0) { throw "The elevated uninstaller failed (exit $code). Close the game and check folder permissions before retrying." }
        Write-Host "SUCCESS: uninstallation completed in the elevated process for $target"
        exit 0
    }
    if($result.Status -eq 'WhatIf') { Write-Host 'CHECK ONLY: nothing was removed.' }
    else { Write-Host "SUCCESS: $($result.Status) in $($result.GamePath)" }
    exit 0
} catch { Write-Host "UNINSTALL FAILED: $($_.Exception.Message)" -ForegroundColor Red; exit 1 }
