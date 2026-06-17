# Regenerate tool-specific config from .ai/config/ sources.
# Usage: scripts\sync-config.ps1
$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')
python (Join-Path $PSScriptRoot 'sync-config.py') @args
exit $LASTEXITCODE