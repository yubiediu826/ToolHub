# ============================================================
# ToolHub · bump-version.ps1
# ============================================================
# 用途: 升级 VERSION 文件 + 提示更新 CHANGELOG.md + 打 git tag
#
# 决策依据: .workflow/decisions/2026-08-26_version-management.md
# 守门: AGENTS.md H7 (commit 前必跑)
#
# 用法:
#   PS> .\bump-version.ps1 -BumpType patch    # 1.0.0 -> 1.0.1
#   PS> .\bump-version.ps1 -BumpType minor    # 1.0.0 -> 1.1.0
#   PS> .\bump-version.ps1 -BumpType major    # 1.0.0 -> 2.0.0
#   PS> .\bump-version.ps1 -SetVersion 2.0.0  # 直接设 (少用)
#
# 自动做的事:
#   1. 读当前 VERSION
#   2. 算新版本
#   3. 写 VERSION
#   4. 提示"去 CHANGELOG.md 加 [X.Y.Z] 段"
#   5. (若在 git 仓) git tag v<NEW_VERSION>
#   6. (若在 git 仓 + 有 gh CLI) gh release create v<NEW.VERSION> --draft
#
# 守门:
#   拒绝 VERSION 含非数字(如 "1.0.0-beta")
#   拒绝 < 1.0.0
#   拒绝 git 工作区有未提交修改(除非 -Force)
# ============================================================

param(
    [ValidateSet("major", "minor", "patch")]
    [string]$BumpType,

    [string]$SetVersion,

    [switch]$Force
)

$ErrorActionPreference = 'Stop'

# 文件路径
$versionFile = Join-Path $PSScriptRoot "VERSION"

# 读当前版本
if (-not (Test-Path $versionFile)) {
    Write-Error "VERSION 文件不存在: $versionFile"
    exit 1
}
$currentVersion = (Get-Content $versionFile -Raw).Trim()

if ($currentVersion -notmatch '^\d+\.\d+\.\d+$') {
    Write-Error "VERSION 格式错(需 SemVer X.Y.Z): '$currentVersion'"
    exit 1
}

# 算新版本
if ($SetVersion) {
    if ($SetVersion -notmatch '^\d+\.\d+\.\d+$') {
        Write-Error "SetVersion 格式错(需 SemVer X.Y.Z): '$SetVersion'"
        exit 1
    }
    $newVersion = $SetVersion
} else {
    if (-not $BumpType) {
        Write-Error "需要 -BumpType (major/minor/patch) 或 -SetVersion X.Y.Z"
        exit 1
    }
    $parts = $currentVersion -split '\.'
    [int]$major = $parts[0]
    [int]$minor = $parts[1]
    [int]$patch = $parts[2]
    switch ($BumpType) {
        "major" { $major++; $minor = 0; $patch = 0 }
        "minor" { $minor++; $patch = 0 }
        "patch" { $patch++ }
    }
    $newVersion = "$major.$minor.$patch"
}

Write-Host "VERSION: $currentVersion -> $newVersion" -ForegroundColor Cyan

# 写 VERSION
Set-Content -Path $versionFile -Value $newVersion -NoNewline
Write-Host "[OK] VERSION 文件已更新: $newVersion" -ForegroundColor Green

# 提示更新 CHANGELOG
Write-Host ""
Write-Host "-> 下一步: 编辑 CHANGELOG.md,在 [Unreleased] 之上加 [${newVersion}] - <日期> 段" -ForegroundColor Yellow
Write-Host "  例: ## [$newVersion] - $(Get-Date -Format 'yyyy-MM-dd')" -ForegroundColor Yellow
Write-Host ""

# git tag (若有 git 仓)
$gitDir = Join-Path $PSScriptRoot ".git"
if (Test-Path $gitDir) {
    $status = git status --porcelain 2>&1
    if ($status -and -not $Force) {
        Write-Warning "git 工作区有未提交修改:"
        Write-Warning $status
        Write-Warning "先用 'git add . && git commit' 或 -Force 跳过"
        exit 2
    }
    $tag = "v$newVersion"
    git tag $tag
    Write-Host "[OK] git tag 已打: $tag" -ForegroundColor Green

    # gh release create (若有 gh CLI + -Force 模式可自动)
    $ghPath = Get-Command gh -ErrorAction SilentlyContinue
    if ($ghPath -and $Force) {
        gh release create $tag --draft --title "ToolHub $tag" --notes "See CHANGELOG.md"
        Write-Host "[OK] GitHub release draft 已创建: $tag" -ForegroundColor Green
    } elseif ($ghPath) {
        Write-Host "-> 手动跑: gh release create $tag --draft --title 'ToolHub $tag' --notes 'See CHANGELOG.md'" -ForegroundColor Yellow
    }
} else {
    Write-Host "-> 初始化 git 后再打 tag: git init && git add . && git commit -m 'chore: initial commit' && git tag $tag" -ForegroundColor Yellow
}
