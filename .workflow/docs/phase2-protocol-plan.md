# 阶段 2 计划：多协议解析器 + 卡片仪表盘

> 2026-08-27 制定。协议规格逆向自 BMS通信上位机-V2.03_test 与 EMS通讯测试上位机-V1.4.3 的 Form1.cs（字节级），
> 完整提取规格见文末附录（同时落档于本文件，作为 presets 的实现依据）。

## 一、协议引擎设计（ToolHub/protocol/）

两个参考协议结构高度同源：`帧头 + 地址 + 命令 + 长度 + 数据域 + 校验`，字段全小端、同类遥测布局。
因此不硬编码两种协议，而是实现**一个通用解析引擎**，BMS/EMS 都是它的 JSON 配置档（profile）：

```
protocol/
├── framer.py        # 流式分帧器：按 profile 帧描述做半包/粘包重组
├── profile.py       # Profile 模型 + JSON 加载/保存（version:1），内置校验
├── decoder.py       # 字段表解码：bytes → {key: value}，位域展开/枚举映射/无效值处理
├── checksums.py     # crc16_modbus(查表) / sum8_excl_headers / xor
├── modbus_rtu.py    # 标准 Modbus RTU 功能码解析（01-06/0F/10）
└── presets/
    ├── bms_ofo.json # BMS-OFO 预设（帧头 TX5A/RX55、CRC16-Modbus LE、命令 01-16）
    ├── ems_ofo.json # EMS-OFO 预设（帧头 AAAA、双字节地址、加和校验-扣0xAA、命令 E1-ED）
    └── *_cells.json 等扩展
```

### Profile JSON 结构（v1）

```json
{
  "version": 1,
  "name": "EMS-OFO",
  "framing": {
    "rx_header": "AAAA", "tx_header": "AAAA",
    "addr_offset": 2, "addr_len": 2,
    "cmd_offset": 4, "len_offset": 5,
    "data_offset": 6, "checksum": {"type": "sum8_minus_headers", "headers": [170,170], "size": 1}
  },
  "endian": "little",
  "commands": [
    {"cmd": "0xE2", "name": "BMS信息", "direction": "query", "interval_ms": 300},
    {"cmd": "0xEC", "name": "控制", "direction": "write"}
  ],
  "fields": {
    "0xE2": [
      {"offset": 8,  "type": "u16",   "name": "NTC1温度", "unit": "℃", "invalid": 65535, "signed": true},
      {"offset": 40, "type": "u32",   "name": "电流",     "unit": "mA", "sign_split": true},
      {"offset": 66, "type": "u8",    "name": "SOC",      "unit": "%",  "card": "progress"},
      {"offset": 104,"type": "u16[]", "count": 20, "name": "单体电压", "unit": "mV", "card": "cellgrid"},
      {"offset": 6,  "type": "bits",  "name": "保护状态",  "bits": ["放电高温","放电低温","充电高温","充电低温","单体过压L1","单体过压L2"], "card": "status"},
      {"offset": 17, "type": "ascii", "name": "EMS序号", "card": "text"}
    ]
  }
}
```

### 分帧规则（framer）

按 frame 描述逐字节滑窗：找到 rx_header → 读 len 域 → 计算总长（frame.total = data_offset + LEN +
checksum.size）→ 收齐后校验 checksum → 合法则连同 cmd 交付 decoder，失败则丢帧头继续扫描。

## 二、命令表与字段预设（来自逆向规格）

### BMS-OFO（TX 头 0x5A / RX 头 0x55，Addr=0x01，CRC16-Modbus 低前高后，覆盖 4+LEN）

| CMD | 名称 | 关键字段 |
|-----|------|----------|
| 0x01 | 心跳/实时状态(159B) | 保护/不可恢复故障/AFE 位图×3、充放状态、系统状态机、NTC1-8+极值温度、充/放/MOS 温度、瞬时/平均电流(i32 符号分割)、RSOC/ASOC/SOH/循环、单体电压 20×u16、最高低压差、总压/辅源/Pack 电压、剩余容量 u32×4 |
| 0x03 | 设备信息 | NTC 数、电芯数+化学类型、版本、平台(TI/O2)、设备号 ASCII、标称/实际容量 |
| 0x05/0x02 | 保护参数读/写 | 约 40 个参数（过欠压/延时对、四组温控对、三级过流 i32、使能位图、设计容量…） |
| 0x09 | 均衡开关 | data[0]=01 开 / 00 关 |
| 0x16 | 级联信息 | 主+3 从箱各自 SOC/总压/电流/MOS/保护 |
| 其余 | OCV 表读写(204B)、SN 读写、日志(计数器族)、风扇、容量校准 | 同规格 |

