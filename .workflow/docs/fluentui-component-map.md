# FluentUI 组件目录映射（fluentui-component-map）

> FluentUI-first 查表入口：做 UI 前先在这里找。来源：vendored `FluentUI/` 与 `Example/` 示例。自绘组件完成后登记到第 2 节。

## 1. 常用 Flu* 组件 → 使用场景

| 需求 | 组件 | 备注 |
|------|------|------|
| 按钮 | `FluButton` / `FluFilledButton` / `FluToggleButton` | 主操作用 Filled |
| 下拉选择 | `FluComboBox` | 端口/波特率/校验等参数 |
| 文本输入 | `FluTextBox` / `FluTextArea` / `FluPasswordTextBox` | |
| 开关 | `FluToggleSwitch` | hex 模式、时间戳开关 |
| 复选 | `FluCheckBox` | |
| 滑块 | `FluSlider` / `FluRangeSlider` | |
| 进度 | `FluProgress` / `FluProgressBar` | SOC 卡片 |
| 卡片 | `FluCard` / `FluExpander` | 参数卡/分组 |
| 滚动区 | `FluScrollView` / `FluTreeView` | 日志视图容器 |
| 提示 | `FluContentDialog` / `FluToast` | 错误提示用 Toast |
| 菜单 | `FluMenu` / `FluMenuBar` | 右键菜单 |
| 工具栏 | `FluToolBar` / `FluIconButton` | |
| 表格 | `FluTableView` | 字段表编辑、监听时间线 |
| 页面指示 | `FluPivot` / `FluTabBar` | 页内子标签 |
| 图标 | `FluIcon` + Fluent 图标集 | 禁 emoji |
| 文字样式 | `FluTextStyle.*` | 见 ui-design-spec 第 4 节 |
| 主题 | `FluTheme.*` | 见 ui-design-spec 第 3 节 |

（开发中遇到新组件需求，先在 `Example/doc/` 预览图和 `FluentUI/` 源码中检索，找到后补进本表。）

## 2. 自绘补充组件（SerialCube_*）

| 组件 | 文件 | 状态 |
|------|------|------|
| 页头 | `Components/SerialCube_PageHeader.qml` | 已有 |
| 占位页 | `Components/SerialCube_Placeholder.qml` | 已有 |
| 首页卡片 | `Components/SerialCube_CardItem.qml` | 已有 |
| 设置行 | `Components/SerialCube_SettingsRow.qml` | 已有 |
| 信息行 | `Components/SerialCube_InfoRow.qml` | 已有 |
| 数值卡（仪表盘） | 待建 | 阶段 2 |
| 进度卡（SOC） | 待建 | 阶段 2 |
| 状态卡 + LED 灯 | 待建 | 阶段 2 |
| Gauge 圆形仪表 | 待建 | 阶段 2 |
| HEX dump 行视图 | 待建 | 阶段 1/3 |
