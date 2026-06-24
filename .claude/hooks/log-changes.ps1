# PostToolUse file edits: append one JSON Lines audit record per touched file
# to .claude/logs/agent-activity.jsonl (local, gitignored).
# Handles Claude (tool_input.file_path) and Codex (apply_patch tool_input.command).
# agent_type/agent_id are present in the hook payload only when the call comes
# from inside a subagent (confirmed: code.claude.com/docs/en/hooks) — "main"/"-"
# otherwise, so every line is attributable to the agent that made the edit.
# JSONL audit pattern per code.claude.com/docs/en/hooks ("Audit configuration
# changes" example). Complemented by log-worktree-snapshot.ps1 (event
# worktree_snapshot in the same file) for changes made via raw Bash.
# Never blocks (always exit 0).
$ErrorActionPreference = 'Stop'
# Portable project root: Claude sets CLAUDE_PROJECT_DIR; Codex does not, so fall back to git.
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
foreach ($file in (Get-HookChangedFiles $payload)) {
    if (-not $file) { continue }
    Add-JsonLine -Path $log -Fields ([ordered]@{
        timestamp  = $ts
        event      = 'tool_edit'
        session_id = $sessionId
        agent_type = $agentType
        agent_id   = $agentId
        tool       = $payload.tool_name
        file       = $file
    })
}
exit 0
