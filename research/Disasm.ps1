param([Parameter(Mandatory=$true)][uint32]$Start,[uint32]$End=0,[string]$Module='gamedll_x64_rwdi.dll')
$ErrorActionPreference='Stop'
Add-Type -Path (Join-Path $PSScriptRoot 'PeImage.cs')
$imagePath=Join-Path 'C:\Program Files (x86)\Steam\steamapps\common\DIDE' $Module
$pe=[PeImage]::new($imagePath)
if($End -eq 0) { $f=$pe.Containing($Start); if($null -eq $f) { throw 'No runtime function entry' }; $Start=$f.Start; $End=$f.End }
$range='/range:0x{0:X},0x{1:X}' -f ($pe.Base+$Start),($pe.Base+$End)
& 'C:\BuildTools2026\VC\Tools\MSVC\14.52.37025\bin\Hostx64\x64\dumpbin.exe' /nologo /disasm:nobytes $range $imagePath | ForEach-Object {
    $line=$_
    if($line -match '\[(?<address>[0-9A-F]{16})h\]') {
        $rva=[uint32]([Convert]::ToUInt64($Matches.address,16)-$pe.Base)
        if($pe.Imports.ContainsKey($rva)) { $line+=' ; '+$pe.Imports[$rva] }
        else { try { $str=$pe.Ascii($rva); if($str.Length -ge 3 -and $str -match '^[ -~]+$') { $line+=' ; "'+$str+'"' } } catch {} }
    }
    $line
}
