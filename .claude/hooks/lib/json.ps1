# json.ps1 — read the hook event JSON from stdin and return a field by dotted path.
# Usage (dot-source this file, then):  $f = Get-HookField 'tool_input.file_path'
# Note: reads stdin once; call Get-HookField a single time per hook invocation.
function Get-HookField {
    param([string]$Path)
    $raw = [Console]::In.ReadToEnd()
    if (-not $raw) { return $null }
    $obj = $raw | ConvertFrom-Json
    foreach ($part in $Path.Split('.')) {
        if ($null -eq $obj) { return $null }
        $obj = $obj.$part
    }
    return $obj
}
