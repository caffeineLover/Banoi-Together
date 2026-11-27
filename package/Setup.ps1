[CmdletBinding()]
param([string]$GamePath,[string]$SteamPath)
$ErrorActionPreference='Stop'

try {
    Write-Host 'Banoi Together Setup'
    Write-Host '  1. Install or upgrade'
    Write-Host '  2. Uninstall'
    Write-Host '  Q. Quit'
    Write-Host 'Choose 1, 2, or Q and press Enter.'
    $choice=[Console]::ReadLine()
    if($null -eq $choice -or $choice.Trim() -eq 'Q') { exit 0 }
    $options=@{}
    if($GamePath) { $options.GamePath=$GamePath }
    if($SteamPath) { $options.SteamPath=$SteamPath }
    if($choice.Trim() -eq '2') {
        Write-Host 'Type Y and press Enter to uninstall, or press Enter to cancel.'
        if([Console]::ReadLine() -ne 'Y') { exit 0 }
        & (Join-Path $PSScriptRoot 'Uninstall.ps1') @options
        exit $LASTEXITCODE
    }
    if($choice.Trim() -ne '1') { throw 'Choose 1, 2, or Q.' }

    Write-Host 'Enter P for Peter, H for Hannah, M for Morty, or Q to cancel.'
    $role=[Console]::ReadLine()
    if($null -eq $role -or $role.Trim() -eq 'Q') { exit 0 }
    $role=$role.Trim().ToUpperInvariant()
    $names=@{ P='Peter'; H='Hannah'; M='Morty' }
    if(-not $names.ContainsKey($role)) { throw 'Enter P, H, or M as the tester role.' }

    $desktop=[Environment]::GetFolderPath([Environment+SpecialFolder]::DesktopDirectory)
    if(-not $desktop -or -not [IO.Directory]::Exists($desktop)) { throw 'Windows did not provide an accessible Desktop folder.' }
    $config=Join-Path $desktop 'BanoiTogether.yaml'
    if(-not (Test-Path -LiteralPath $config)) {
        [IO.File]::Copy((Join-Path $PSScriptRoot 'BanoiTogether.yaml'),$config,$false)
    }
    $probe=Join-Path $desktop ('BanoiTogether-'+[guid]::NewGuid().ToString('N')+'.tmp')
    [IO.File]::Open($probe,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None,4096,[IO.FileOptions]::DeleteOnClose).Dispose()

    & (Join-Path $PSScriptRoot 'Install.ps1') @options
    if($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    # Save the role in the original user's profile, after any elevated installer returns.
    $key='HKCU:\Software\BanoiTogether'
    if(-not (Test-Path -LiteralPath $key)) { New-Item -Path $key -Force | Out-Null }
    New-ItemProperty -LiteralPath $key -Name TesterRole -PropertyType String -Value $role -Force | Out-Null
    Write-Host "Setup complete for $($names[$role]) ($role). Launch the game to create a new timestamped Desktop log."
    Write-Host "Desktop: $desktop"
    Write-Host "Shortcut settings: $config"
    exit 0
} catch {
    Write-Host "SETUP FAILED: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
