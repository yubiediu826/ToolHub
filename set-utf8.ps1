# ============================================================
# ToolHub · set-utf8.ps1
# ============================================================
# 用途: 在 PowerShell session 里 source 此文件,把 console
#       / Python 子进程 encoding 切到 UTF-8。
#
# 决策依据: .workflow/decisions/2026-08-26_terminal-utf8.md
#
# 用法 1(直接执行,推荐):
#     PS> .\set-utf8.ps1
#
# 用法 2(source):
#     PS> . .\set-utf8.ps1
#
# 用法 3(Mavis bash 工具 — 每条命令前手动设):
#     Mavis 调 bash 工具时,第一行加:
#       . $env:TOOLHUB_ROOT\set-utf8.ps1
#     或
#       chcp 65001 | Out-Null; $OutputEncoding = [System.Text.Encoding]::UTF8
#
# 注意: Mavis bash 工具的每个 command 是新进程,
#       set-utf8.ps1 在 command 内 source,不会影响后续 command。
#       每个 command 都要 source 一次。
# ============================================================

# 1. 改 console code page 到 65001 (UTF-8)
chcp 65001 | Out-Null

# 2. 改 PowerShell 输出 encoding(2 个 property)
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# 3. 设 Python 子进程 encoding 环境变量
$env:PYTHONIOENCODING = "utf-8"
$env:PYTHONUTF8 = "1"

# 4. 设 PowerShell 默认参数 encoding(影响所有 cmdlet 的 -Encoding 默认值)
$PSDefaultParameterValues['*:Encoding'] = 'utf8'

# 5. 输出确认
Write-Host "[OK] Console encoding set to UTF-8 (chcp 65001, PYTHONUTF8=1, OutputEncoding=UTF-8)" -ForegroundColor Green
