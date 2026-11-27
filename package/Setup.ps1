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

    Write-Host 'Enter your tester role (A or B), or Q to cancel.'
    $role=[Console]::ReadLine()
    if($null -eq $role -or $role.Trim() -eq 'Q') { exit 0 }
    $role=$role.Trim().ToUpperInvariant()
    if($role -cnotin @('A','B')) { throw 'Enter A or B as the tester role.' }

    $desktop=[Environment]::GetFolderPath([Environment+SpecialFolder]::DesktopDirectory)
    if(-not $desktop -or -not [IO.Directory]::Exists($desktop)) { throw 'Windows did not provide an accessible Desktop folder.' }
    $logPath=Join-Path $desktop "DIDEQuestChatPoC-$role.log"
    $log=[IO.File]::Open($logPath,[IO.FileMode]::OpenOrCreate,[IO.FileAccess]::Write,[IO.FileShare]::ReadWrite)
    $log.Dispose()

    & (Join-Path $PSScriptRoot 'Install.ps1') @options
    if($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    # Save the role in the original user's profile, after any elevated installer returns.
    $key='HKCU:\Software\BanoiTogether'
    if(-not (Test-Path -LiteralPath $key)) { New-Item -Path $key -Force | Out-Null }
    New-ItemProperty -LiteralPath $key -Name TesterRole -PropertyType String -Value $role -Force | Out-Null
    Write-Host "Setup complete for tester $role. Launch the game to write to this Desktop log:"
    Write-Host $logPath
    exit 0
} catch {
    Write-Host "SETUP FAILED: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
