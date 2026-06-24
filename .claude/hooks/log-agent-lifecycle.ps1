# SubagentStart/SubagentStop: append a human-traceable JSON Lines record of when
# each subagent started/finished, to .claude/logs/agent-runs.jsonl (local,
# gitignored). See log-agent-lifecycle.sh for the rationale and field sourcing.
# Never blocks (always exit 0).
$ErrorActionPreference = 'Stop'
$projectDir = if ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { git rev-parse --show-toplevel 2>$null }
if (-not $projectDir) { $projectDir = '.' }
$hookDir = Join-Path $projectDir '.claude/hooks'
. (Join-Path $hookDir 'lib/json.ps1')
$payload = Get-HookPayload
if ($null -eq $payload) { exit 0 }
$log = Join-Path $projectDir '.claude/logs/agent-runs.jsonl'
$ts = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ')
$event = switch ($payload.hook_event_name) {
    'SubagentStart' { 'subagent_start' }
    'SubagentStop'  { 'subagent_stop' }
    default         { if ($payload.hook_event_name) { $payload.hook_event_name } else { 'unknown' } }
}
Add-JsonLine -Path $log -Fields ([ordered]@{
    timestamp  = $ts
    event      = $event
    session_id = $payload.session_id
    agent_type = if ($payload.agent_type) { $payload.agent_type } else { '?' }
    agent_id   = if ($payload.agent_id) { $payload.agent_id } else { '-' }
})
exit 0
