@echo off
setlocal
set GODOT_EXE=%GODOT_EXE%
if "%GODOT_EXE%"=="" set GODOT_EXE=godot
%GODOT_EXE% --headless --path "%~dp0.." --script "res://scripts/tools/PackConfigs.gd"
if errorlevel 1 (
	echo 打包失败：请设置 GODOT_EXE 指向 Godot 可执行文件
	exit /b 1
)
endlocal
