[CmdletBinding(SupportsShouldProcess=$true)]
param([string]$GamePath,[string]$SteamPath,[switch]$Elevated)
$ErrorActionPreference='Stop'
try {
    . (Join-Path $PSScriptRoot 'Installer.Common.ps1')
    $target=Resolve-DideGamePath -GamePath $GamePath -SteamPath $SteamPath
    Write-Host "Game folder: $target"
    try { $result=Install-DidePackage -PackagePath $PSScriptRoot -GamePath $target -WhatIf:$WhatIfPreference }
    catch [UnauthorizedAccessException] {
        if($Elevated) { throw }
        Write-Host 'Administrator access is required. Approve the Windows UAC prompt to continue.'
        $code=Invoke-DideElevatedRetry -ScriptPath $PSCommandPath -GamePath $target
        if($code -ne 0) { throw "The elevated installer failed (exit $code). Rerun Install.cmd to see validation details; close the game and check folder permissions." }
        Write-Host "SUCCESS: installation completed in the elevated process for $target"
        exit 0
    }
    if($result.Status -eq 'WhatIf') { Write-Host 'CHECK ONLY: validation passed; nothing was installed.' }
    else { Write-Host "SUCCESS: $($result.Status) $($result.Version) in $($result.GamePath)" }
    Write-Host 'Completion chat is disabled in this diagnostic. Install on A/B only; C stays vanilla.'
    exit 0
} catch { Write-Host "INSTALL FAILED: $($_.Exception.Message)" -ForegroundColor Red; exit 1 }
