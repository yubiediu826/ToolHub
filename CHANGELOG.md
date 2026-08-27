# Changelog

All notable changes to ToolHub will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2026-08-27

### Added
- **工作流规范体系** (`.workflow/`): AGENTS.md 硬约束 H1-H8、UI 设计规范 (WinUI 3 基准/语义色/字号层级/布局模板)、代码规范 (QML 只做展示/业务下沉 Python/线程模型)、UI 验收闭环 (草案→截图自查→交付评审)、设计原则、FluentUI 组件目录映射、总体实施计划 master-plan；4 项决策落档 decisions/
- **串口调试 T_Serial 页** (参考 VOFA+ 布局 + SerialTool v1.7.4 功能):
  - 左侧设置栏: 连接设置 (串口/波特率/数据位/校验位/停止位/流控 + 打开/关闭)、数据区设置 (显示方式 文本/HEX、字符编码 自动/UTF-8/GBK、自动换行、显示时间戳、时间分包 ms、最大行数、冻结显示)、发送区设置 (HEX 发送、追加换行 CR/LF/CRLF、定时发送 ms、本地回显)
  - 右侧数据区: 等宽字体日志视图、A-/A+ 字号调节、自动吸底滚动、空态提示
  - 右侧发送区: 多行输入、发送历史 (10 条)、清空、定时循环发送
  - 底部状态栏: 连接状态灯、RX/TX 字节数·包数·速率实时统计
- **串口后端** `ToolHub/serialport/` (包名不可用 serial/ 会遮蔽 pyserial):
  - `serial_worker.py`: pyserial 线程读循环、参数配置、hex/text 发送、追加换行、本地回显、16ms 批量 Signal 上报
  - `rx_log.py`: 时间分包聚合、文本/HEX 视图、自动/UTF-8/GBK 解码、时间戳模式、自动换行、最大行数裁剪、冻结显示、RX/TX 字节/包/速率统计、日志保存到 Downloads
- git 仓库初始化 + .gitignore + 首次提交

### Verified
- COM20↔COM21 虚拟串口回环实测: HEX 发送 48 65 6C 6C 6F → 对端收到 `48 65 6c 6c 6f`，对端回发被记录为 RX，时间戳/方向/分包/统计正确

## [1.0.5] - 2026-08-26

### Fixed
- **导航视图自动模式 footer (设置/关于) 点击也展开 sidebar**: 业务态 2 footer item 之前走 v5 helper toggle (跟 NavModel 一样), 用户反馈"自动模式设置和信息保持紧凑, 点击图标不需要展开" (16:20 反馈)
  - 修法: NavFooter.qml onTap 改成**全部业务态 (0/1/2) 单纯 push**, 不调 helper
  - 业务态 0/1 锁死 (跟 v7 一致, 单纯 push 不切 displayMode)
  - 业务态 2 footer 单纯 push 不切 displayMode (用户 16:20 反馈)
  - 主区 NavModel 业务态 2 仍走 v5 helper toggle (跟原话"点击图标展开" 一致)
  - expander 父项 "工具" 业务态 2 走库 _navAutoMode 守卫 toggle (v9)

## [1.0.4] - 2026-08-26

### Fixed
- **导航视图自动模式"点击工具 expander 父项不展开"**: v1.0.3 撤销库行 227-248 vendor 改动后, 业务态 2 (自动) expander 父项也走库默认 popup 行为, 不切 displayMode — 跟用户原话"自动: 默认折叠 + 点击图标展开 + 再次点击折叠" 描述矛盾 (16:17 反馈)
  - 修法: 库 onClicked 加 `control._navAutoMode` 守卫 (3 选 1):
    - 业务态 0/1: 走 Example 库默认 popup 行为 (锁死, 跟 v1.0.3 一致)
    - 业务态 2: 走 v3 决策 toggle 行为 (Compact→Open / Open→Compact, 跟搜索栏自动展开一致)
  - 库加 `property bool _navAutoMode: false` (default = popup 行为, 兼容 Example)
  - ToolHub 业务层 Settings.applyNavMode / setNavMode 同步设 `navView._navAutoMode = (navMode === 2)`
  - 库不能直接 import ToolHub.Settings (QML 边界), 用 _navAutoMode property 中转

