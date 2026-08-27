# .workflow — 工作流总入口

## 阅读顺序（新会话必读）

1. `AGENTS.md` — 8 条硬约束
2. `docs/code-conventions.md` — 目录/分层/命名/反模式
3. `docs/ui-design-spec.md` — UI 设计规范（栅格/颜色/字号/布局模板/自绘规范）
4. `docs/ui-acceptance.md` — UI 验收闭环（草案→截图自查→交付评审）
5. `docs/design-principles.md` — 6 条设计原则
6. `docs/master-plan.md` — 项目总体实施计划（三工具箱）
7. `decisions/` — 决策落档

## 目录

| 路径 | 内容 |
|------|------|
| `AGENTS.md` | AI 硬约束 H1-H8 |
| `docs/` | 规范文档 + 总体计划 |
| `decisions/` | 按日期落档的决策（含背景/选项/结论） |

## 项目目标

ToolHub：FluentUI 桌面工具箱，含三个核心工具：
1. **串口调试** — 串口数据收发 + 日志打印（参考 SerialTool-comm-v1.7.4 终端功能）
2. **串口监听** — 虚拟串口对桥接监听双向流量（类似 CommMonitor 串口监控精灵）
3. **多协议解析器** — 用户配置 TLV 自定义协议 / Modbus RTU 后自动解析并生成卡片仪表盘（参考 BMS/EMS 上位机）
