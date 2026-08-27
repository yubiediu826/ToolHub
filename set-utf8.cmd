@echo off
REM ============================================================
REM ToolHub · set-utf8.cmd
REM ============================================================
REM 用途: 在 cmd.exe session 中 source 此文件,把 console
REM       / Python 子进程 encoding 切到 UTF-8。
REM
REM 决策依据: .workflow/decisions/2026-08-26_terminal-utf8.md
REM
REM 用法 1(在 cmd.exe 中,推荐): 直接执行
REM     > set-utf8.cmd
REM
REM 用法 2(在 .bat 链式调):
REM     call set-utf8.cmd
REM     python script-start.py
REM
REM 用法 3(PowerShell session): 直接运行
REM     PS> .\set-utf8.cmd
REM     然后手动:
REM       $OutputEncoding = [System.Text.Encoding]::UTF8
REM       [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
REM
REM 用法 4(Mavis bash 工具 — 当前 session):
REM     .\set-utf8.cmd
REM     <command>
REM     必须在每次开新 bash 工具调用前 source 一次
REM ============================================================

REM 1. 改 console code page 到 65001 (UTF-8) — cmd.exe 立即生效
chcp 65001 >nul

REM 2. 设 Python 子进程 encoding 环境变量
set PYTHONIOENCODING=utf-8
set PYTHONUTF8=1

REM 3. 输出确认
echo [OK] Console encoding set to UTF-8 (chcp 65001, PYTHONUTF8=1)
