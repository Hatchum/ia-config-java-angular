# Stop gate (task P4) — PowerShell variant of verify-on-stop.sh: block ending
# a session on a dirty worktree whose verification command fails (exit 2 feeds
# stderr back to Claude). Ships INERT until $script:VerifyCmd in lib/checks.ps1
# is filled (a value containing '<' is treated as unconfigured, exit 0).
# Loop protection: exits 0 when stop_hook_active is true.
$ErrorActionPreference = 'Stop'
$projectDir = if ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { git rev-parse --show-toplevel 2>$null }
if (-not $projectDir) { $projectDir = '.' }
$hookDir = Join-Path $projectDir '.claude/hooks'
. (Join-Path $hookDir 'lib/json.ps1')
. (Join-Path $hookDir 'lib/checks.ps1')
$payload = Get-HookPayload
if ($payload -and $payload.stop_hook_active) { exit 0 }
$dirty = git -C $projectDir status --porcelain 2>$null
if (-not $dirty) { exit 0 }
if ($script:VerifyCmd -like '*<*') { exit 0 }
Push-Location $projectDir
try {
    $out = Invoke-Expression $script:VerifyCmd 2>&1
    $code = $LASTEXITCODE
} finally { Pop-Location }
if ($code -ne 0) {
    [Console]::Error.WriteLine("Stop blocked: verification gate failed ($script:VerifyCmd). Fix before ending the session.")
    [Console]::Error.WriteLine(($out | Out-String))
    exit 2
}
exit 0
