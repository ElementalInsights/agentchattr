@echo off
REM AthenaAI — Agentic Teams | Start full team in a single Windows Terminal window
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

REM Check if Windows Terminal is available
where wt >nul 2>&1
if %errorlevel% neq 0 (
    echo   Windows Terminal not found — falling back to separate windows.
    goto :fallback
)

REM Start server if not already running
netstat -ano | findstr :8300 | findstr LISTENING >nul 2>&1
if %errorlevel% neq 0 (
    echo   Starting agentchattr server...
    start "AthenaAI Server" cmd /c "call .venv\Scripts\activate.bat && python run.py"
)

REM Wait for server to be ready
:wait_server
netstat -ano | findstr :8300 | findstr LISTENING >nul 2>&1
if %errorlevel% neq 0 (
    timeout /t 1 /nobreak >nul
    goto :wait_server
)
echo   Server ready. Launching team in Windows Terminal...

REM Store the working directory for use in WT tabs
set WDIR=%CD%

REM Open all 4 agents as tabs in a single Windows Terminal window
REM Each tab activates the venv and launches its agent wrapper
wt.exe ^
  --title "Architect" ^
  cmd /k "cd /d "%WDIR%" && call .venv\Scripts\activate.bat && python wrapper.py claude-arch --dangerously-skip-permissions" ^
  ; new-tab --title "Builder" ^
  cmd /k "cd /d "%WDIR%" && timeout /t 2 /nobreak >nul && call .venv\Scripts\activate.bat && python wrapper.py claude-build --dangerously-skip-permissions" ^
  ; new-tab --title "Reviewer" ^
  cmd /k "cd /d "%WDIR%" && timeout /t 4 /nobreak >nul && call .venv\Scripts\activate.bat && python wrapper.py claude-review --dangerously-skip-permissions" ^
  ; new-tab --title "Scientist" ^
  cmd /k "cd /d "%WDIR%" && timeout /t 6 /nobreak >nul && call .venv\Scripts\activate.bat && python wrapper.py claude-science --dangerously-skip-permissions"

echo.
echo   AthenaAI team is online.
echo   Open http://localhost:8300 to start.
echo.
goto :end

REM ── Fallback: separate windows (if Windows Terminal not installed) ──────────
:fallback
netstat -ano | findstr :8300 | findstr LISTENING >nul 2>&1
if %errorlevel% neq 0 (
    start "AthenaAI Server" cmd /c "call .venv\Scripts\activate.bat && python run.py"
)
:wait_server_fb
netstat -ano | findstr :8300 | findstr LISTENING >nul 2>&1
if %errorlevel% neq 0 ( timeout /t 1 /nobreak >nul && goto :wait_server_fb )

start "Architect"  cmd /c "call .venv\Scripts\activate.bat && python wrapper.py claude-arch   --dangerously-skip-permissions & pause"
timeout /t 2 /nobreak >nul
start "Builder"    cmd /c "call .venv\Scripts\activate.bat && python wrapper.py claude-build  --dangerously-skip-permissions & pause"
timeout /t 2 /nobreak >nul
start "Reviewer"   cmd /c "call .venv\Scripts\activate.bat && python wrapper.py claude-review --dangerously-skip-permissions & pause"
timeout /t 2 /nobreak >nul
start "Scientist"  cmd /c "call .venv\Scripts\activate.bat && python wrapper.py claude-science --dangerously-skip-permissions & pause"

echo.
echo   AthenaAI team is online ^(separate windows^).
echo   Open http://localhost:8300 to start.
echo.

:end