### EMS-OFO（头 AAAA、Addr 2 字节、命令回显、LEN 校验、**加和校验**=全帧累加−0xAA−0xAA 取 u8）

| CMD | 名称 | 关键字段 |
|-----|------|----------|
| 0xE1 | 系统信息 | 协议版本、EMS 序号15ASCII、各模块(BMS/PCS/MPPT)型号+版本+器件号、总充/放电功率、剩余充/放电时间 s |
| 0xE2 | BMS 信息 | 与 BMS 0x01 高度同构（保护/故障/AFE/状态位图、NTC 温度族、电流 i32、SOC 族、单体电压 20、MOS 断开原因位图） |
| 0xE6 | 太阳能(海索 MPPT) | 母线 V/I/P ÷10、电池电压 ÷10、DC 温度、OVP/UVP/充电设定 ÷10 |
| 0xE7 | PV 充电 | Vbus/Ibus/Pbus/Vbat/Ibat/Pbat u32、MOS 温度(0xFFFF 无效)、适配器类型 |
| 0xEA/EB/ED | 风扇照明/通信保护/级联 | 位图与同构字段 |
| 0xEC | 控制帧(13B 写) | test_mode/风扇×2/校准模式位图 + 风扇占空比 + 校准容量 u32 |

### 轮询模型

发送线程取轮询列表顺序发查询帧（可配间隔，默认 300ms），retry>5 标记设备离线清显示——对应 UI 的「启动/停止轮询」与离线态。

## 三、卡片仪表盘（QML）

数据流：绑定的串口会话 worker.bytesReceived → framer → decoder → QVariantMap dict → QML。卡片按字段 `card`
提示自动生成：

| card 类型 | 组件 | 适用 |
|-----------|------|------|
| number | SerialCube_DashNumber 卡（Caption 标题 + Title 大数 + 单位） | 电压/电流/功率/循环次数 |
| progress | FluProgressBar 卡 | SOC/ASOC/SOH |
| status | LED 灯组卡（Canvas 圆点 + 名称） | 保护/故障/充放状态位图 |
| cellgrid | 单体电压瓦片栅格（min 高亮绿/max 红/压差提示） | 单体电压 ×N |
| text | 文本卡 | 序号/器件号/版本 |
| gauge | Canvas 圆弧仪表（自绘，WinUI 规范） | 功率等主指标（可选） |

栅格：`columns = max(2, floor(pageWidth/280))`；2 秒无新帧进入"离线灰"态（对应 retry>5）。

## 四、页面布局（草案，待确认）

```
┌ 协议解析 ────────────────────────────────────────────────┐
│ 协议解析 │ ▾预设[BMS-OFO] │ ▾绑定会话[COM20] │ (▶轮询) [⚙]  A?│  ← 40px 工具栏（同串口页样式）
├─ 左侧配置栏 280px ──────┬─ 右侧 ─────────────────────────┤
│ ▸ 协议档案              │ ┌数值卡┐┌进度卡SOC┐┌状态卡●●●┐    │
│   帧格式摘要(只读)       │ ├…… GridLayout 自适应列数 ……┤    │
│ ▸ 轮询命令              │ └───────────────────────────────┘    │
│   ☑0x01 心跳/状态       │                                      │
│   ☐0x03 设备信息        ├──────────────────────────────────────┤
│   间隔[600]ms           │ 解析日志（原始帧 hexdump              │
│   (▶启动轮询)           │          + 解析键值行，占满余高）       │
│ ▸ 配置：保存/加载JSON    │                                      │
└─────────────────────────┴──────────────────────────────────────┘
```

