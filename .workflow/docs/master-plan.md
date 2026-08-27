# ToolHub 总体实施计划（master-plan）

> 2026-08-27 制定并经用户确认。技术栈：PySide6 3.11.9 + FluentUI QML。主项目 `D:\WorkSpace\ToolHub\ToolHub`，Example 仅作参考。

## 阶段 0：工作流搭建（本次完成）

- `.workflow/` 规范体系：AGENTS.md / ui-design-spec / code-conventions / design-principles / ui-acceptance / fluentui-component-map
- 4 项决策落档 decisions/
- git init + .gitignore + 首次提交

## 阶段 1：串口调试（v1.1.0，T_Serial 页）

- `ToolHub/serialport/serial_worker.py`：QThread 封装 pyserial（枚举/开关/读写/hex-text/定时循环发送），16ms 批量 emit。
- `ToolHub/serialport/rx_log.py`：接收缓冲 + hexdump/时间戳/收发着色。
- QML 三区布局：参数卡（FluComboBox：端口/波特率 1200~2000000/数据位/校验/停止位/流控 + 连接按钮）、发送卡、日志区（暂停/清空/保存）。
- 验收：真实串口对测收发；UI 走验收闭环。

## 阶段 2：多协议解析 + 卡片仪表盘（v1.2.0，新页「协议解析」）

- `ToolHub/protocol/tlv.py`：可配置自定义帧（帧头 0x5A/0xAAAA、地址、命令字、长度、CRC16-Modbus），字段表驱动（名称/偏移/类型/缩放/单位）；BMS、EMS 预设。
- `ToolHub/protocol/modbus_rtu.py`：功能码 01/02/03/04/0F/10，寄存器映射表解析。
- `ToolHub/protocol/framer.py`：流式分帧（半包/粘包）。
- 协议配置 UI（字段表编辑 + JSON 持久化 %APPDATA%/ToolHub/）+ 仪表盘（数值卡/进度卡/状态卡栅格，Gauge 用 Canvas 按 ui-design-spec 自绘）。

## 阶段 3：串口监听（v1.3.0）

- com0com 虚拟串口对 + `ToolHub/monitor/bridge.py` 纯 Python 双向桥接转发并镜像流量；安装引导页。
- 监听页：时间线视图（方向/时间戳/hexdump），联动协议解析引擎，会话导出 csv。

## 阶段 4：收尾

- 填 zh_CN 翻译（99 messages）、PyInstaller 打包验证、每阶段 bump-version + CHANGELOG。

## 风险

- 串口监听依赖用户安装 com0com 驱动（一次性，向导引导）。
- 截图验收依赖 ZCode 屏幕截图能力（当前环境具备）。
