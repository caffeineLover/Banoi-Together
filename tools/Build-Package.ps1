[CmdletBinding()]
param([string]$Version='0.1.0-test.2',[string]$DllPath,[string]$OutputDirectory)
$ErrorActionPreference='Stop'
$repo=Split-Path $PSScriptRoot -Parent
if($Version -notmatch '^\d+\.\d+\.\d+-test(?:\.\d+)?$') { throw 'Use a test version such as 0.1.0-test.1.' }
if(-not $DllPath) { $DllPath=Join-Path $repo 'poc\build\xinput1_3.dll' }
if(-not $OutputDirectory) { $OutputDirectory=Join-Path $repo 'dist' }
$DllPath=[IO.Path]::GetFullPath($DllPath)
$OutputDirectory=[IO.Path]::GetFullPath($OutputDirectory)
if(-not (Test-Path -LiteralPath $DllPath -PathType Leaf)) { throw 'Build the native DLL with poc\build.cmd first.' }
[IO.Directory]::CreateDirectory($OutputDirectory) | Out-Null
$stage=Join-Path $OutputDirectory ('stage-'+[guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory($stage) | Out-Null
try {
    $template=Join-Path $repo 'package'
    foreach($name in @('Install.ps1','Uninstall.ps1','Installer.Common.ps1','Install.cmd','Uninstall.cmd')) {
        Copy-Item -LiteralPath (Join-Path $template $name) -Destination (Join-Path $stage $name)
    }
    foreach($name in @('README.md','LICENSE')) { Copy-Item -LiteralPath (Join-Path $repo $name) -Destination (Join-Path $stage $name) }
    Copy-Item -LiteralPath $DllPath -Destination (Join-Path $stage 'xinput1_3.dll')
    $metadata=Get-Content -LiteralPath (Join-Path $template 'version.json') -Raw | ConvertFrom-Json
    $nativeSource=Get-Content -LiteralPath (Join-Path $repo 'poc\quest_chat.cpp') -Raw
    foreach($name in @('gamedll_x64_rwdi.dll','engine_x64_rwdi.dll')) {
        if(-not $nativeSource.Contains($metadata.supportedBinaries.$name)) { throw "Package native fingerprint differs from DLL source: $name" }
    }
    $metadata.version=$Version
    $metadata.file.sha256=(Get-FileHash -LiteralPath $DllPath -Algorithm SHA256).Hash
    $metadata | Add-Member -NotePropertyName nativeSourceSha256 -NotePropertyValue (Get-FileHash -LiteralPath (Join-Path $repo 'poc\quest_chat.cpp') -Algorithm SHA256).Hash
    if($env:GITHUB_SHA) { $metadata | Add-Member -NotePropertyName sourceCommit -NotePropertyValue $env:GITHUB_SHA }
    [IO.File]::WriteAllText((Join-Path $stage 'version.json'),($metadata | ConvertTo-Json -Depth 6),[Text.UTF8Encoding]::new($false))
    . (Join-Path $stage 'Installer.Common.ps1')
    Read-DidePackage $stage | Out-Null
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip=Join-Path $OutputDirectory "DIDE-CoopQuestActivity-v$Version.zip"
    # Write a new file first, then replace only this named build output.
    $newZip=Join-Path $OutputDirectory ([guid]::NewGuid().ToString('N')+'.zip')
    try {
        [IO.Compression.ZipFile]::CreateFromDirectory($stage,$newZip,[IO.Compression.CompressionLevel]::Optimal,$false)
        Move-Item -LiteralPath $newZip -Destination $zip -Force
    } finally { if(Test-Path -LiteralPath $newZip) { Remove-Item -LiteralPath $newZip -Force } }
    $digest=(Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash
    [IO.File]::WriteAllText(($zip+'.sha256'),($digest+'  '+[IO.Path]::GetFileName($zip)+[Environment]::NewLine),[Text.UTF8Encoding]::new($false))
    Write-Host "Package: $zip"
    Write-Host "DLL SHA256: $($metadata.file.sha256)"
    Write-Host "ZIP SHA256: $digest"
} finally {
    $allowed=$OutputDirectory.TrimEnd('\')+'\'
    if(-not ([IO.Path]::GetFullPath($stage)).StartsWith($allowed,[StringComparison]::OrdinalIgnoreCase)) { throw 'Unsafe package-stage cleanup path' }
    Remove-Item -LiteralPath $stage -Recurse -Force
}
