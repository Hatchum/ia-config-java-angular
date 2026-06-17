# PostToolUse file edits: lint/format each file touched by the edit.
# Handles Claude (Write|Edit|MultiEdit → tool_input.file_path) and
# Codex (apply_patch → file markers in tool_input.command).
# Contract: exit 2 feeds the linter output back to the agent as correction feedback.
$ErrorActionPreference = 'Stop'
# Portable project root: Claude sets CLAUDE_PROJECT_DIR; Codex does not, so fall back to git.
$projectDir = if ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { git rev-parse --show-toplevel 2>$null }
if (-not $projectDir) { $projectDir = '.' }
$hookDir = Join-Path $projectDir '.claude/hooks'
. (Join-Path $hookDir 'lib/json.ps1')
. (Join-Path $hookDir 'lib/checks.ps1')
$payload = Get-HookPayload
$status = 0
foreach ($file in (Get-HookChangedFiles $payload)) {
    if (-not $file) { continue }
    $out = Invoke-LintForFile $file 2>&1
    if ($LASTEXITCODE -ne 0) {
        [Console]::Error.WriteLine(($out | Out-String))
        $status = 2
    }
}
exit $status
