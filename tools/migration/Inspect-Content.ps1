param(
    [string]$ContentRoot = 'C:\dev\fs2-content',
    [string[]]$MissionNames = @('SM1-01.fs2'),
    [string]$OutputPath
)
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $ContentRoot).Path
$inventory = [Collections.Generic.List[object]]::new()
foreach ($archive in Get-ChildItem -LiteralPath $root -Filter '*.vp' -File | Sort-Object Name) {
    $stream = [IO.File]::OpenRead($archive.FullName)
    $reader = [IO.BinaryReader]::new($stream)
    try {
        $magic = [Text.Encoding]::ASCII.GetString($reader.ReadBytes(4))
        $version = $reader.ReadInt32()
        $index = $reader.ReadInt32()
        $count = $reader.ReadInt32()
        if ($magic -ne 'VPVP' -or $version -ne 2 -or $index -lt 16 -or $count -lt 0 -or ($index + [long]$count * 44) -gt $stream.Length) {
            throw "Invalid/unsupported VP index: $($archive.FullName)"
        }
        $stream.Position = $index
        $dirs = [Collections.Generic.List[string]]::new()
        for ($i = 0; $i -lt $count; $i++) {
            $offset = $reader.ReadInt32()
            $size = $reader.ReadInt32()
            $name = [Text.Encoding]::ASCII.GetString($reader.ReadBytes(32)).Split([char]0)[0]
            $null = $reader.ReadInt32()
            if ($name -match '[/\\]' -or $size -lt 0) { throw "Invalid VP entry: $name" }
            if ($size -eq 0) {
                if ($name -eq '..') {
                    if ($dirs.Count -eq 0) { throw 'VP directory underflow' }
                    $dirs.RemoveAt($dirs.Count - 1)
                } else { $dirs.Add($name) }
                continue
            }
            if ($offset -lt 16 -or ([long]$offset + $size) -gt $index) { throw "Invalid VP range: $name" }
            $inventory.Add([pscustomobject]@{ path=(@($dirs) + $name) -join '/'; name=$name; extension=[IO.Path]::GetExtension($name).ToLowerInvariant(); source=$archive.FullName; offset=$offset; size=$size; kind='vp' })
        }
    } finally { $reader.Dispose() }
}
if (Test-Path -LiteralPath (Join-Path $root 'data')) {
    foreach ($file in Get-ChildItem -LiteralPath (Join-Path $root 'data') -File -Recurse) {
        $inventory.Add([pscustomobject]@{ path=$file.FullName.Substring($root.Length + 1).Replace('\','/'); name=$file.Name; extension=$file.Extension.ToLowerInvariant(); source=$file.FullName; offset=0; size=$file.Length; kind='loose' })
    }
}
function Read-Entry($entry) {
    $stream = [IO.File]::OpenRead($entry.source)
    try {
        $stream.Position = $entry.offset
        $bytes = [byte[]]::new($entry.size)
        $read = 0
        while ($read -lt $bytes.Length) {
            $n = $stream.Read($bytes, $read, $bytes.Length - $read)
            if ($n -eq 0) { throw 'Unexpected EOF' }
            $read += $n
        }
        return ,$bytes
    } finally { $stream.Dispose() }
}
function Values($text, $pattern) {
    @([regex]::Matches($text, $pattern, 'Multiline') | ForEach-Object { $_.Groups[1].Value.Trim() } | Sort-Object -Unique)
}
function Section($text, $name) {
    ([regex]::Match($text, '(?ms)^#' + [regex]::Escape($name) + '\b[^\r\n]*\r?\n(.*?)(?=^#|\z)')).Groups[1].Value
}
$summaries = foreach ($mission in $MissionNames) {
    $candidates = @($inventory | Where-Object name -eq $mission)
    if ($candidates.Count -ne 1) { throw "Expected one source for $mission; found $($candidates.Count). Resolve overrides explicitly." }
    $entry = $candidates[0]
    $bytes = Read-Entry $entry
    $sha = [Security.Cryptography.SHA256]::Create()
    try { $hash = [BitConverter]::ToString($sha.ComputeHash($bytes)).Replace('-','').ToLowerInvariant() } finally { $sha.Dispose() }
    $text = [Text.Encoding]::GetEncoding(1252).GetString($bytes)
    # Lexical discovery only: these are not a parsed/resolved dependency closure.
    [pscustomobject]@{
        file=$entry; sha256=$hash
        title=([regex]::Match($text, '^\$Name:\s*(.*)$', 'Multiline')).Groups[1].Value.Trim()
        shipClasses=Values $text '^\$Class:\s*(.*)$'
        objectNames=Values (Section $text 'Objects') '^\$Name:\s*([^;\r\n]*)'
        eventNames=Values (Section $text 'Events') '^\+Name:\s*([^;\r\n]*)'
        wingNames=Values (Section $text 'Wings') '^\$Name:\s*([^;\r\n]*)'
        assetTokens=Values $text '(?i)([a-z0-9_#.-]+\.(?:wav|ogg|ani|eff|pcx|tga|png|dds|pof|mve|fs2))'
        operatorCandidates=Values $text '\(\s*([a-z][a-z0-9-]*)\b'
        resourceLines=@($text -split '\r?\n' | Where-Object { $_ -match '^\s*[+$].*(?:Weapon|Bank|Music|Sound|Voice|Bitmap|Skybox|Sun|Nebula|Ship Choices|Formula|Goal|Background|Loadout)' })
        status='Lexical inventory only; table merge, indirect model/texture dependencies, and event semantics remain unresolved.'
    }
}
$campaigns = foreach ($entry in $inventory | Where-Object name -eq 'FreeSpace2.fc2') {
    $text = [Text.Encoding]::GetEncoding(1252).GetString((Read-Entry $entry))
    [pscustomobject]@{ source=$entry; missionOrder=@([regex]::Matches($text, '^\$Mission:\s*(.*)$', 'Multiline') | ForEach-Object { $_.Groups[1].Value.Trim() }) }
}
$report = [pscustomobject]@{
    contentRoot=$root
    resolutionPolicy='No mod precedence inferred. Mission/campaign candidates must be unique; inventory preserves duplicates for later resolution.'
    formats=@($inventory | Group-Object extension | Sort-Object Name | ForEach-Object { [pscustomobject]@{ extension=$_.Name; count=$_.Count; bytes=($_.Group | Measure-Object size -Sum).Sum } })
    campaigns=@($campaigns); missions=@($summaries); files=@($inventory)
}
if ($OutputPath) { $report | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $OutputPath -Encoding UTF8 }
$report | Select-Object contentRoot, formats, campaigns, @{Name='missions';Expression={ @($_.missions | Select-Object file, sha256, title, shipClasses, operatorCandidates, status) }} | ConvertTo-Json -Depth 12
