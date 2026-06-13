# checks.ps1 — shared lint/format routing for hooks (PowerShell variant).
# Fill the *LintCmd placeholders at install (§12 <LINT_COMMANDS>).
# A command still containing "<" is treated as UNCONFIGURED and skipped (exit 0),
# so the kit ships safe until real commands are wired in.

# Java sources. Example: mvn -q -pl :your-module spotless:apply checkstyle:check
$script:JavaLintCmd = '<LINT_COMMANDS: java — e.g. mvn -q spotless:apply checkstyle:check>'
# TS/HTML/SCSS/CSS. The touched file is exposed as $file.
# Example: npx eslint --fix "$file"; npx prettier --write "$file"
$script:WebLintCmd  = '<LINT_COMMANDS: web — e.g. npx eslint --fix "$file"; npx prettier --write "$file">'

function Invoke-LintForFile {
    param([string]$file)
    $cmd = switch -Wildcard ($file) {
        '*.java' { $script:JavaLintCmd; break }
        '*.ts'   { $script:WebLintCmd;  break }
        '*.html' { $script:WebLintCmd;  break }
        '*.scss' { $script:WebLintCmd;  break }
        '*.css'  { $script:WebLintCmd;  break }
        default  { $null }
    }
    if (-not $cmd) { $global:LASTEXITCODE = 0; return }
    if ($cmd -like '*<*') {
        [Console]::Error.WriteLine("hook: lint not configured for $file (fill <LINT_COMMANDS> in checks.ps1)")
        $global:LASTEXITCODE = 0; return
    }
    Invoke-Expression $cmd
}
