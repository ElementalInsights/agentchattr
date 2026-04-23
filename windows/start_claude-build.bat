@echo off
REM agentchattr — Athena Rust Lab: claude-build
cd /d "%~dp0.."

if not exist ".venv" (
    python -m venv .venv
    .venv\Scripts\pip install -q -r requirements.txt >/dev/null 2>/dev/null
)
call .venv\Scripts\activate.bat

where claude >/dev/null 2>&1
if %errorlevel% neq 0 (
    echo.
    echo   Error: "claude" was not found on PATH.
    pause
    exit /b 1
)

netstat -ano | findstr :8300 | findstr LISTENING >/dev/null 2>&1
if %errorlevel% neq 0 (
    start "agentchattr server" cmd /c "python run.py"
)
:wait_server
netstat -ano | findstr :8300 | findstr LISTENING >/dev/null 2>&1
if %errorlevel% neq 0 (
    timeout /t 1 /nobreak >/dev/null
    goto :wait_server
)

python wrapper.py claude-build
if %errorlevel% neq 0 (
    echo.
    echo   Agent exited unexpectedly. Check the output above.
    pause
)
