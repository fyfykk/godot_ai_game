@echo off
setlocal
set ROOT=%~dp0
if "%ROOT:~-1%"=="\" set ROOT=%ROOT:~0,-1%
set PORT=8443
set PID_FILE=%ROOT%\build\web_server.pid
if exist "%PID_FILE%" (
  for /f "usebackq delims=" %%p in ("%PID_FILE%") do set PID=%%p
  if not "%PID%"=="" (
    taskkill /PID %PID% /F >nul 2>&1
  )
  del "%PID_FILE%"
)
for /f "tokens=5" %%p in ('netstat -ano ^| findstr ":%PORT% .*LISTENING"') do taskkill /PID %%p /F >nul 2>&1
endlocal
