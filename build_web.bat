@echo off
setlocal
set ROOT=%~dp0
if "%ROOT:~-1%"=="\" set ROOT=%ROOT:~0,-1%
set GODOT_EXE=%ROOT%\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64.exe
if not exist "%GODOT_EXE%" set GODOT_EXE=godot
set OUT_DIR=%ROOT%\build\web
if exist "%OUT_DIR%" rmdir /s /q "%OUT_DIR%"
mkdir "%OUT_DIR%"
set OUT_HTML=%OUT_DIR%\index.html
if not exist "%ROOT%\export_presets.cfg" (
  echo Missing export_presets.cfg. Open Godot ^> Project ^> Export, add "Web" preset, then retry.
  exit /b 1
)
set TEMPLATE_DIR=%APPDATA%\Godot\export_templates\4.6.1.stable
if not exist "%TEMPLATE_DIR%\web_release.wasm32.zip" (
  if not exist "%TEMPLATE_DIR%\web_release.zip" (
    echo Missing Web export templates. Install via Godot ^> Editor ^> Manage Export Templates.
    exit /b 1
  )
)
set PACK_LOG=%OUT_DIR%\pack.log
"%GODOT_EXE%" --headless --path "%ROOT%" --script "res://scripts/tools/PackConfigs.gd" > "%PACK_LOG%" 2>&1
if errorlevel 1 (
  echo Pack configs failed. See log: %PACK_LOG%
  exit /b 1
)
set LOG=%OUT_DIR%\export.log
"%GODOT_EXE%" --headless --path "%ROOT%" --export-release "Web" "%OUT_HTML%" > "%LOG%" 2>&1
if errorlevel 1 (
  echo Export failed. See log: %LOG%
  exit /b 1
)
if not exist "%OUT_HTML%" (
  echo Export finished but index.html not found. See log: %LOG%
  exit /b 1
)
set OUT_JS=%OUT_DIR%\index.js
if exist "%OUT_JS%" (
  powershell -NoProfile -Command "(Get-Content '%OUT_JS%' -Raw) -replace 'if \\(!Features\\.isSecureContext\\(\\)\\) \\{\\s*missing\\.push\\(''Secure Context - Check web server configuration \\(use HTTPS\\)''\\);\\s*\\}', '' | Set-Content '%OUT_JS%' -Encoding UTF8"
)
echo Exported: %OUT_HTML%
endlocal
