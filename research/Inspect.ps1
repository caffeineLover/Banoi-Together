param([string[]]$Names=@('MenuAcceptQuest','B_Accept','G_QuestName','net_chat_message'),[string]$Module='gamedll_x64_rwdi.dll')
$ErrorActionPreference='Stop'
Add-Type -Path (Join-Path $PSScriptRoot 'PeImage.cs')
$imagePath=Join-Path 'C:\Program Files (x86)\Steam\steamapps\common\DIDE' $Module
$pe=[PeImage]::new($imagePath)
'Image {0} base=0x{1:X} functions={2}' -f $Module,$pe.Base,$pe.Functions.Count
foreach($name in $Names) {
    foreach($rva in $pe.FindString($name)) {
        'String "{0}" RVA=0x{1:X8}' -f $name,$rva
        $pe.RipReferences($rva) | ForEach-Object { $_.ToString() }
    }
}
