# PostToolUse(Write|Edit|MultiEdit): lint/format the file that was just written.
# Contract: exit 2 feeds the linter output back to Claude as correction feedback.
$ErrorActionPreference = 'Stop'
$hookDir = Join-Path $env:CLAUDE_PROJECT_DIR '.claude/hooks'
. (Join-Path $hookDir 'lib/json.ps1')
. (Join-Path $hookDir 'lib/checks.ps1')
$file = Get-HookField 'tool_input.file_path'
if (-not $file) { exit 0 }
$out = Invoke-LintForFile $file 2>&1
if ($LASTEXITCODE -eq 0) { exit 0 }
[Console]::Error.WriteLine(($out | Out-String))
exit 2
