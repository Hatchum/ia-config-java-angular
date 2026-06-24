# Stop/SubagentStop: scan the working tree once per turn (see
# log-worktree-snapshot.sh for the rationale — captures raw-Bash file changes
# the tool-matched hook misses). Appends to the same log as log-changes.ps1
# (event worktree_snapshot vs tool_edit).
# Never blocks (always exit 0).
$ErrorActionPreference = 'Stop'
$projectDir = if ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { git rev-parse --show-toplevel 2>$null }
if (-not $projectDir) { $projectDir = '.' }
$hookDir = Join-Path $projectDir '.claude/hooks'
. (Join-Path $hookDir 'lib/json.ps1')
$payload = Get-HookPayload
if ($null -eq $payload) { exit 0 }
$log = Join-Path $projectDir '.claude/logs/agent-activity.jsonl'
$ts = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ')
$agentType = if ($payload.agent_type) { $payload.agent_type } else { 'main' }
$agentId = if ($payload.agent_id) { $payload.agent_id } else { '-' }
$sessionId = $payload.session_id
$statusLines = git -C $projectDir status --porcelain 2>$null
foreach ($line in $statusLines) {
    if (-not $line) { continue }
    $status = $line.Substring(0, 2)
    $path = $line.Substring(3)
    Add-JsonLine -Path $log -Fields ([ordered]@{
        timestamp  = $ts
        event      = 'worktree_snapshot'
        session_id = $sessionId
        agent_type = $agentType
        agent_id   = $agentId
        status     = $status
        file       = $path
    })
}
exit 0
