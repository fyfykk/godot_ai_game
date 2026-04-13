@echo off
setlocal
set ROOT=%~dp0
if "%ROOT:~-1%"=="\" set ROOT=%ROOT:~0,-1%
set PORT=8443
set TUNNEL_OUT_LOG=%ROOT%\build\web_public_tunnel.out.log
set TUNNEL_ERR_LOG=%ROOT%\build\web_public_tunnel.err.log
set TUNNEL_PID_FILE=%ROOT%\build\web_public_tunnel.pid
set URL_FILE=%ROOT%\build\web_public_url.txt
set CLOUD_FLARED=%ROOT%\tools\cloudflared.exe
if not exist "%CLOUD_FLARED%" set CLOUD_FLARED=cloudflared

if /i "%~1"=="stop" goto STOP_MODE

call "%ROOT%\build_web.bat"
if errorlevel 1 exit /b 1

call "%ROOT%\stop_web_server.bat" >nul 2>&1
call "%ROOT%\start_web_server.bat"
if errorlevel 1 exit /b 1

if exist "%TUNNEL_PID_FILE%" (
  set OLD_PID=
  for /f "usebackq delims=" %%p in ("%TUNNEL_PID_FILE%") do set OLD_PID=%%p
  if not "%OLD_PID%"=="" taskkill /PID %OLD_PID% /F >nul 2>&1
  del "%TUNNEL_PID_FILE%"
)
if exist "%TUNNEL_OUT_LOG%" del "%TUNNEL_OUT_LOG%"
if exist "%TUNNEL_ERR_LOG%" del "%TUNNEL_ERR_LOG%"
if exist "%URL_FILE%" del "%URL_FILE%"

if /i "%CLOUD_FLARED%"=="cloudflared" (
  where cloudflared >nul 2>&1
  if errorlevel 1 (
    call :ENSURE_CLOUDFLARED
    if errorlevel 1 (
      call "%ROOT%\stop_web_server.bat" >nul 2>&1
      exit /b 1
    )
  )
) else (
  if not exist "%CLOUD_FLARED%" (
    call :ENSURE_CLOUDFLARED
    if errorlevel 1 (
      call "%ROOT%\stop_web_server.bat" >nul 2>&1
      exit /b 1
    )
  )
)

call :START_TUNNEL
if errorlevel 1 (
  call :ENSURE_CLOUDFLARED
  if errorlevel 1 (
    call "%ROOT%\stop_web_server.bat" >nul 2>&1
    exit /b 1
  )
  call :START_TUNNEL
  if errorlevel 1 (
    echo Failed to start cloudflared. Check tools\cloudflared.exe or PATH cloudflared.
    call "%ROOT%\stop_web_server.bat" >nul 2>&1
    exit /b 1
  )
)

powershell -NoProfile -Command "$outLog='%TUNNEL_OUT_LOG%'; $errLog='%TUNNEL_ERR_LOG%'; $url=''; for($i=0;$i -lt 60;$i++){ Start-Sleep -Milliseconds 500; $txt=''; if(Test-Path $outLog){ $txt += (Get-Content $outLog -Raw) + [Environment]::NewLine }; if(Test-Path $errLog){ $txt += (Get-Content $errLog -Raw) }; $m=[regex]::Match($txt,'https://[a-zA-Z0-9.-]+\.trycloudflare\.com'); if($m.Success){ $url=$m.Value; break } }; if($url -ne ''){ Set-Content -Path '%URL_FILE%' -Value $url -Encoding ascii; Write-Output $url; exit 0 } else { exit 1 }"
if errorlevel 1 (
  echo Tunnel started but public URL not detected yet.
  echo Check logs:
  echo   %TUNNEL_OUT_LOG%
  echo   %TUNNEL_ERR_LOG%
  call "%ROOT%\stop_web_server.bat" >nul 2>&1
  exit /b 1
)

for /f "usebackq delims=" %%u in ("%URL_FILE%") do set PUBLIC_URL=%%u
echo.
echo ================== PUBLIC WEB URL ==================
echo %PUBLIC_URL%
echo Public URL: %PUBLIC_URL%
echo Stop command: publish_web_public.bat stop
echo ====================================================
exit /b 0

:START_TUNNEL
powershell -NoProfile -Command "try { $exe='%CLOUD_FLARED%'; $args=@('tunnel','--url','https://localhost:%PORT%','--no-tls-verify'); $p=Start-Process -FilePath $exe -ArgumentList $args -WorkingDirectory '%ROOT%' -RedirectStandardOutput '%TUNNEL_OUT_LOG%' -RedirectStandardError '%TUNNEL_ERR_LOG%' -PassThru -ErrorAction Stop; $p.Id | Set-Content -Path '%TUNNEL_PID_FILE%' -Encoding ascii; exit 0 } catch { exit 1 }"
exit /b %errorlevel%

:ENSURE_CLOUDFLARED
if not exist "%ROOT%\tools" mkdir "%ROOT%\tools"
powershell -NoProfile -Command "$arch=$env:PROCESSOR_ARCHITEW6432; if(-not $arch){ $arch=$env:PROCESSOR_ARCHITECTURE }; $arch=($arch+'').ToUpper(); if($arch -eq 'ARM64'){ $urls=@('https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-arm64.exe','https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe') } elseif($arch -eq 'AMD64'){ $urls=@('https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe','https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-386.exe') } else { $urls=@('https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-386.exe','https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe') }; $ok=$false; foreach($u in $urls){ try { Invoke-WebRequest -Uri $u -OutFile '%ROOT%\tools\cloudflared.exe' -UseBasicParsing -TimeoutSec 25 -ErrorAction Stop; $p=Start-Process -FilePath '%ROOT%\tools\cloudflared.exe' -ArgumentList @('--version') -Wait -PassThru -WindowStyle Hidden -ErrorAction Stop; if($p.ExitCode -eq 0){ $ok=$true; break } } catch {} }; if($ok){ exit 0 } else { exit 1 }"
if errorlevel 1 (
  echo cloudflared not found and auto-download failed.
  echo Please install cloudflared and add it to PATH, or put cloudflared.exe at tools\cloudflared.exe
  exit /b 1
)
set CLOUD_FLARED=%ROOT%\tools\cloudflared.exe
exit /b 0

:STOP_MODE
if exist "%TUNNEL_PID_FILE%" (
  set PID=
  for /f "usebackq delims=" %%p in ("%TUNNEL_PID_FILE%") do set PID=%%p
  if not "%PID%"=="" taskkill /PID %PID% /F >nul 2>&1
  del "%TUNNEL_PID_FILE%"
)
call "%ROOT%\stop_web_server.bat"
echo Public web tunnel and local web server stopped.
endlocal
