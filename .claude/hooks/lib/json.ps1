# json.ps1 — read the hook event JSON from stdin and pull fields out of it.

function Get-HookField {
    # Read stdin once and return a field by dotted path.
    # Usage:  $f = Get-HookField 'tool_input.file_path'
    # Note: reads stdin once; call a single time per hook invocation.
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

function Get-HookPayload {
    # Read the hook event JSON from stdin once and return the parsed object.
    $raw = [Console]::In.ReadToEnd()
    if (-not $raw) { return $null }
    return ($raw | ConvertFrom-Json)
}

function Get-HookChangedFiles {
    # Emit the file paths touched by an edit, handling BOTH payload shapes:
    #   Claude Write/Edit/MultiEdit → tool_input.file_path (one path)
    #   Codex apply_patch           → file markers in tool_input.command patch text
    # Delete markers are intentionally skipped (nothing left to lint/log).
    param([object]$Payload)
    if ($null -eq $Payload) { return @() }
    $fp = $Payload.tool_input.file_path
    if ($fp) { return @($fp) }
    $cmd = $Payload.tool_input.command
    if (-not $cmd) { return @() }
    $files = @()
    foreach ($line in ($cmd -split "`n")) {
        $line = $line.TrimEnd("`r")
        if ($line -match '^\*\*\* (?:Add|Update) File: (.+)$') { $files += $Matches[1] }
        elseif ($line -match '^\*\*\* Move to: (.+)$')         { $files += $Matches[1] }
    }
    return $files
}