## [1.0.3] - 2026-08-26

### Fixed
- **导航视图紧凑/开放模式"点击工具 expander 父项依然可展开/折叠"**: v1.0.2 业务层 fix 不够 — ToolHub 库 `FluentUI/.../FluNavigationView.qml:227-248` 在 v1.0.0 之前被业务决策 (`2026-08-26_ui-nav-click-behavior.md` v3) 改过, 让 expander 父项 Compact→Open / Open→Compact 切 displayMode; 业务层 `FluPaneItemExpander` 无 tap signal / onTapListener, 拦截不了
  - 修法: **撤销库行 227-248 vendor 改动, 回到 Example 库默认 popup 行为** (22 行 → 11 行)
  - **突破 H1 守门** (不修 `FluentUI/`): 写决策 `2026-08-26_upstream-pr-restoration.md` 明示破 H1 原因 (用户授权 + 技术必要性 + 业务一致性)
  - v3 决策部分撤销 (`2026-08-26_ui-nav-click-behavior.md` 补段): expander onClicked 行为撤回, 由 upstream-pr-restoration 承接; 搜索栏自动展开仍有效 (独立路径)
  - 业务态 2 (自动) expander 父项不重建 toggle: 用户拍板"不重建", expander 父项也走库默认 popup; leaf 子项仍走 v5 helper toggle

## [1.0.2] - 2026-08-26

### Fixed
- **导航视图紧凑/开放模式"点击图标不可展开/折叠"**: v6 helper `fixedMode` 短路导致业务态 0/1 永远不切 `displayMode` (用户点图标只跳转页面, sidebar 状态不变), 跟 Example `T_Settings.qml:130-146` 范本行为不一致
  - 修法: helper 退回 v5 (删 `fixedMode` 短路), NavModel/NavFooter onTap 改成 `if (Settings.navMode === 2 && navModel.handleItemClick(...)) return` 业务态 2 走 v5 toggle / 0/1 单纯 `navView.push(url)` 跟 Example ItemsOriginal 一样
  - Settings.applyNavMode 0/1 仍用库原生 `FluNavigationViewType.Compact/Open` 常量 (跟 Example 直接 `GlobalModel.displayMode = FluNavigationViewType.Compact` 等同)

## [1.0.1] - 2026-08-26

### Added
- **导航视图模式可配置(3 选 1)**：设置 → 通用 → 导航视图
  - **紧凑**：库原生 `FluNavigationViewType.Compact` (跟 Example 选 Compact 视图一致)
  - **开放**：库原生 `FluNavigationViewType.Open` (跟 Example 选 Open 视图一致)
  - **自动**(默认)：业务态, 启动 Compact + 点图标展开 + 再次点同一图标折叠
- **Settings singleton** (`qml/global/Settings.qml`)：业务态封装 + `QtCore.Settings` 持久化(替代 deprecated `Qt.labs.settings`)
- **SerialCube_NavToggleHelper v5→v6→v7**：v7 退回 v5 简化版, helper 只服务业务态 2 (自动 toggle)
- **T_Settings 导航视图配置行**：`FluRadioButtons` 3 个 + 自动模式说明文字

### Changed
- **main.py 显式 `setOrganizationName` / `setApplicationName`**：QSettings 落 `Software\ToolHub\ToolHub` 命名空间(避免污染默认组织)
- **main.qml 启动序列**：在 `setCurrentIndex(0)` 之前先 `Settings.applyNavMode()`, 业务态 Auto 强制启动 Compact(覆盖库默认 Auto+width>900=Open)
- **qml/global/qmldir + resource.qrc**：注册 Settings singleton + Settings.qml

## [1.0.0] - 2026-08-26

### Added
- **Catalog SSOT**: 5 份 FluentUI 文档(selecting.md / components.md / icons.md / README.md / preflight-checklist.md),合计 56KB
- **5 个 SerialCube_* 包装组件**:
  - `SerialCube_PageHeader.qml` - 页面顶部色条+图标+标题+副标题
  - `SerialCube_Placeholder.qml` - "页面建设中"占位
  - `SerialCube_CardItem.qml` - 首页卡片(FluFrame + FluShadow)
  - `SerialCube_SettingsRow.qml` - 设置行(标签+右侧控件)
  - `SerialCube_InfoRow.qml` - 关于页信息行
  - `SerialCube_NavToggleHelper.qml` - 侧边栏点击行为共享逻辑
