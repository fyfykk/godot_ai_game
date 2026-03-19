@echo off
setlocal
set ROOT=%~dp0
if "%ROOT:~-1%"=="\" set ROOT=%ROOT:~0,-1%
set PORT=8443
set OUT_DIR=%ROOT%\build\web
set CERT_DIR=%ROOT%\tools_cache\https
set CERT=%CERT_DIR%\server.crt
set KEY=%CERT_DIR%\server.key
set LOG_OUT=%ROOT%\build\web_server.out.log
set LOG_ERR=%ROOT%\build\web_server.err.log
for /f "usebackq delims=" %%i in (`powershell -NoProfile -Command "$ips = Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.IPAddress -notlike '169.254*' -and $_.IPAddress -ne '127.0.0.1'} | Select-Object -ExpandProperty IPAddress; $lan = $ips | Where-Object {$_ -like '192.168.*'} | Select-Object -First 1; if (-not $lan) { $lan = $ips | Where-Object {$_ -like '10.*'} | Select-Object -First 1 }; if (-not $lan) { $lan = $ips | Where-Object {$_ -match '^172\\.(1[6-9]|2[0-9]|3[0-1])\\.'} | Select-Object -First 1 }; if (-not $lan) { $lan = $ips | Select-Object -First 1 }; if ($lan) { $lan }"`) do set LAN_IP=%%i
if "%LAN_IP%"=="" set LAN_IP=127.0.0.1
for /f "usebackq delims=" %%i in (`powershell -NoProfile -Command "$ips = Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.IPAddress -notlike '169.254*' -and $_.IPAddress -ne '127.0.0.1'} | Select-Object -ExpandProperty IPAddress; $ips -join ','"`) do set ALL_IPS=%%i
if not exist "%OUT_DIR%\index.html" (
  echo Missing build/web/index.html. Run build_web.bat first.
  exit /b 1
)
if not exist "%CERT_DIR%" mkdir "%CERT_DIR%"
if not exist "%CERT%" (
  python "%ROOT%\scripts\tools\gen_selfsigned.py" --out-dir "%CERT_DIR%" --ip "%LAN_IP%"
)
if not exist "%KEY%" (
  python "%ROOT%\scripts\tools\gen_selfsigned.py" --out-dir "%CERT_DIR%" --ip "%LAN_IP%"
)
netsh advfirewall firewall add rule name="ai_game_web_8443" dir=in action=allow protocol=TCP localport=%PORT% >nul 2>&1
if exist "%ROOT%\build\web_server.pid" del "%ROOT%\build\web_server.pid"
powershell -NoProfile -Command "$argsList = @('scripts/tools/https_server.py','--dir','build/web','--cert','%CERT%','--key','%KEY%','--port','%PORT%'); $p = Start-Process -FilePath python -ArgumentList $argsList -WorkingDirectory '%ROOT%' -RedirectStandardOutput '%LOG_OUT%' -RedirectStandardError '%LOG_ERR%' -PassThru; $p.Id | Set-Content -Path '%ROOT%\build\web_server.pid' -Encoding ascii"
powershell -NoProfile -Command "Start-Sleep -Milliseconds 500; if (Get-NetTCPConnection -State Listen -LocalPort %PORT% -ErrorAction SilentlyContinue) { exit 0 } else { exit 1 }"
if errorlevel 1 (
  echo Server failed to start. See %LOG_OUT% and %LOG_ERR%
  exit /b 1
)
echo https://localhost:%PORT%/
echo https://%LAN_IP%:%PORT%/
if not "%ALL_IPS%"=="" echo LAN IPs: %ALL_IPS%
endlocal
