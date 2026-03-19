@echo off
setlocal
set ROOT=%~dp0
if "%ROOT:~-1%"=="\" set ROOT=%ROOT:~0,-1%
set GODOT_EXE=%ROOT%\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64.exe
if not exist "%GODOT_EXE%" set GODOT_EXE=godot
set OUT_DIR=%ROOT%\build
if not exist "%OUT_DIR%" mkdir "%OUT_DIR%"
set OUT_EXE=%OUT_DIR%\ai_game.exe
if not exist "%ROOT%\export_presets.cfg" (
  echo Missing export_presets.cfg. Open Godot ^> Project ^> Export, add "Windows Desktop" preset, then retry.
  exit /b 1
)
set TEMPLATE_DIR=%APPDATA%\Godot\export_templates\4.6.1.stable
if not exist "%TEMPLATE_DIR%\windows_release_x86_64.exe" (
  echo Missing export templates. Install via Godot ^> Editor ^> Manage Export Templates.
  exit /b 1
)
if not exist "%TEMPLATE_DIR%\windows_debug_x86_64.exe" (
  echo Missing export templates. Install via Godot ^> Editor ^> Manage Export Templates.
  exit /b 1
)
set PACK_LOG=%OUT_DIR%\pack.log
"%GODOT_EXE%" --headless --path "%ROOT%" --script "res://scripts/tools/PackConfigs.gd" > "%PACK_LOG%" 2>&1
if errorlevel 1 (
  echo Pack configs failed. See log: %PACK_LOG%
  exit /b 1
)
set LOG=%OUT_DIR%\export.log
"%GODOT_EXE%" --headless --path "%ROOT%" --export-release "Windows Desktop" "%OUT_EXE%" > "%LOG%" 2>&1
if errorlevel 1 (
  echo Export failed. See log: %LOG%
  exit /b 1
)
if not exist "%OUT_EXE%" (
  echo Export finished but exe not found. See log: %LOG%
  exit /b 1
)
echo Exported: %OUT_EXE%
endlocal
