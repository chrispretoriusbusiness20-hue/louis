@echo off
rem Launches the Local AI Video Studio: ComfyUI engine + studio web app,
rem then opens the browser. Keep both server windows open while generating.
cd /d "%~dp0"

if not exist "ComfyUI\venv\Scripts\python.exe" (
    echo ComfyUI is not installed yet. Run setup-windows.ps1 first ^(see README^).
    pause
    exit /b 1
)

where nvidia-smi >nul 2>&1
if %errorlevel%==0 (set "GPUFLAG=") else (set "GPUFLAG=--cpu")

start "ComfyUI engine - keep this window open" cmd /k ""%~dp0ComfyUI\venv\Scripts\python.exe" "%~dp0ComfyUI\main.py" %GPUFLAG%"
start "Video Studio - keep this window open" cmd /k ""%~dp0ComfyUI\venv\Scripts\python.exe" "%~dp0studio\server.py""

echo Waiting for the servers to start...
timeout /t 20 /nobreak >nul
start "" http://127.0.0.1:8189
echo.
echo Studio opened in your browser at http://127.0.0.1:8189
echo If the page says the engine is not running yet, wait ~1 minute and reload.
