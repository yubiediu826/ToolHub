# UI 设计规范（ui-design-spec）

> SSOT：所有 UI 开发以本文件为基准。用户反馈的样式调整必须回写到本文件。
> 违反本规范的 UI 视为不合格，不允许提交。

## 1. 设计语言基准

Fluent Design 2 / WinUI 3 风格，基于 vendored FluentUI QML 框架（`FluentUI/`，上游 zhuzichu520/PySide6-FluentUI-QML）。

- **组件优先级**：先查 `.workflow/docs/fluentui-component-map.md`（组件目录）找 `Flu*` 组件；FluentUI 没有的，按第 6 节 WinUI 风格自绘规范实现，并注册为 `SerialCube_` 前缀共享组件。
- **禁止**：Qt 内置控件（Button/TextField/ComboBox 等）、硬编码颜色、硬编码字号、QML 内联 component。

## 2. 布局栅格

| 规则 | 值 |
|------|----|
| 基础栅格 | 8px |
| 控件圆角 | 4px（卡片 8px） |
| 页面左右边距 | 24px |
| 卡片间距 | 12px |
| 卡片内边距 | 16px |
| 表单行间距 | 8px |
| 控件标准高度 | 32px（紧凑 28px，工具栏 36px） |
| 内容区最大宽度 | 无限制（工具页铺满），设置页 720px 居中 |

## 3. 颜色（只用 FluTheme 语义色）

| 语义 | 引用 | 使用场景 |
|------|------|----------|
| 主色 | `FluTheme.primaryColor` | 主操作按钮、选中态、链接、进度条 |
| 前景 | `FluTheme.textColor` | 正文、标题 |
| 次级前景 | `FluTheme.textColorSecondary`（若无则 primaryColor 降透明度） | 辅助文字、说明 |
| 背景卡片 | `FluTheme.dark ? Qt.rgba(1,1,1,0.05) : Qt.rgba(0,0,0,0.03)` | 卡片底色 |
| 分隔线 | `FluTheme.dividerColor` | 分组分隔 |
| 成功 | `FluTheme.successColor`（若无用 Qt.lighter(primaryColor) 并登记到本表） | 连接成功、CRC 通过、在线状态 |
| 警告 | `FluTheme.warningColor` | 温度告警、非致命错误 |
| 错误 | `FluTheme.errorColor` | 打开失败、CRC 错误、离线 |
| 接收数据 | `FluTheme.textColor` | 日志中接收方向 |
| 发送数据 | `FluTheme.primaryColor` | 日志中发送方向（与接收区分） |

**双主题检查**：任何颜色改动必须在明/暗主题下各截图验证一次可读性。

## 4. 字体（只用 FluTextStyle）

| 层级 | 引用 | 用途 |
|------|------|------|
| 页面标题 | `FluTextStyle.Title` | PageHeader 标题 |
| 卡片标题 | `FluTextStyle.BodyStrong` | 卡片/分组标题 |
| 正文 | `FluTextStyle.Body` | 一般文字、表单值 |
| 辅助 | `FluTextStyle.Caption` | 说明、单位、时间戳 |
| 代码/日志 | `FluTextStyle.Body` + `font.family: "Consolas"` | HEX dump、日志视图（等宽字体例外允许） |

## 5. 页面布局模板

### 5.1 导航页标准结构

```
SerialCube_PageHeader(标题+副标题)
Column {
    左右边距 24, 卡片间距 12
    FluCard / SerialCube 包装卡片 × N
}
```

### 5.2 工具页三区结构（串口调试/监听等）

```
┌─ PageHeader ──────────────────────────────┐
├─ 参数区（横排表单卡，FluComboBox/FluTextBox）─┤ 高度固定，不随内容撑开
├─ 操作区（发送框/控制按钮卡）                    │
├─ 日志/数据区（FluScrollView + TextView）      │ 占满剩余高度，flex: 1
└──────────────────────────────────────────┘
```

- 参数区控件横向排列（端口 | 波特率 | 数据位 | 校验 | 停止位 | 流控 | 连接按钮）。
- 日志区必须铺满剩余空间；数据多时只滚动日志区，参数区不动。

### 5.3 卡片仪表盘栅格（协议解析）

- `GridLayout`，`columns: Math.max(2, Math.floor(pageWidth / 280))`。
- 数值卡：标题（Caption）+ 大数值（`FluTextStyle.Title`）+ 单位（Caption）。
- 进度卡（SOC 等）：标题 + FluProgressBar + 百分比。
- 状态卡：标题 + LED 状态灯（自绘）+ 状态文字。

## 6. 自绘组件规范（FluentUI 缺失组件）

适用：仪表盘（Gauge）、LED 状态灯、示波器/波形、HEX dump 视图。

- 用 QML `Canvas` + `FluTheme` 色绘制；尺寸通过属性暴露，不写死。
- **交互态**：可交互元素必须有 hover（边框或背景 `FluTheme.dark ? 0.06 : 0.03` 白/黑叠加）和 pressed（叠加加倍）效果。
- **焦点视觉**：可聚焦元素获得键盘焦点时显示 2px `FluTheme.primaryColor` 外框（WinUI focus stroke 风格）。
- **禁用态**：`enabled: false` 时整体透明度降至 0.4，不改变色相。
- **动效**：数值变化用 200ms 平滑动效（Behavior on 属性）；禁止长动画。
- 自绘组件完成后登记到 `fluentui-component-map.md` 的「自绘补充组件」表。

## 7. 图标

统一用 FluentUI 自带 Fluent 图标（`FluIcon`/`FluIcons`，参考 Example 的图标页）。禁止拼接 emoji 当图标。
