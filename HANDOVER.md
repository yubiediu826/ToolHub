# ToolHub · 交接文档

> **项目**: ToolHub — 基于 FluentUI 的桌面工具中心 (`tool-launcher` 类型)
> **作者**: yubiediu826
> **提交日期**: 2026-08-26
> **版本**: v1.0.0 (SemVer 起点,见 `VERSION` 文件)
> **上游**: [zhuzichu520/PySide6-FluentUI-QML](https://github.com/zhuzichu520/PySide6-FluentUI-QML)
> **仓库**: [github.com/yubiediu826/SerialCube](https://github.com/yubiediu826/SerialCube)

---

## 一句话项目目标

构建一个**桌面工具中心**(类似 Windows 设置 / macOS Launchpad / VS Code 资源管理器),左侧导航 + 右侧内容,基于 PySide6 + FluentUI QML。

---

## 架构(1 张图说清)

```
┌─ ToolHub 仓 (D:\WorkSpace\ToolHub\ToolHub) ─┐
│                                                                              │
│  FluentUI/                    ← vendored 上游框架(不动)                       │
│  ToolHub/                                                                       │
│    ├── main.py                  ← 入口(调 qasync + QQmlApplicationEngine)   │
│    ├── imports/                                                             │
│    │    ├── resource.qrc        ← Qt 资源清单(11 page + 5 Components)     │
│    │    ├── resource_rc.py      ← pyside6-rcc 自动生成(.gitignore)         │
│    │    └── ToolHub/                                                           │
│    │         ├── i18n/                                                            │
│    │         ├── image/                                                           │
│    │         └── qml/                                                            │
│    │              ├── App.qml           ← FluRouter.routes 注册               │
│    │              ├── main.qml          ← FluWindow + FluNavigationView        │
│    │              ├── global/                                                         │
│    │              │    ├── NavModel.qml        (singleton)  主页导航项         │
│    │              │    ├── NavFooter.qml       (singleton)  footer 项(设置/关于) │
│    │              │    └── qmldir                                                        │
│    │              ├── Components/                                                       │
│    │              │    ├── SerialCube_PageHeader.qml      页面顶部色条+标题            │
│    │              │    ├── SerialCube_Placeholder.qml     页面建设中占位                │
│    │              │    ├── SerialCube_CardItem.qml        首页卡片                    │
│    │              │    ├── SerialCube_SettingsRow.qml     设置行                        │
│    │              │    ├── SerialCube_InfoRow.qml         关于页信息行                │
│    │              │    ├── SerialCube_NavToggleHelper.qml 侧边栏 toggle 行为(共享)   │
│    │              │    └── qmldir                                                            │
│    │              └── page/                  (7 page: Home/Settings/About/Serial/Network/File/Data) │
│    └── main.py / env.py / set-utf8.cmd / set-utf8.ps1 / VERSION / CHANGELOG.md    │
│                                                                              │
│  .workflow/                                                                       │
│    ├── AGENTS.md                ← AI 行为准则(8 个 H 硬约束)                  │
│    ├── README.md                ← 工作流总入口                                   │
│    ├── PROFILE.md / PROFILES.md ← 工具类型声明                                    │
│    ├── BUILD.md / INIT_NEW_PROJECT.md                                          │
│    ├── skills/core/             ← 11 个项目本地 skill(qml-* 6 + qt-* 3 + ...)  │
│    ├── skills/sample-refs/                                                      │
│    ├── specs/                                                                       │
│    ├── decisions/               ← 13 份决策落档                                   │
│    ├── env/                      ← 环境规范 6 文件                              │
│    ├── docs/superpowers/plans/  ← 实施 plan                                     │
│    ├── _archive/                ← 精简时备份(.gitignore 排除)                  │
│    ├── VERSION / CHANGELOG.md / bump-version.ps1                                │
│    └── tools/                                                                        │
│                                                                              │
│  docs/                            ← 实施 plan 索引                            │
│  build/ dist/ .venv/ __pycache__/ *.qm *.qmlc     ← .gitignore 排除            │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## 当前状态(2026-08-26 v1.0.0)

### ✅ 已完成

| 维度 | 内容 |
|------|------|
| **FluentUI 框架集成** | 上游 [zhuzichu520/PySide6-FluentUI-QML](https://github.com/zhuzichu520/PySide6-FluentUI-QML) vendored 在 `FluentUI/` |
| **11 个 page → 7 个 page** | 保留 Home/Settings/About/Serial/Network/File/Data;**删**了 FavCommon/FavWorkflow/RecentToday/RecentWeek |
| **5 个业务包装组件** | `SerialCube_PageHeader` / `Placeholder` / `CardItem` / `SettingsRow` / `InfoRow` |
| **1 个共享 helper** | `SerialCube_NavToggleHelper` (侧边栏重复点图标折叠,替代手动折叠按钮) |
| **侧边栏** | 3 个 expander 分组(首页/工具/工具子项)+ footer(设置/关于),**无手动折叠按钮** |
| **11 个项目本地 skill** | qml-* (6) + qt-qml* (3) + terminal-utf8 (1) + version-management (1) — 全在 `.workflow/skills/`,**不依赖全局** |
| **13 份决策落档** | `.workflow/decisions/2026-08-*.md` |
| **版本管理 6 件套** | VERSION + CHANGELOG.md + bump-version.ps1 + AGENTS H7 + skill + decision |
| **PowerShell 乱码修复** | set-utf8.cmd + .ps1 + skill + AGENTS H8 |
| **0 反模式** | 0 硬色 / 0 硬字号 / 0 Qt 内置控件 / 0 内联 component |
| **i18n 工作流** | .ts 源 99 messages, .qm 编译产物 |

### 🚧 已知问题

| # | 问题 | 影响 | 后续 |
|---|------|------|------|
| 1 | i18n 翻译内容空(.qm 26 bytes, fallback 英文) | 用户界面英文/中文硬编码 | 人工填 `ToolHub_zh_CN.ts` 的 `<translation>` 段 → 重跑 `script-update-translations.py` |
| 2 | 4 个 page(T_Serial/Network/File/Data)都是 placeholder,无真实业务 | 工具分组点击只是"页面建设中" | M1 sprint 接 SerialWorker/NetworkWorker 实现真实功能 |
| 3 | v5 toggle 行为:helper 改 `control.displayMode` 永久脱离 Auto 模式 | 改窗口宽度后 sidebar 不会自动调整 | 接受 trade-off(固定窗口大小)或后续加 vendor 改动暴露 `d.isCompact` |
| 4 | Auto 模式 displayMode 在 helper toggle 后失效 | 改 window 宽度不响应 | 同上 |

### 📊 关键指标

```
项目文件总数: 50+ (active 排除 archive)
skill 数量: 11 (全项目本地)
decisions 数量: 13
CHANGELOG [1.0.0] 段: 40+ 变更项
page/ 目录: 7 个 page
包装组件: 5 个
反模式命中: 0 (硬色/硬字号/Qt 内置控件/内联 component)
```

---

## 启动命令

### 首次启动(完整)

```powershell
# Windows PowerShell 7+ / 5.1
cd D:\WorkSpace\ToolHub\ToolHub

# 1. 初始化 venv(首次, 5-10 分钟)
.\venv\Scripts\python.exe script-init-venv.py
# 或: py -3.11 script-init-venv.py

# 2. 设置 UTF-8(防止中文乱码)
.\set-utf8.ps1

# 3. 启动
.\run.bat
# 或: .\venv\Scripts\python.exe script-start.py
```

### 后续启动(快速)

```powershell
.\set-utf8.ps1; .\run.bat
# 或
.\venv\Scripts\python.exe script-start.py fast
```

### 其他脚本

| 命令 | 用途 |
|------|------|
| `.\bump-version.ps1 -BumpType patch` | 升级版本号 1.0.0 → 1.0.1 |
| `.\bump-version.ps1 -BumpType minor` | 升级版本号 1.0.0 → 1.1.0 |
| `.\venv\Scripts\python.exe script-update-translations.py` | 重新生成 .ts / .qm |
| `.\venv\Scripts\python.exe script-update-resource.py` | 重新编译 resource_rc.py |
| `.\venv\Scripts\python.exe script-build-pyinstaller.py` | 打包成 .exe |
| `.\venv\Scripts\python.exe script-build-nuitka.py` | 打包成单文件 .exe |

---

## 工作流(新会话必读)

### 第一次进项目的阅读顺序

1. **`AGENTS.md`** — 8 个 H 硬约束(H1-H8,含版本管理 + 终端 UTF-8)
2. **`README.md`** — 工作流总入口
3. **`PROFILE.md`** — 当前项目类型(`tool-launcher`)
4. **`PROFILES.md`** — 工具类型目录
5. **`CHANGELOG.md` `[1.0.0]` 段** — 40+ 变更项
6. **`decisions/` 目录** — 13 份决策落档
7. **`skills/core/qml-fluentui-catalog/references/preflight-checklist.md`** — 5 问自检
8. **HANDOVER.md**(本文件) — 总览

### 写代码前必走 5 问自检

任何 UI 改动前走 `preflight-checklist.md` 5 问:
1. 我查了 selecting.md 吗?
2. 我用 `Flu*` 吗?
3. 我用 `FluTheme.*` 颜色 + `FluTextStyle.*` 字号吗?
4. 我有重复模式吗?(→ 抽 `SerialCube_*` 包装)
5. 我跑了启动 + 健康检查吗?(commit 前必走 `bump-version.ps1`)

---

## 决策索引(13 份,按时间倒序)

| 日期 | 文件 | 类型 |
|------|------|------|
| 2026-08-26 | `2026-08-26_remove-fav-recent-toggle.md` | arch-simplification |
| 2026-08-26 | `2026-08-26_version-management.md` | arch-versioning |
| 2026-08-26 | `2026-08-26_terminal-utf8.md` | hard-constraint |
| 2026-08-26 | `2026-08-26_code-review-fixes.md` | code-review-fixes |
| 2026-08-26 | `2026-08-26_patch-nav-toggle-helper.md` | bug-fix-patch(3 次修复) |
| 2026-08-26 | `2026-08-26_no-hardcoded-style.md` | hard-constraint |
| 2026-08-26 | `2026-08-26_components-ssot.md` | docs-ssot |
| 2026-08-26 | `2026-08-26_fluentui-first-refactor.md` | arch-workflow-refactor |
| 2026-08-26 | `2026-08-26_workflow-cleanup.md` | arch-workflow-cleanup |
| 2026-08-26 | `2026-08-26_ui-nav-click-behavior.md` | ui-nav-click-behavior |
| 2026-08-23 | `2026-08-23_toolhub-nav-icon-spec.md` | ui-toolhub-icons |
| 2026-08-23 | `2026-08-23_tool-type-add-launcher.md` | tool-type-add- |
| 2026-08-23 | `2026-08-23_arch-workflow-generalize.md` | arch-workflow-generalize |

**复审日**: 2027-02-26 (6 个月后) — 每条决策加"复审"段,写"仍合理吗 / 需要反转吗"

---

## 项目本地 skill 原则(用户偏好)

`.workflow/skills/` 下的所有 skill **只在项目本地**,**绝不**复制到:
- `~/.minimax/skills/` (全局)
- `Mavis/.builtin-skills/` (全局)
- 任何其他项目仓

**理由**: 换设备/换 clone 仍可用,不依赖 Mavis 全局 skill 库。

评审历史(2026-08-26 12:42): ✅ 通过 — 0 处 Mavis / `~/.minimax` 引用。

---

## 技术栈

| 维度 | 选型 |
|------|------|
| Python | **3.11.9** (venv 必须在 `ToolHub/venv/`,禁止变体名) |
| PySide6 | **6.7.2** |
| Qt | **6.7.2** |
| qasync | **0.27.1** (asyncio ↔ Qt 事件循环桥) |
| UI 框架 | FluentUI (zhuzichu520/PySide6-FluentUI-QML 上游 vendor) |
| SemVer | 2.0.0 |
| 文档规范 | [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) 1.1 |
| 打包工具 | PyInstaller (推荐) + Nuitka (高级) |

---

## 环境要求

### Windows

- **Python 3.11.9** (PATH 默认 3.13 不可用,框架未适配)
- **Git** (任何版本,建议 2.30+)
- **Visual Studio Build Tools 2022** (Nuitka 打包需要)
- PowerShell 5.1+ (Windows PowerShell) 或 PowerShell 7+ (pwsh)

### Mac / Linux

- Python 3.11.9
- Qt6 系统依赖
- 改 `env.py` 的 `_scriptsPath()` (Windows→Unix)

---

## 后续 sprint 计划

### v1.1.0 (MINOR · 新功能)

| Task | 描述 |
|------|------|
| 1 | T_Serial 接 pyserial 真实串口(SerialWorker + 4ms/16ms 实时基线) |
| 2 | T_Network 接 asyncio 真实 TCP/UDP(NetworkWorker) |
| 3 | T_File 接 Qt 文件系统模型(批量重命名/格式转换) |
| 4 | T_Data 接 pandas CSV/JSON 导入(图表 + 透视表) |
| 5 | 填 `ToolHub_zh_CN.ts` 翻译(99 messages) |
| 6 | `script-build-pyinstaller.py` 验证打包成功 |

### v1.0.x (PATCH · 修)

| Task | 描述 |
|------|------|
| 1 | vendor 改动: 暴露 `FluNavigationView.d.isCompact` 作为 property(让 v5 toggle 不破坏 Auto 模式) |
| 2 | `getCurrentUrl()` NoStack 分支加 QUrl normalize 测试(避免再次 string 比较失败) |

### 后续 (v2.0+ · MAJOR)

- 多语言切换 UI(`FluComboBox` 选 zh_CN / en_US)
- 主题色自定义(`FluAccentColor`)
- 暗/亮模式自动跟随系统(目前是手动切换)
- Plugin 系统(`ToolHub/plugins/` 动态加载新工具)

---

## 复审 checklist (6 个月后 · 2027-02-26)

- [ ] 13 份 decisions 仍合理吗?逐条复审,反转不合时宜的
- [ ] `bump-version.ps1` 是否需要扩展支持 `1.0.0-beta.1` 等预发布?
- [ ] 翻译 `.ts` 是否已填完?`script-update-translations.py` 是否需要 CI 自动化?
- [ ] 4 个 placeholder page(T_Serial/Network/File/Data)是否已接真实功能?
- [ ] vendor 改动(暴露 `d.isCompact`)是否值得做?
- [ ] GitHub release 工作流是否启用(`gh release create` 自动化)?

---

## 联系方式

- **作者**: yubiediu826
- **GitHub**: https://github.com/yubiediu826
- **上游 UI 框架**: https://github.com/zhuzichu520/PySide6-FluentUI-QML
- **本仓库**: https://github.com/yubiediu826/SerialCube

---

**最后更新**: 2026-08-26 13:30
**版本**: v1.0.0
**状态**: 首次提交准备中
