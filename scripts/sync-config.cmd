@echo off
cd /d "%~dp0.."
python "%~dp0sync-config.py" %*
exit /b %ERRORLEVEL%