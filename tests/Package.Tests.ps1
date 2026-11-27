[CmdletBinding()]
param([string]$Version='0.1.0-test.5')
$ErrorActionPreference='Stop'
$repo=Split-Path $PSScriptRoot -Parent
$builder=Join-Path $repo 'tools\Build-Package.ps1'
if(-not (Test-Path -LiteralPath $builder)) { throw 'Package builder is missing (expected initial RED).' }
& $builder -Version $Version
$zipPath=Join-Path $repo "dist\DIDE-CoopQuestActivity-v$Version.zip"
Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive=[IO.Compression.ZipFile]::OpenRead($zipPath)
try {
    $support='Support - Do Not Run/'
    $expected=(@('Setup Banoi Together.cmd','LICENSE','README.md') + @('Setup.ps1','Install.ps1','Installer.Common.ps1','Uninstall.ps1','BanoiTogether.yaml','version.json','xinput1_3.dll' | ForEach-Object { $support+$_ })) | Sort-Object
    $actual=@($archive.Entries | ForEach-Object { $_.FullName.Replace('\','/') }) | Sort-Object
    if(($actual -join '|') -cne ($expected -join '|')) { throw ('Unexpected ZIP content: '+($actual -join ', ')) }
    $reader=[IO.StreamReader]::new(($archive.Entries | Where-Object { $_.FullName.Replace('\','/') -ceq ($support+'version.json') }).Open())
    try { $metadata=$reader.ReadToEnd() | ConvertFrom-Json } finally { $reader.Dispose() }
    if($metadata.version -ne $Version) { throw 'Wrong version in package' }
    $payload=($archive.Entries | Where-Object { $_.FullName.Replace('\','/') -ceq ($support+'xinput1_3.dll') }).Open()
    $hasher=[Security.Cryptography.SHA256]::Create()
    try { $hash=[BitConverter]::ToString($hasher.ComputeHash($payload)).Replace('-','') }
    finally { $hasher.Dispose(); $payload.Dispose() }
    if($hash -ne $metadata.file.sha256) { throw 'Packaged DLL does not match generated manifest' }
    if($hash -ne (Get-FileHash -LiteralPath (Join-Path $repo 'poc\build\xinput1_3.dll')).Hash) { throw 'ZIP changed the compiled payload' }
} finally { $archive.Dispose() }
$checksum=(Get-Content -LiteralPath ($zipPath+'.sha256') -Raw).Trim()
if(-not $checksum.StartsWith((Get-FileHash -LiteralPath $zipPath).Hash)) { throw 'ZIP checksum mismatch' }
$extract=Join-Path $repo ('tests\.tmp\extracted-'+[guid]::NewGuid().ToString('N'))
[IO.Compression.ZipFile]::ExtractToDirectory($zipPath,$extract)
try {
    $config=Get-Content -LiteralPath (Join-Path $extract 'Support - Do Not Run\BanoiTogether.yaml') -Raw
    if($config -notmatch '(?m)^fullscreen_key: F11\s*$') { throw 'Missing default F11 shortcut' }
    $cancel='Q' | & (Join-Path $extract 'Setup Banoi Together.cmd')
    if($LASTEXITCODE -ne 0 -or ($cancel -join ' ') -notmatch 'Install or upgrade.*Uninstall.*Quit') { throw 'Setup menu did not open and exit cleanly' }
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'Installer.Tests.ps1') -ExtractedPackage (Join-Path $extract 'Support - Do Not Run')
    if($LASTEXITCODE -ne 0) { throw 'Extracted-package installer integration tests failed' }
} finally {
    $allowed=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '.tmp')).TrimEnd('\')+'\'
    if(-not ([IO.Path]::GetFullPath($extract)).StartsWith($allowed,[StringComparison]::OrdinalIgnoreCase)) { throw 'Unsafe extraction cleanup path' }
    Remove-Item -LiteralPath $extract -Recurse -Force
}
Write-Host 'PASS curated ZIP entries, metadata version, DLL identity, ZIP checksum and extracted-package install/uninstall'
