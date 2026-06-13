# PostToolUse(Write|Edit|MultiEdit): append an entry to a local, gitignored changelog.
# Never blocks (always exit 0).
$ErrorActionPreference = 'Stop'
$raw = [Console]::In.ReadToEnd()
if (-not $raw) { exit 0 }
$obj = $raw | ConvertFrom-Json
$file = $obj.tool_input.file_path
if (-not $file) { exit 0 }
$log = Join-Path $env:CLAUDE_PROJECT_DIR '.claude/changes.local.log'
$ts = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ')
"$ts`t$($obj.tool_name)`t$file" | Out-File -FilePath $log -Append -Encoding utf8
exit 0