- 「绑定会话」下拉列出串口调试页的活动会话，协议页**复用其连接**（收流被动解析）；勾选轮询后才主动发查询帧
- 预设切换 → 加载对应 profile 并重建仪表盘卡片；用户改动可存为自定义 JSON（%APPDATA%/ToolHub/profiles/）

## 五、实施步骤与验收

| 步骤 | 内容 | 验收 |
|------|------|------|
| P1 引擎 | framer/profile/decoder/checksums + BMS、EMS 预设 JSON + pytest 单测（构造帧→解码断言，含半包/粘包/坏 CRC 用例） | 单测全绿 |
| P2 页面骨架 | 新导航项「协议解析」，工具栏/绑定会话/预设选择/解析日志（先只读被动解析） | 对 COM20 发 BMS 0xAA 假帧能看到解码行 |
| P3 仪表盘 | 卡片族五类 + 自动生成 + 离线灰 | 回环发 SOC 变化卡片实时更新 |
| P4 轮询 | 命令勾选 + 定时发送 + retry 离线 | v1.3.0 发布 bump |
| P5 Modbus RTU + 字段表编辑器 | 第二协议 + 用户自定义字段 | v1.4.0 |

风险：解析大日志的 RichText 性能沿用脏缓存方案；BMS 0x01 帧 159B、EMS 0xE2 帧 ~160B 属正常量级。

---

## 附录 A：BMS-OFO 协议完整规格（逆向自 Form1.cs L142/L2909/L2924-5008）

- 物理层 115200 8N1；TX 帧 `[5A][01][CMD][LEN][DATA..][CRC16 lo hi]` 总长 LEN+6；
  RX 帧同构但帧头 **0x55**（不对称！）。CRC16-Modbus：反射多项式 0xA001、初值 0xFFFF（半字节查表法），
  覆盖前 4+LEN 字节，低字节在前。全小端。
- 命令：0x01 心跳/实时状态(位图+遥测)、0x02 写保护参 95B、0x03 设备信息、0x04 OCV 101 点+使能、
  0x05 读保护参、0x06 读 OCV、0x07 SN 16B、0x08 读 SN、0x09 均衡开关、0x0A 日志、0x0B 容量校准 u32、
  0x0C 风扇%、0x16 级联(主机+3 从)；升级 0x10-0x14（握手 B+版本、128B/页、APP_CRC 为逐字节和）。
- 温度编码：u16 装 sbyte ℃，0xFFFF=无效；日志模式 u8=℃−40 有符号偏移。电流 i32 正充负放 mA。电压 mV 原样。
- 0x01 响应字段表见 §二 命令表（20 单体电压 @89..128、NTC@20..35、电流@52..59、RSOC@64、SOH@74、
  循环@75..76、总压@137..138、RM@147..150 等）。

## 附录 B：EMS-OFO 协议完整规格（Form1.cs check_sum@1411、Data_Loading_16/32@1424-1439、解析@1482+）

- 物理层 115200 8N1。查询帧 7B：`AA AA 00 00 CMD 00 SUM`；响应帧总长 LEN+7：
  `AA AA addr(2) CMD LEN DATA.. SUM`，SUM=(Σ(0..6+LEN−1) − 0xAA − 0xAA) & 0xFF（含头部，双 AA 相互抵消）。
  数据域自偏移 6 起，小端。版本号显示均为字节逆序拼点（buf[hi+1].buf[lo] hex2）。
- 命令 0xE1 系统信息（含各模块型号/版本/器件号）、0xE2 BMS 信息（与 BMS 0x01 同构）、0xE3/E4 PCS 两家、
  0xE5 太阳能(仅识别未解析)/0xE6 海索 MPPT(Vbus/Ibus/Pbus/Vbat÷10 等)、0xE7 PV(u32 族)、
  0xE8 DC-USB、0xE9 TypeC、0xEA 风扇照明、0xEB 通信保护、0xEC 控制写(13B)、0xED 级联。
- 轮询：后台线程每命令间隔 300ms 顺序发送（勾选系统信息追加 EA/EB）；UI 定时器 50ms 解析刷屏；
  retry>5 清显示判离线。注意其 CRC16 函数是死代码，实际用加和校验。
