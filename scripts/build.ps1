# Build the full Maven reactor (includes the Angular module when wired via
# frontend-maven-plugin). Usage: scripts\build.ps1  [extra mvn args]
$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')
mvn -q -T1C clean install @args
exit $LASTEXITCODE
