[CmdletBinding()]
param([string]$ExtractedPackage)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2
$repo = Split-Path $PSScriptRoot -Parent
$common = Join-Path $repo 'package\Installer.Common.ps1'
if ($ExtractedPackage) { $common = Join-Path $ExtractedPackage 'Installer.Common.ps1' }
if (-not (Test-Path -LiteralPath $common)) { throw 'Installer implementation is missing (expected initial RED).' }
. $common
$testParent = Join-Path $PSScriptRoot '.tmp'
$testRoot = Join-Path $testParent ([guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory($testRoot) | Out-Null
$script:passed = 0
$script:failed = 0
$script:fixtureIndex = 0
$script:runningFixture = $false
$script:fixtureLinks = @()

# Mock only the OS process query; all filesystem/discovery behavior is real.
function Test-DideGameRunning { param([string]$GamePath) return $script:runningFixture }
function Assert-Equal($Actual, $Expected, [string]$Message) {
    if ($Actual -cne $Expected) { throw "$Message : expected [$Expected], got [$Actual]" }
}
function Assert-Throws([scriptblock]$Action, [string]$Pattern) {
    try { & $Action | Out-Null } catch {
        if ($_.Exception.Message -notmatch $Pattern) { throw "Wrong failure: $($_.Exception.Message)" }
        return
    }
    throw "Expected a failure matching $Pattern"
}
function Test-Case([string]$Name, [scriptblock]$Action) {
    try { & $Action; $script:passed++; Write-Host "PASS $Name" }
    catch { $script:failed++; Write-Host "FAIL $Name : $($_.Exception.Message)" }
    finally { $script:runningFixture = $false }
}
function Write-TestText([string]$Path, [string]$Value) {
    [IO.Directory]::CreateDirectory((Split-Path $Path -Parent)) | Out-Null
    [IO.File]::WriteAllText($Path, $Value, [Text.UTF8Encoding]::new($false))
}
function New-Fixture {
    $script:fixtureIndex++
    $base = Join-Path $testRoot "case$script:fixtureIndex"
    $steam = Join-Path $base 'Steam Root'
    $library = Join-Path $base "Other Library's games"
    $game = Join-Path $library 'steamapps\common\DIDE'
    $package = Join-Path $base 'package'
    [IO.Directory]::CreateDirectory($game) | Out-Null
    [byte[]]$exe = New-Object byte[] 128
    $exe[0]=77; $exe[1]=90; $exe[60]=64; $exe[64]=80; $exe[65]=69; $exe[68]=100; $exe[69]=134
    [IO.File]::WriteAllBytes((Join-Path $game 'DeadIslandGame.exe'),$exe)
    Write-TestText (Join-Path $game 'gamedll_x64_rwdi.dll') 'fake game module for installer tests'
    Write-TestText (Join-Path $game 'engine_x64_rwdi.dll') 'fake engine module for installer tests'
    foreach ($n in 0..2) { Write-TestText (Join-Path $game "DI\Data$n.pak") "protected sentinel $n" }
    Write-TestText (Join-Path $package 'xinput1_3.dll') 'test observer payload'
    $meta = [ordered]@{
        product='DIDE-CoopQuestActivity'; schemaVersion=1; version='0.1.0-test'; appId='383150'
        file=[ordered]@{name='xinput1_3.dll'; sha256=(Get-FileHash (Join-Path $package 'xinput1_3.dll')).Hash}
        supportedBinaries=[ordered]@{
            'gamedll_x64_rwdi.dll'=(Get-FileHash (Join-Path $game 'gamedll_x64_rwdi.dll')).Hash
            'engine_x64_rwdi.dll'=(Get-FileHash (Join-Path $game 'engine_x64_rwdi.dll')).Hash
        }
        legacyHashes=@()
    }
    Write-TestText (Join-Path $package 'version.json') ($meta | ConvertTo-Json -Depth 6)
    $escaped = $library.Replace('\','\\')
    Write-TestText (Join-Path $steam 'steamapps\libraryfolders.vdf') ('"libraryfolders" { "0" { "path" "'+$escaped+'" "apps" { "383150" "123" } } }')
    Write-TestText (Join-Path $library 'steamapps\appmanifest_383150.acf') '"AppState" { "appid" "383150" "installdir" "DIDE" }'
    return [pscustomobject]@{Root=$base; Steam=$steam; Library=$library; Game=$game; Package=$package; Metadata=$meta}
}
function Snapshot-Game([string]$GamePath) {
    return ((Get-ChildItem -LiteralPath $GamePath -File -Recurse | Sort-Object FullName | ForEach-Object {
        $_.FullName.Substring($GamePath.Length) + ':' + (Get-FileHash -LiteralPath $_.FullName).Hash
    }) -join '|')
}
function Copy-EntryPoints($Fixture) {
    foreach($name in @('Install.ps1','Uninstall.ps1','Installer.Common.ps1')) {
        Copy-Item -LiteralPath (Join-Path (Split-Path $common -Parent) $name) -Destination $Fixture.Package -Force
    }
}

try {
    Test-Case 'discovers secondary Steam library with spaces/apostrophe' {
        $f=New-Fixture
        $found=@(Find-DideInstallations -SteamRoots @($f.Steam))
        Assert-Equal $found.Count 1 'installation count'
        Assert-Equal $found[0] $f.Game 'discovered game'
        Assert-Equal (Resolve-DideGamePath -SteamPath $f.Steam) $f.Game 'resolved path'
    }
    Test-Case 'legacy library format and duplicate library references' {
        $f=New-Fixture; $escaped=$f.Library.Replace('\','\\')
        Write-TestText (Join-Path $f.Steam 'steamapps\libraryfolders.vdf') ('"LibraryFolders" { "1" "'+$escaped+'" "2" "'+$escaped+'" }')
        Assert-Equal (@(Find-DideInstallations -SteamRoots @($f.Steam))).Count 1 'deduplicated count'
    }
    Test-Case 'refuses absent, wrong-app and escaping manifests' {
        $f=New-Fixture
        foreach($body in @('"AppState" { "appid" "999" "installdir" "DIDE" }','"AppState" { "appid" "383150" "installdir" "..\\outside" }')) {
            Write-TestText (Join-Path $f.Library 'steamapps\appmanifest_383150.acf') $body
            Assert-Equal (@(Find-DideInstallations -SteamRoots @($f.Steam))).Count 0 'invalid manifest count'
        }
        Assert-Throws { Resolve-DideGamePath -SteamPath $f.Steam } 'not found'
    }
    Test-Case 'multiple installations require an explicit game path' {
        $f=New-Fixture; $g=New-Fixture
        $one=$f.Library.Replace('\','\\'); $two=$g.Library.Replace('\','\\')
        Write-TestText (Join-Path $f.Steam 'steamapps\libraryfolders.vdf') ('"libraryfolders" { "0" { "path" "'+$one+'" } "1" { "path" "'+$two+'" } }')
        Assert-Throws { Resolve-DideGamePath -SteamPath $f.Steam } 'multiple'
    }
    Test-Case 'install, idempotent rerun and uninstall preserve original files' {
        $f=New-Fixture; $before=Snapshot-Game $f.Game
        Assert-Equal (Install-DidePackage -PackagePath $f.Package -GamePath $f.Game).Status 'Installed' 'install status'
        Assert-Equal (Install-DidePackage -PackagePath $f.Package -GamePath $f.Game).Status 'AlreadyInstalled' 'rerun status'
        Assert-Equal (Uninstall-DidePackage -GamePath $f.Game).Status 'Uninstalled' 'uninstall status'
        Assert-Equal (Snapshot-Game $f.Game) $before 'all original files unchanged'
        Assert-Equal (Uninstall-DidePackage -GamePath $f.Game).Status 'NotInstalled' 'second uninstall'
    }
    Test-Case 'owned upgrade succeeds and tracks the new payload' {
        $f=New-Fixture; Install-DidePackage -PackagePath $f.Package -GamePath $f.Game | Out-Null
        Write-TestText (Join-Path $f.Package 'xinput1_3.dll') 'new observer payload'
        $f.Metadata.version='0.1.0-test.2'; $f.Metadata.file.sha256=(Get-FileHash (Join-Path $f.Package 'xinput1_3.dll')).Hash
        Write-TestText (Join-Path $f.Package 'version.json') ($f.Metadata | ConvertTo-Json -Depth 6)
        Assert-Equal (Install-DidePackage -PackagePath $f.Package -GamePath $f.Game).Status 'Installed' 'upgrade status'
        Assert-Equal (Get-FileHash (Join-Path $f.Game 'xinput1_3.dll')).Hash $f.Metadata.file.sha256 'upgraded hash'
        Uninstall-DidePackage -GamePath $f.Game | Out-Null
    }
    Test-Case 'adopts an identical manual install or known diagnostic' {
        $f=New-Fixture
        Copy-Item -LiteralPath (Join-Path $f.Package 'xinput1_3.dll') -Destination $f.Game
        Install-DidePackage -PackagePath $f.Package -GamePath $f.Game | Out-Null
        Uninstall-DidePackage -GamePath $f.Game | Out-Null
        Write-TestText (Join-Path $f.Game 'xinput1_3.dll') 'known old diagnostic'
        $f.Metadata.legacyHashes=@((Get-FileHash (Join-Path $f.Game 'xinput1_3.dll')).Hash)
        Write-TestText (Join-Path $f.Package 'version.json') ($f.Metadata | ConvertTo-Json -Depth 6)
        Install-DidePackage -PackagePath $f.Package -GamePath $f.Game | Out-Null
        Uninstall-DidePackage -GamePath $f.Game | Out-Null
    }
    Test-Case 'unknown proxy is never overwritten or removed' {
        $f=New-Fixture; Write-TestText (Join-Path $f.Game 'xinput1_3.dll') 'another mod'
        $before=Snapshot-Game $f.Game
        Assert-Throws { Install-DidePackage -PackagePath $f.Package -GamePath $f.Game } 'conflict'
        Assert-Throws { Uninstall-DidePackage -GamePath $f.Game } 'ownership|unrecognized'
        Assert-Equal (Snapshot-Game $f.Game) $before 'conflicting proxy preserved'
    }
    Test-Case 'modified installed DLL and foreign receipt are refused' {
        $f=New-Fixture; Install-DidePackage -PackagePath $f.Package -GamePath $f.Game | Out-Null
        Write-TestText (Join-Path $f.Game 'xinput1_3.dll') 'changed after install'
        $before=Snapshot-Game $f.Game
        Assert-Throws { Uninstall-DidePackage -GamePath $f.Game } 'modified|conflict'
        Assert-Equal (Snapshot-Game $f.Game) $before 'modified proxy preserved'
        Write-TestText (Join-Path $f.Game 'DIDE-CoopQuestActivity.install.json') '{"product":"someone-else"}'
        $before=Snapshot-Game $f.Game
        Assert-Throws { Install-DidePackage -PackagePath $f.Package -GamePath $f.Game } 'receipt|ownership'
        Assert-Equal (Snapshot-Game $f.Game) $before 'foreign receipt preserved'
    }
    Test-Case 'wrong native build, x86 exe and corrupt payload make no writes' {
        foreach($kind in @('native','exe','payload')) {
            $f=New-Fixture
            if($kind -eq 'native') { Write-TestText (Join-Path $f.Game 'gamedll_x64_rwdi.dll') 'wrong game build' }
            if($kind -eq 'exe') { Write-TestText (Join-Path $f.Game 'DeadIslandGame.exe') 'not an x64 PE' }
            if($kind -eq 'payload') { Write-TestText (Join-Path $f.Package 'xinput1_3.dll') 'corrupt package' }
            $before=Snapshot-Game $f.Game
            Assert-Throws { Install-DidePackage -PackagePath $f.Package -GamePath $f.Game } 'unsupported|x64|payload'
            Assert-Equal (Snapshot-Game $f.Game) $before "$kind failure preserved game"
        }
    }
    Test-Case 'running game and WhatIf cause no writes' {
        $f=New-Fixture; $before=Snapshot-Game $f.Game
        $script:runningFixture=$true
        Assert-Throws { Install-DidePackage -PackagePath $f.Package -GamePath $f.Game } 'running|close'
        Assert-Throws { Uninstall-DidePackage -GamePath $f.Game } 'running|close'
        $script:runningFixture=$false
        Assert-Equal (Install-DidePackage -PackagePath $f.Package -GamePath $f.Game -WhatIf).Status 'WhatIf' 'dry run'
        Assert-Equal (Snapshot-Game $f.Game) $before 'no dry-run writes'
    }
    Test-Case 'receipt write failure rolls back a new install and upgrade' {
        $writer=(Get-Item Function:Write-DideAtomicFile).ScriptBlock
        try {
            foreach($upgrade in @($false,$true)) {
                $f=New-Fixture
                if($upgrade) { Install-DidePackage -PackagePath $f.Package -GamePath $f.Game | Out-Null }
                $before=Snapshot-Game $f.Game
                Write-TestText (Join-Path $f.Package 'xinput1_3.dll') 'replacement payload'
                $f.Metadata.file.sha256=(Get-FileHash (Join-Path $f.Package 'xinput1_3.dll')).Hash
                Write-TestText (Join-Path $f.Package 'version.json') ($f.Metadata | ConvertTo-Json -Depth 6)
                function Write-DideAtomicFile { param($Path,$Bytes)
                    if($Path -like '*.install.json') { throw 'injected receipt write failure' }
                    & $writer -Path $Path -Bytes $Bytes
                }
                Assert-Throws { Install-DidePackage -PackagePath $f.Package -GamePath $f.Game } 'injected receipt'
                Assert-Equal (Snapshot-Game $f.Game) $before 'rollback restored snapshot'
                Set-Item Function:Write-DideAtomicFile $writer
            }
        } finally { Set-Item Function:Write-DideAtomicFile $writer }
    }
    Test-Case 'junction game folder is refused without touching its target' {
        $f=New-Fixture; $link=Join-Path $f.Root 'LinkedGame'
        New-Item -ItemType Junction -Path $link -Target $f.Game | Out-Null
        $script:fixtureLinks += $link
        $before=Snapshot-Game $f.Game
        Assert-Throws { Install-DidePackage -PackagePath $f.Package -GamePath $link } 'link|reparse'
        Assert-Equal (Snapshot-Game $f.Game) $before 'junction target preserved'
    }
    Test-Case 'fresh-process WhatIf entry point validates without writes' {
        $f=New-Fixture; Copy-EntryPoints $f; $before=Snapshot-Game $f.Game
        $output=& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $f.Package 'Install.ps1') -GamePath $f.Game -WhatIf
        Assert-Equal $LASTEXITCODE 0 ('dry-run exit: '+($output -join ' '))
        if(($output -join ' ') -notmatch 'CHECK ONLY') { throw 'No dry-run result shown' }
        Assert-Equal (Snapshot-Game $f.Game) $before 'entry point did not write'
    }
    Test-Case 'original console reports elevated success and failure' {
        foreach($entry in @('Install','Uninstall')) {
            foreach($code in @(0,17)) {
                $f=New-Fixture; Copy-EntryPoints $f
                $mock="`r`nfunction $entry-DidePackage { throw [UnauthorizedAccessException]::new('fixture access denied') }`r`nfunction Invoke-DideElevatedRetry { return $code }`r`n"
                [IO.File]::AppendAllText((Join-Path $f.Package 'Installer.Common.ps1'),$mock)
                $output=& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $f.Package ($entry+'.ps1')) -GamePath $f.Game
                $actualExit=$LASTEXITCODE; $text=$output -join ' '
                if($code -eq 0) {
                    Assert-Equal $actualExit 0 'elevated success exit'
                    if($text -notmatch 'SUCCESS:.*elevated') { throw ('Missing original-console success: '+$text) }
                } else {
                    if($actualExit -eq 0 -or $text -notmatch 'FAILED:.*elevated.*17') { throw ('Missing elevated failure: '+$text) }
                }
            }
        }
    }
    Test-Case 'terminated upgrades recover previous files at either write boundary' {
        foreach($upgrade in @($false,$true)) {
          foreach($stopAfter in @('xinput1_3.dll','DIDE-CoopQuestActivity.install.json')) {
            $f=New-Fixture
            if($upgrade) { Install-DidePackage -PackagePath $f.Package -GamePath $f.Game | Out-Null }
            $before=Snapshot-Game $f.Game
            Write-TestText (Join-Path $f.Package 'xinput1_3.dll') 'interrupted upgrade payload'
            $f.Metadata.version='0.1.0-test.2'; $f.Metadata.file.sha256=(Get-FileHash (Join-Path $f.Package 'xinput1_3.dll')).Hash
            Write-TestText (Join-Path $f.Package 'version.json') ($f.Metadata | ConvertTo-Json -Depth 6)
            $harness=Join-Path $f.Root 'interrupt.ps1'
            Write-TestText $harness @'
param($Common,$Package,$Game,$StopAfter)
$ErrorActionPreference='Stop'
. $Common
$writer=(Get-Item Function:Write-DideAtomicFile).ScriptBlock
function Write-DideAtomicFile { param($Path,$Bytes)
    & $writer -Path $Path -Bytes $Bytes
    if([IO.Path]::GetFileName($Path) -eq $StopAfter) { [Diagnostics.Process]::GetCurrentProcess().Kill() }
}
Install-DidePackage -PackagePath $Package -GamePath $Game | Out-Null
'@
            & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $harness -Common $common -Package $f.Package -Game $f.Game -StopAfter $stopAfter
            if($LASTEXITCODE -eq 0) { throw 'Child was not terminated' }
            $interrupted=Snapshot-Game $f.Game
            Assert-Throws { Install-DidePackage -PackagePath $f.Package -GamePath $f.Game -WhatIf } 'interrupted'
            Assert-Equal (Snapshot-Game $f.Game) $interrupted 'dry run does not recover by writing'
            # A subsequent entry recovers under the normal per-install lock.
            $mutex=Enter-DideInstallLock $f.Game
            try { Repair-DideInterruptedInstall $f.Game } finally { $mutex.ReleaseMutex(); $mutex.Dispose() }
            Assert-Equal (Snapshot-Game $f.Game) $before 'durable recovery restored prior files'
            Uninstall-DidePackage -GamePath $f.Game | Out-Null
          }
        }
    }
    Test-Case 'unknown recovery journal is preserved and refused' {
        $f=New-Fixture
        Write-TestText (Join-Path $f.Game 'DIDE-CoopQuestActivity.install.pending.json') '{"product":"someone-else","schemaVersion":1}'
        $before=Snapshot-Game $f.Game
        Assert-Throws { Install-DidePackage -PackagePath $f.Package -GamePath $f.Game } 'pending|journal'
        Assert-Throws { Uninstall-DidePackage -GamePath $f.Game } 'pending|journal'
        Assert-Equal (Snapshot-Game $f.Game) $before 'unknown journal preserved'
    }
    if($ExtractedPackage) {
        Test-Case 'extracted real package installs and uninstalls without development tools' {
            $f=New-Fixture
            $real=Get-Content -Raw -LiteralPath (Join-Path $ExtractedPackage 'version.json') | ConvertFrom-Json
            $fixtureMeta=Get-Content -Raw -LiteralPath (Join-Path $f.Package 'version.json') | ConvertFrom-Json
            # Replace fixture native hashes only; retain the actual packaged DLL/hash/scripts.
            Copy-Item -LiteralPath (Join-Path $ExtractedPackage 'xinput1_3.dll') -Destination $f.Package -Force
            $fixtureMeta.file.sha256=$real.file.sha256
            Write-TestText (Join-Path $f.Package 'version.json') ($fixtureMeta | ConvertTo-Json -Depth 6)
            $before=Snapshot-Game $f.Game
            Install-DidePackage -PackagePath $f.Package -GamePath $f.Game | Out-Null
            Uninstall-DidePackage -GamePath $f.Game | Out-Null
            Assert-Equal (Snapshot-Game $f.Game) $before 'real payload fixture restored'
        }
    }
} finally {
    # Every target is created under this run's known workspace fixture root.
    foreach($link in $script:fixtureLinks) { [IO.Directory]::Delete($link) }
    $resolved=[IO.Path]::GetFullPath($testRoot)
    $allowed=[IO.Path]::GetFullPath($testParent).TrimEnd('\')+'\'
    if(-not $resolved.StartsWith($allowed,[StringComparison]::OrdinalIgnoreCase)) { throw 'Unsafe fixture cleanup path' }
    Remove-Item -LiteralPath $resolved -Recurse -Force
}
Write-Host "Installer tests: $script:passed passed, $script:failed failed"
if($script:failed) { exit 1 }
