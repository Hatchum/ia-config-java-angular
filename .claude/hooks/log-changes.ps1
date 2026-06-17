# PostToolUse file edits: append each touched file to a local, gitignored changelog.
# Handles Claude (tool_input.file_path) and Codex (apply_patch tool_input.command).
# Never blocks (always exit 0).
$ErrorActionPreference = 'Stop'
# Portable project root: Claude sets CLAUDE_PROJECT_DIR; Codex does not, so fall back to git.
$projectDir = if ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { git rev-parse --show-toplevel 2>$null }
if (-not $projectDir) { $projectDir = '.' }
$hookDir = Join-Path $projectDir '.claude/hooks'
. (Join-Path $hookDir 'lib/json.ps1')
$payload = Get-HookPayload
if ($null -eq $payload) { exit 0 }
$log = Join-Path $projectDir '.claude/changes.local.log'
$ts = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ')
foreach ($file in (Get-HookChangedFiles $payload)) {
    if (-not $file) { continue }
    "$ts`t$($payload.tool_name)`t$file" | Out-File -FilePath $log -Append -Encoding utf8
}
exit 0
