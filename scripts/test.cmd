@echo off
REM Run backend tests (Maven reactor) then frontend tests.
REM <PLACEHOLDER>: set ANGULAR_DIR to the Angular module directory at install.
REM If the reactor already runs frontend tests (frontend-maven-plugin), the
REM frontend block below is optional.
setlocal
cd /d "%~dp0.."
call mvn test %*
if errorlevel 1 ( endlocal & exit /b 1 )

set "ANGULAR_DIR=frontend"
if not exist "%ANGULAR_DIR%\package.json" (
  echo [test] frontend skipped: "%ANGULAR_DIR%\package.json" not found ^(set ANGULAR_DIR in scripts\test.cmd^)
  endlocal & exit /b 0
)
pushd "%ANGULAR_DIR%"
call npm test
set "ERR=%errorlevel%"
popd
endlocal & exit /b %ERR%
