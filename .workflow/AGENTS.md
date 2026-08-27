# AGENTS.md — ToolHub AI 硬约束

进入本仓库的任何 AI 会话，写代码前必须遵守以下硬约束（H1-H8）。

- **H1 先读规范**：动手前按序读 `.workflow/README.md` → `docs/code-conventions.md` → `docs/ui-design-spec.md` → `docs/ui-acceptance.md`。
- **H2 FluentUI-first**：UI 只用 `Flu*` 组件；缺失组件按 ui-design-spec 第 6 节自绘为 `SerialCube_*`。禁止 Qt 内置控件。
- **H3 无硬编码样式**：颜色只用 `FluTheme.*`，字号只用 `FluTextStyle.*`（等宽 family 例外）。反模式清单见 code-conventions 第 7 节，提交前 0 容忍。
- **H4 分层**：QML 只做展示；业务逻辑在 Python QObject，Signal/Slot 桥接；串口 I/O 在 QThread Worker，UI 线程禁止阻塞。
- **H5 UI 验收闭环**：页面级新 UI 必须先出草案给用户确认，完成后截图（明/暗主题）自查并交付评审（见 docs/ui-acceptance.md）。
- **H6 vendored 框架只读**：`FluentUI/` 目录不修改；需要的扩展在外面包装。
- **H7 版本管理**：阶段完成必须 `.\bump-version.ps1` + 更新 CHANGELOG.md（Keep a Changelog）。
- **H8 终端 UTF-8**：Windows 终端先 `.\set-utf8.ps1`，避免中文乱码。

## 工作流入口

- 规范文档：`.workflow/docs/`（ui-design-spec / code-conventions / design-principles / ui-acceptance）
- 决策记录：`.workflow/decisions/YYYY-MM-DD_*.md`
- 总体计划：`.workflow/docs/master-plan.md`
- 交接总览：`HANDOVER.md`
