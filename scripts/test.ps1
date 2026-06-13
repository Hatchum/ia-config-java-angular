# Run backend tests (Maven reactor) then frontend tests.
# <PLACEHOLDER>: set $AngularDir to the Angular module directory at install.
# If the reactor already runs frontend tests (frontend-maven-plugin), the
# frontend block below is optional.
$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')
mvn test @args
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$AngularDir = 'frontend'   # <ANGULAR_MODULE_DIR>
if (-not (Test-Path (Join-Path $AngularDir 'package.json'))) {
    Write-Host "[test] frontend skipped: $AngularDir/package.json not found (set `$AngularDir in scripts/test.ps1)"
    exit 0
}
Push-Location $AngularDir
try { npm test; $code = $LASTEXITCODE } finally { Pop-Location }
exit $code
