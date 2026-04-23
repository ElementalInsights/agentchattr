@echo off
REM agentchattr — Start the full Athena Rust Lab team (all 4 agents, unattended)
cd /d "%~dp0.."

REM Auto-create venv and install deps on first run
if not exist ".venv" (
    echo   Setting up environment...
    python -m venv .venv
    .venv\Scripts\pip install -q -r requirements.txt >nul 2>nul
)
call .venv\Scripts\activate.bat

REM Pre-flight: check claude CLI is installed
where claude >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo   Error: "claude" was not found on PATH.
    echo   Install Claude Code first, then try again.
    echo.
    pause
    exit /b 1
)

REM Start server if not already running
netstat -ano | findstr :8300 | findstr LISTENING >nul 2>&1
if %errorlevel% neq 0 (
    echo   Starting agentchattr server...
    start "agentchattr — server" cmd /c "python run.py"
)

REM Wait for server to be ready
:wait_server
netstat -ano | findstr :8300 | findstr LISTENING >nul 2>&1
if %errorlevel% neq 0 (
    timeout /t 1 /nobreak >nul
    goto :wait_server
)
echo   Server ready.

REM Launch all 4 agents in separate windows, staggered so they don't race on startup
echo   Launching Architect...
start "Architect  (@claude-arch)"  cmd /c "call .venv\Scripts\activate.bat && python wrapper.py claude-arch  --dangerously-skip-permissions & pause"

timeout /t 2 /nobreak >nul

echo   Launching Builder...
start "Builder    (@claude-build)" cmd /c "call .venv\Scripts\activate.bat && python wrapper.py claude-build --dangerously-skip-permissions & pause"

timeout /t 2 /nobreak >nul

echo   Launching Reviewer...
start "Reviewer   (@claude-review)" cmd /c "call .venv\Scripts\activate.bat && python wrapper.py claude-review --dangerously-skip-permissions & pause"

timeout /t 2 /nobreak >nul

echo   Launching Scientist...
start "Scientist  (@claude-science)" cmd /c "call .venv\Scripts\activate.bat && python wrapper.py claude-science --dangerously-skip-permissions & pause"

echo.
echo   Rust Lab team is online.
echo   Open http://localhost:8300 to start.
echo.
