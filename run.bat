@echo off
REM 启动 ToolHub —— 双击此文件即可
chcp 65001 >nul
title ToolHub

REM 优先用 py launcher（推荐装 3.11.x）
where py >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    py -3.11 script-start.py %*
    goto :end
)

REM 回退到 python 命令
where python >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    python script-start.py %*
    goto :end
)

echo.
echo [ERROR] Python not found.
echo         Install Python 3.11+ from https://www.python.org/downloads/
echo         (记得勾选 "Add Python to PATH")
echo.
pause
exit /b 1

:end
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [INFO] 程序退出码: %ERRORLEVEL%
    pause
)