- **NavModel + NavFooter 共享 helper** (L1 重构,DRY)
- **11 个 page 全部用包装组件**, 零硬色/硬字号/Qt 内置控件/内联 component
- **AGENTS H6 硬约束**: FluentUI 优先(原 S1 升 H)
- **5 问 preflight 自检清单**: preflight-checklist.md
- **i18n 工作流恢复**: 99 messages 含今晨新加 10 个(待人工填翻译)
- **terminal-utf8 skill**: set-utf8.cmd + .ps1, 修 PowerShell 中文乱码

### Changed
- **整个 .workflow/ 清理**: 移除 10 项无用文件(_superpowers/ 7 skill + sample-refs/ + 2 templates/ + 1 test_scaffolding.py + 1 INIT)
- **AGENTS.md 升级**: S1 → H6,加 H7(版本)+H8(终端 UTF-8)硬约束
- **NavModel / NavFooter 重构**: 抽 SerialCube_NavToggleHelper
- **i18n 路径修复**: main.py `project_` → `ToolHub_` 前缀,匹配 resource.qrc
- **resource.qrc 增补**: Components/ 包装组件注册(6 个 .qml + qmldir)
- **main.qml darkMode 切换**: 修 System 模式正确处理(0→2 而非 1)
- **CardItem 三态视觉反馈**: pressed / hovered / normal 色切换
- **PageHeader 显式 width binding**: `width: parent ? parent.width : 0`
- **CardItem 删内嵌 Rectangle 边框**: 避免双层边框
- **NavToggleHelper toggle 闭环**: 3 次修复(currentUrl/getCurrentUrl/lastClickedUrl)

### Fixed
- **侧边栏重复点同一图标无法折叠** (3 次修复, 12:24 / 12:30 / 12:33)
- **i18n 翻译路径完全错配** (`project_` vs `ToolHub_`)
- **Components/ 未在 resource.qrc 注册** → qrc 模式下 import "../Components" no such directory
- **qmldir 错标 singleton** (PageHeader/Placeholder 不是 singleton)
- **T_Home 内联 CardItem component** 抽到 SerialCube_CardItem
- **T_About 硬 pixelSize / 硬 rgba 分隔线** 改用 FluTextStyle.Caption / FluDivider
- **T_Settings 用 Qt ComboBox** 改 FluComboBox

### Documentation
- `.workflow/decisions/2026-08-26_fluentui-first-refactor.md` - 重构总决策
- `.workflow/decisions/2026-08-26_workflow-cleanup.md` - workflow 清理
- `.workflow/decisions/2026-08-26_code-review-fixes.md` - 6 项 review 修复
- `.workflow/decisions/2026-08-26_components-ssot.md` - catalog SSOT
- `.workflow/decisions/2026-08-26_no-hardcoded-style.md` - 反模式 H 约束
- `.workflow/decisions/2026-08-26_patch-nav-toggle-helper.md` - 3 次 toggle 修复
- `.workflow/decisions/2026-08-26_terminal-utf8.md` - PowerShell 乱码修复
- `docs/superpowers/plans/2026-08-26_toolhub-fluentui-refactor.md` - 重构 plan
- `docs/superpowers/plans/2026-08-26_version-management.md` - 本 plan

## [Unreleased] - 计划中

### Removed
- **侧边栏折叠按钮** (`item_toggle_sidebar`): v5 helper 重复点图标折叠完全替代
- **收藏分组** (NavModel.favExpander + T_FavCommon/T_FavWorkflow): tool-launcher MVP 不需要
- **最近分组** (NavModel.recentExpander + T_RecentToday/T_RecentWeek): 同上
- **4 个 page 文件**: 移到回收站(mavis-trash 可恢复)
- **4 个 FluRouter 路由** + **4 个 resource.qrc 注册** 同步删除

### Planned
- (暂无;下个 release 周期开始填)
