# PreToolUse(Bash): if the command is a `git commit`, lint staged files first.
# Contract: exit 2 BLOCKS the commit and returns the report to Claude.
# Inert while <LINT_COMMANDS> are unconfigured (Invoke-LintForFile skips → never blocks).
$ErrorActionPreference = 'Stop'
# Portable project root: Claude sets CLAUDE_PROJECT_DIR; Codex does not, so fall back to git.
$projectDir = if ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { git rev-parse --show-toplevel 2>$null }
if (-not $projectDir) { $projectDir = '.' }
$hookDir = Join-Path $projectDir '.claude/hooks'
. (Join-Path $hookDir 'lib/json.ps1')
. (Join-Path $hookDir 'lib/checks.ps1')
$cmd = Get-HookField 'tool_input.command'
if ($cmd -notmatch 'git\s+commit') { exit 0 }
$failed = $false; $report = @()
$staged = git diff --cached --name-only --diff-filter=ACM 2>$null
foreach ($f in $staged) {
    if (-not $f) { continue }
    $out = Invoke-LintForFile $f 2>&1
    if ($LASTEXITCODE -ne 0) { $failed = $true; $report += ($out | Out-String) }
}
if ($failed) {
    [Console]::Error.WriteLine("Commit blocked: staged files failed lint.`n" + ($report -join "`n"))
    exit 2
}
exit 0
