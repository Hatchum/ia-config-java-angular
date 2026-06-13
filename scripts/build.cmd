@echo off
REM Build the full Maven reactor (includes the Angular module when wired via
REM frontend-maven-plugin). Usage: scripts\build.cmd  [extra mvn args]
setlocal
cd /d "%~dp0.."
call mvn -q -T1C clean install %*
set "ERR=%errorlevel%"
endlocal & exit /b %ERR%
