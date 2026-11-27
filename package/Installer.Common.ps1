# Shared by the install/uninstall entry points. Windows PowerShell 5.1 compatible.
Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'

function Initialize-DideTesterDesktop([string]$Desktop,[string]$ConfigTemplate) {
    if(-not $Desktop -or -not [IO.Directory]::Exists($Desktop)) { throw 'Windows did not provide an accessible Desktop folder.' }
    $probe=Join-Path $Desktop ('BanoiTogether-'+[guid]::NewGuid().ToString('N')+'.tmp')
    [IO.FileStream]::new($probe,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None,4096,[IO.FileOptions]::DeleteOnClose).Dispose()
    $config=Join-Path $Desktop 'BanoiTogether.yaml'
    if(-not (Test-Path -LiteralPath $config)) {
        [IO.File]::Copy($ConfigTemplate,$config,$false)
    }
    return $config
}

function Get-DideFullPath([string]$Path) {
    return [IO.Path]::GetFullPath($Path).TrimEnd('\','/')
}
function Assert-DideNoLinks([string]$Path) {
    $probe=[IO.Path]::GetFullPath($Path)
    while($probe) {
        if(Test-Path -LiteralPath $probe) {
            $item=Get-Item -LiteralPath $probe -Force
            if($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "Filesystem link/reparse point is not supported: $probe" }
        }
        $parent=Split-Path -Path $probe -Parent
        if($parent -eq $probe) { break }
        $probe=$parent
    }
}
function Get-DideBytesHash([byte[]]$Bytes) {
    $hasher=[Security.Cryptography.SHA256]::Create()
    try { return [BitConverter]::ToString($hasher.ComputeHash($Bytes)).Replace('-','') }
    finally { $hasher.Dispose() }
}
function Get-DideHash([string]$Path) {
    # Avoid PS 5.1 Get-FileHash's inherited WhatIf behavior on first use.
    $stream=[IO.File]::OpenRead($Path)
    $hasher=[Security.Cryptography.SHA256]::Create()
    try { return [BitConverter]::ToString($hasher.ComputeHash($stream)).Replace('-','') }
    finally { $hasher.Dispose(); $stream.Dispose() }
}
function ConvertFrom-DideVdfString([string]$Value) { return [regex]::Replace($Value,'\\([\\"])','$1') }
function Get-DideVdfValue([string]$Text,[string]$Name) {
    $match=[regex]::Match($Text,'"'+[regex]::Escape($Name)+'"\s*"((?:\\.|[^"\\])*)"',[Text.RegularExpressions.RegexOptions]::IgnoreCase)
    if($match.Success) { return ConvertFrom-DideVdfString $match.Groups[1].Value }
    return ''
}
function Get-DideSteamRoots {
    $roots=@()
    foreach($entry in @(@('HKCU:\Software\Valve\Steam','SteamPath'),@('HKLM:\SOFTWARE\WOW6432Node\Valve\Steam','InstallPath'),@('HKLM:\SOFTWARE\Valve\Steam','InstallPath'))) {
        if(Test-Path -LiteralPath $entry[0]) {
            $value=Get-ItemPropertyValue -LiteralPath $entry[0] -Name $entry[1] -ErrorAction SilentlyContinue
            if($value) { $roots += [string]$value }
        }
    }
    if(${env:ProgramFiles(x86)}) { $roots += Join-Path ${env:ProgramFiles(x86)} 'Steam' }
    if($env:ProgramFiles) { $roots += Join-Path $env:ProgramFiles 'Steam' }
    return $roots | Select-Object -Unique
}
function Find-DideInstallations([string[]]$SteamRoots) {
    $libraries=@{}
    foreach($root in $SteamRoots) {
        if(-not $root -or -not (Test-Path -LiteralPath $root -PathType Container)) { continue }
        $libraries[(Get-DideFullPath $root)]=$true
        $file=Join-Path $root 'steamapps\libraryfolders.vdf'
        if(Test-Path -LiteralPath $file -PathType Leaf) {
            $text=Get-Content -LiteralPath $file -Raw
            # Supports modern "path" entries and older numeric-key library paths.
            foreach($match in [regex]::Matches($text,'"(?:path|\d+)"\s*"((?:\\.|[^"\\])*)"',[Text.RegularExpressions.RegexOptions]::IgnoreCase)) {
                $path=ConvertFrom-DideVdfString $match.Groups[1].Value
                if([IO.Path]::IsPathRooted($path) -and (Test-Path -LiteralPath $path -PathType Container)) {
                    $libraries[(Get-DideFullPath $path)]=$true
                }
            }
        }
    }
    $found=@{}
    foreach($library in $libraries.Keys) {
        $manifest=Join-Path $library 'steamapps\appmanifest_383150.acf'
        if(-not (Test-Path -LiteralPath $manifest -PathType Leaf)) { continue }
        $text=Get-Content -LiteralPath $manifest -Raw
        if((Get-DideVdfValue $text 'appid') -ne '383150') { continue }
        $dir=Get-DideVdfValue $text 'installdir'
        if(-not $dir -or $dir -in @('.','..') -or $dir.IndexOfAny([char[]]'\/:') -ge 0 -or $dir.IndexOfAny([IO.Path]::GetInvalidFileNameChars()) -ge 0) { continue }
        $candidate=Join-Path $library ('steamapps\common\'+$dir)
        if(Test-Path -LiteralPath (Join-Path $candidate 'DeadIslandGame.exe') -PathType Leaf) {
            $found[(Get-DideFullPath $candidate)]=$true
        }
    }
    return $found.Keys | Sort-Object
}
function Resolve-DideGamePath([string]$GamePath,[string]$SteamPath) {
    if($GamePath) { return Get-DideFullPath $GamePath }
    if($SteamPath) { $roots=@($SteamPath) } else { $roots=@(Get-DideSteamRoots) }
    $candidates=@(Find-DideInstallations -SteamRoots $roots)
    if($candidates.Count -eq 0) { throw 'Dead Island Definitive Edition (Steam app 383150) was not found. Supply -GamePath with the folder containing DeadIslandGame.exe.' }
    if($candidates.Count -gt 1) { throw ('Multiple installations found. Supply -GamePath to choose one: '+($candidates -join '; ')) }
    return $candidates[0]
}
function Read-DidePackage([string]$PackagePath) {
    $manifestPath=Join-Path $PackagePath 'version.json'
    $metadata=Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
    if($metadata.product -ne 'DIDE-CoopQuestActivity' -or $metadata.schemaVersion -ne 1 -or [string]$metadata.appId -ne '383150' -or
       $metadata.version -notmatch '^\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?$' -or
       $metadata.file.name -cne 'xinput1_3.dll' -or $metadata.file.sha256 -notmatch '^[0-9A-Fa-f]{64}$') {
        throw 'Invalid package metadata or payload name. Extract the entire release ZIP again.'
    }
    $binaryNames=@($metadata.supportedBinaries.PSObject.Properties.Name | Sort-Object)
    if(($binaryNames -join '|') -cne 'engine_x64_rwdi.dll|gamedll_x64_rwdi.dll') { throw 'Invalid supported native-binary list in package.' }
    foreach($name in $binaryNames) {
        if($metadata.supportedBinaries.$name -notmatch '^[0-9A-Fa-f]{64}$') { throw "Invalid native fingerprint for $name" }
    }
    $payload=Join-Path $PackagePath 'xinput1_3.dll'
    Assert-DideNoLinks $payload
    if(-not (Test-Path -LiteralPath $payload -PathType Leaf) -or (Get-DideHash $payload) -ne $metadata.file.sha256) {
        throw 'Missing or corrupt payload DLL. Extract the entire release ZIP again.'
    }
    return $metadata
}
function Assert-DideGame([string]$GamePath,$Metadata) {
    Assert-DideNoLinks $GamePath
    foreach($name in @('DeadIslandGame.exe','gamedll_x64_rwdi.dll','engine_x64_rwdi.dll','DI\Data0.pak','DI\Data1.pak','DI\Data2.pak')) {
        $path=Join-Path $GamePath $name
        Assert-DideNoLinks $path
        if(-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Required game file is missing: $path" }
    }
    $exe=[IO.File]::ReadAllBytes((Join-Path $GamePath 'DeadIslandGame.exe'))
    if($exe.Length -lt 64 -or $exe[0] -ne 77 -or $exe[1] -ne 90) { throw 'Unsupported executable: expected the x64 Definitive Edition.' }
    $offset=[BitConverter]::ToUInt32($exe,60)
    if($offset -gt $exe.Length-6 -or [BitConverter]::ToUInt32($exe,[int]$offset) -ne 0x4550 -or [BitConverter]::ToUInt16($exe,[int]$offset+4) -ne 0x8664) {
        throw 'Unsupported executable: expected the x64 Definitive Edition.'
    }
    foreach($name in @('gamedll_x64_rwdi.dll','engine_x64_rwdi.dll')) {
        if((Get-DideHash (Join-Path $GamePath $name)) -ne $Metadata.supportedBinaries.$name) {
            throw "Unsupported game build: $name does not match this test build. No files were installed."
        }
    }
}
function Test-DideGameRunning([string]$GamePath) {
    $expected=Join-Path $GamePath 'DeadIslandGame.exe'
    foreach($process in @(Get-Process -Name DeadIslandGame -ErrorAction SilentlyContinue)) {
        try { $path=$process.Path } catch { throw 'Cannot inspect the running game. Close Dead Island before installing or uninstalling.' }
        if(-not $path -or $path -ieq $expected) { return $true }
    }
    return $false
}
function Read-DideReceipt([string]$GamePath) {
    $path=Join-Path $GamePath 'DIDE-CoopQuestActivity.install.json'
    Assert-DideNoLinks $path
    if(-not (Test-Path -LiteralPath $path)) { return $null }
    try {
        $receipt=Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
        if($receipt.product -ne 'DIDE-CoopQuestActivity' -or $receipt.schemaVersion -ne 1 -or
           $receipt.file.name -cne 'xinput1_3.dll' -or $receipt.file.sha256 -notmatch '^[0-9A-Fa-f]{64}$') { throw 'Invalid ownership data' }
        return $receipt
    } catch { throw "Unrecognized or damaged ownership receipt: $path. Refusing to change it." }
}
function Enter-DideInstallLock([string]$GamePath) {
    $hasher=[Security.Cryptography.SHA256]::Create()
    try { $hash=[BitConverter]::ToString($hasher.ComputeHash([Text.Encoding]::UTF8.GetBytes($GamePath.ToLowerInvariant()))).Replace('-','') }
    finally { $hasher.Dispose() }
    $mutex=[Threading.Mutex]::new($false,'Local\DIDECoopQuestActivity-'+$hash)
    try { $acquired=$mutex.WaitOne(0) } catch [Threading.AbandonedMutexException] { $acquired=$true }
    if(-not $acquired) { $mutex.Dispose(); throw 'Another install/uninstall is already running for this game folder.' }
    return $mutex
}
function Write-DideAtomicFile([string]$Path,[byte[]]$Bytes) {
    Assert-DideNoLinks $Path
    $temp=Join-Path (Split-Path $Path -Parent) ('.dide-'+[guid]::NewGuid().ToString('N')+'.tmp')
    try {
        $stream=[IO.File]::Open($temp,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
        try { $stream.Write($Bytes,0,$Bytes.Length); $stream.Flush($true) } finally { $stream.Dispose() }
        if(Test-Path -LiteralPath $Path) { [IO.File]::Replace($temp,$Path,[System.Management.Automation.Language.NullString]::Value) }
        else { [IO.File]::Move($temp,$Path) }
    } finally { if(Test-Path -LiteralPath $temp) { [IO.File]::Delete($temp) } }
}
function New-DideResult([string]$Status,[string]$GamePath,[string]$Version='') {
    return [pscustomobject]@{Status=$Status; GamePath=$GamePath; Version=$Version}
}
function New-DideBackup([byte[]]$Bytes) {
    if($null -eq $Bytes) { return $null }
    return @{data=[Convert]::ToBase64String($Bytes); sha256=(Get-DideBytesHash $Bytes)}
}
function Repair-DideInterruptedInstall([string]$GamePath) {
    # Caller holds the install lock. The durable journal is removed last;
    # restoration is idempotent even if this recovery is interrupted too.
    $journalPath=Join-Path $GamePath 'DIDE-CoopQuestActivity.install.pending.json'
    Assert-DideNoLinks $journalPath
    if(-not (Test-Path -LiteralPath $journalPath)) { return }
    if($WhatIfPreference) { throw 'An interrupted installation needs recovery. Rerun without -WhatIf.' }
    try {
        $journal=Get-Content -LiteralPath $journalPath -Raw | ConvertFrom-Json
        if($journal.product -ne 'DIDE-CoopQuestActivity' -or $journal.schemaVersion -ne 1) { throw 'Wrong journal identity' }
        $restores=@()
        foreach($entry in @(@('xinput1_3.dll','dll'),@('DIDE-CoopQuestActivity.install.json','receipt'))) {
            $path=Join-Path $GamePath $entry[0]
            Assert-DideNoLinks $path
            $record=$journal.($entry[1])
            if($record.afterHash -notmatch '^[0-9A-Fa-f]{64}$') { throw 'Invalid pending hash' }
            $bytes=$null; $beforeHash=''
            if($null -ne $record.before) {
                $bytes=[Convert]::FromBase64String($record.before.data)
                $beforeHash=Get-DideBytesHash $bytes
                if($beforeHash -ne $record.before.sha256) { throw 'Damaged recovery backup' }
            }
            $current=''
            if(Test-Path -LiteralPath $path) {
                $current=Get-DideHash $path
                if($current -ne $record.afterHash -and $current -ne $beforeHash) { throw "Recovery conflict: $($entry[0]) changed outside the installer" }
            }
            if($current -ne $beforeHash) { $restores+=@{Path=$path; Bytes=$bytes} }
        }
    } catch { throw "Unrecognized or damaged pending installation; no files restored: $($_.Exception.Message)" }
    foreach($restore in $restores) {
        if($null -ne $restore.Bytes) { Write-DideAtomicFile $restore.Path $restore.Bytes }
        elseif(Test-Path -LiteralPath $restore.Path) { [IO.File]::Delete($restore.Path) }
    }
    [IO.File]::Delete($journalPath)
    Write-Host 'Recovered the previous installation after an interrupted install.'
}
function Install-DidePackage {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param([Parameter(Mandatory=$true)][string]$PackagePath,[Parameter(Mandatory=$true)][string]$GamePath)
    $GamePath=Get-DideFullPath $GamePath
    $metadata=Read-DidePackage $PackagePath
    Assert-DideGame $GamePath $metadata
    if(Test-DideGameRunning $GamePath) { throw 'The game is running. Close it before installing.' }
    $mutex=Enter-DideInstallLock $GamePath
    try {
        Repair-DideInterruptedInstall $GamePath
        $target=Join-Path $GamePath 'xinput1_3.dll'
        $receiptPath=Join-Path $GamePath 'DIDE-CoopQuestActivity.install.json'
        Assert-DideNoLinks $target
        $receipt=Read-DideReceipt $GamePath
        $existing=Test-Path -LiteralPath $target
        $existingHash=''
        if($existing) {
            $existingHash=Get-DideHash $target
            if($existingHash -ne $metadata.file.sha256 -and
               (-not $receipt -or $existingHash -ne $receipt.file.sha256) -and
               $existingHash -notin @($metadata.legacyHashes)) {
                throw 'Proxy DLL conflict: an unrecognized or modified xinput1_3.dll is already installed. It was not overwritten.'
            }
        }
        if($receipt -and $existingHash -eq $metadata.file.sha256 -and $receipt.file.sha256 -eq $metadata.file.sha256 -and $receipt.version -eq $metadata.version) {
            return New-DideResult 'AlreadyInstalled' $GamePath $metadata.version
        }
        if(-not $PSCmdlet.ShouldProcess($GamePath,'Install DIDE-CoopQuestActivity '+$metadata.version)) { return New-DideResult 'WhatIf' $GamePath $metadata.version }
        $oldDll=$null; $oldReceipt=$null
        if($existing) { $oldDll=[IO.File]::ReadAllBytes($target) }
        if($receipt) { $oldReceipt=[IO.File]::ReadAllBytes($receiptPath) }
        $newReceipt=[ordered]@{product='DIDE-CoopQuestActivity'; schemaVersion=1; version=$metadata.version; file=[ordered]@{name='xinput1_3.dll'; sha256=$metadata.file.sha256}}
        $receiptBytes=[Text.UTF8Encoding]::new($false).GetBytes(($newReceipt | ConvertTo-Json -Depth 5))
        $journalPath=Join-Path $GamePath 'DIDE-CoopQuestActivity.install.pending.json'
        $journal=@{product='DIDE-CoopQuestActivity'; schemaVersion=1
            dll=@{before=(New-DideBackup $oldDll); afterHash=$metadata.file.sha256}
            receipt=@{before=(New-DideBackup $oldReceipt); afterHash=(Get-DideBytesHash $receiptBytes)}}
        try {
            Write-DideAtomicFile $journalPath ([Text.UTF8Encoding]::new($false).GetBytes(($journal | ConvertTo-Json -Depth 6)))
            Write-DideAtomicFile $target ([IO.File]::ReadAllBytes((Join-Path $PackagePath 'xinput1_3.dll')))
            Write-DideAtomicFile $receiptPath $receiptBytes
            if((Get-DideHash $target) -ne $metadata.file.sha256) { throw 'Installed DLL failed final SHA256 verification.' }
            [IO.File]::Delete($journalPath)
        } catch {
            $failure=$_
            try {
                Repair-DideInterruptedInstall $GamePath
            } catch { throw "Installation failed: $($failure.Exception.Message). Rollback also failed: $($_.Exception.Message)" }
            throw $failure
        }
        return New-DideResult 'Installed' $GamePath $metadata.version
    } finally { $mutex.ReleaseMutex(); $mutex.Dispose() }
}
function Uninstall-DidePackage {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param([Parameter(Mandatory=$true)][string]$GamePath)
    $GamePath=Get-DideFullPath $GamePath
    Assert-DideNoLinks $GamePath
    if(Test-DideGameRunning $GamePath) { throw 'The game is running. Close it before uninstalling.' }
    $mutex=Enter-DideInstallLock $GamePath
    try {
        Repair-DideInterruptedInstall $GamePath
        $target=Join-Path $GamePath 'xinput1_3.dll'
        $receiptPath=Join-Path $GamePath 'DIDE-CoopQuestActivity.install.json'
        Assert-DideNoLinks $target
        $receipt=Read-DideReceipt $GamePath
        if(-not $receipt) {
            if(Test-Path -LiteralPath $target) { throw 'No ownership receipt for the existing proxy. Refusing to remove an unrecognized DLL. Run the matching installer to adopt a known manual install first.' }
            return New-DideResult 'NotInstalled' $GamePath
        }
        $exists=Test-Path -LiteralPath $target
        if($exists -and (Get-DideHash $target) -ne $receipt.file.sha256) { throw 'The installed DLL was modified. Refusing to remove it.' }
        if(-not $PSCmdlet.ShouldProcess($GamePath,'Remove the owned DIDE-CoopQuestActivity DLL and receipt')) { return New-DideResult 'WhatIf' $GamePath $receipt.version }
        $oldDll=$null
        if($exists) { $oldDll=[IO.File]::ReadAllBytes($target) }
        try {
            if($exists) { [IO.File]::Delete($target) }
            [IO.File]::Delete($receiptPath)
        } catch {
            $failure=$_
            if($null -ne $oldDll -and -not (Test-Path -LiteralPath $target)) { Write-DideAtomicFile $target $oldDll }
            throw $failure
        }
        return New-DideResult 'Uninstalled' $GamePath $receipt.version
    } finally { $mutex.ReleaseMutex(); $mutex.Dispose() }
}
function Invoke-DideElevatedRetry([string]$ScriptPath,[string]$GamePath) {
    # Valid Windows paths cannot contain double quotes. Pass -File arguments,
    # never executable PowerShell source containing user-controlled paths.
    if($ScriptPath.Contains('"') -or $GamePath.Contains('"')) { throw 'Invalid path for elevation.' }
    $powerShell=Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
    $arguments='-NoLogo -NoProfile -ExecutionPolicy Bypass -File "'+$ScriptPath+'" -GamePath "'+$GamePath.TrimEnd('\')+'" -Elevated'
    $process=Start-Process -FilePath $powerShell -ArgumentList $arguments -Verb RunAs -Wait -PassThru
    return $process.ExitCode
}
