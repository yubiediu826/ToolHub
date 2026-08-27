# 代码规范（code-conventions）

> 适用于 PySide6 3.11.9 + FluentUI QML 项目。提交前自查反模式清单（第 7 节）。

## 1. 目录结构

```
ToolHub/                          ← 仓库根（git）
├── .workflow/                    ← 工作流与规范（本目录）
├── FluentUI/                     ← vendored 上游框架（只读，不改）
├── ToolHub/
│   ├── main.py                   ← 入口
│   ├── imports/ToolHub/qml/
│   │   ├── App.qml / main.qml
│   │   ├── global/               ← NavModel/NavFooter 等 singleton
│   │   ├── Components/           ← SerialCube_* 共享组件（前缀强制）
│   │   └── page/                 ← T_*.qml 页面
│   ├── serial/                   ← 串口域：serial_worker.py / rx_log.py
│   ├── protocol/                 ← 协议域：tlv.py / modbus_rtu.py / framer.py
│   ├── monitor/                  ← 监听域：bridge.py / session.py
│   └── i18n 资源等
├── env.py / script-*.py / run.bat / VERSION / CHANGELOG.md
```

## 2. 分层原则（最重要）

- **QML 只做展示与交互**。业务逻辑（串口读写、协议解析、文件 IO）一律在 Python。
- Python 通过 `QObject` + `Signal` / `Slot` / `Property` 暴露给 QML，在 `main.py` `setContextProperty` 注册。
- **禁止** QML 内写业务（如用 JS 解析协议帧、QML 直接操作文件）。
- 每个 Worker 类一个 `.py` 文件，可独立单测。

## 3. 命名

| 对象 | 规范 | 例 |
|------|------|----|
| QML 文件 | PascalCase，组件加 `SerialCube_` 前缀 | `SerialCube_GaugeCard.qml` |
| QML 页面 | `T_` 前缀 PascalCase | `T_Serial.qml` |
| QML id | 小驼峰 | `serialWorker` |
| Python 模块/函数/变量 | snake_case | `serial_worker.py` |
| Python 类 | PascalCase | `SerialWorker` |
| Qt 信号 | `xxxChanged`（Property 配套）或动词过去式事件 | `dataReceived` |
| Slot | 动词开头 | `openPort()` `sendData()` |

## 4. 线程模型

- 串口/网络/桥接 I/O 一律放独立 `QThread` Worker，UI 线程只通过 Signal 收数据。
- Worker 对外只暴露：`start`/`stop`、参数 Property、数据/状态 Signal。
- 高频数据（串口接收）先在 Worker 内做缓冲与格式化，按 16ms 周期批量 emit 到 UI，避免每字节一次 Signal。

## 5. 配置持久化

- 用户配置（串口参数、协议定义）统一 JSON 存 `%APPDATA%/ToolHub/`（`QStandardPaths.AppConfigLocation`）。
- 协议定义文件格式版本化（`{"version": 1, ...}`），加载时校验。

## 6. i18n

- 所有用户可见文案用 `qsTr()`，中文原文直接写，通过 `.ts/.qm` 翻译。
- 纯技术字符串（"COM3"、"0x5A"）不翻译。

## 7. 反模式清单（commit 前 0 容忍）

- [ ] 0 硬编码颜色（`#FFFFFF`、`Qt.rgba` 裸值）→ 必须用 `FluTheme.*`
- [ ] 0 硬编码字号（`font.pixelSize: 14` 裸值）→ 必须用 `FluTextStyle.*`（等宽字体 family 除外）
- [ ] 0 Qt 内置控件（Button/TextField/ComboBox/TableView…）→ 必须用 `Flu*`
- [ ] 0 QML 内联 component → 抽 `SerialCube_*` 文件
- [ ] 0 QML 业务逻辑 → 下沉 Python
- [ ] 0 未 qsTr 的用户文案
- [ ] 0 UI 线程阻塞 I/O

## 8. 版本与提交

- 每个阶段完成跑 `.\bump-version.ps1 -BumpType minor/patch`，CHANGELOG 按 Keep a Changelog 记录。
- 提交信息格式：`<scope>: <摘要>`，如 `serial: 实现串口收发 Worker`、`docs: 补充 UI 设计规范`。
