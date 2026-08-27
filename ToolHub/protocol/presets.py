"""内置协议预设：BMS-OFO 与 EMS-OFO（字段规格逆向自两家上位机 Form1.cs）。

完整字节级规格见 .workflow/docs/phase2-protocol-plan.md 附录 A/B。
预设以 dict 形式内置，导出/编辑后可作为用户自定义 JSON 加载。
"""

BMS_OFO = {
    "version": 1,
    "name": "BMS-OFO",
    "framing": {
        "rx_header": "55",
        "tx_header": "5A",
        "addr_offset": 1,
        "addr_len": 1,
        "cmd_offset": 2,
        "len_offset": 3,
        "data_offset": 4,
        "checksum": {"type": "crc16_modbus", "size": 2}
    },
    "endian": "little",
    "commands": [
        {"cmd": "0x01", "name": "心跳/实时状态", "direction": "query", "interval_ms": 600},
        {"cmd": "0x03", "name": "设备信息", "direction": "query", "interval_ms": 3000},
        {"cmd": "0x09", "name": "均衡开关", "direction": "write"},
        {"cmd": "0x16", "name": "级联信息", "direction": "query", "interval_ms": 5000}
    ],
    "fields": {
        # ---- 0x01 心跳/实时状态（绝对下标−4 = 数据域偏移）----
        "0x01": [
            {"offset": 2,  "type": "bits", "size": 2, "name": "常规保护",
             "bits": ["放电高温", "放电低温", "充电高温", "充电低温",
                      "单体过压L1", "单体过压L2", "单体欠压L1", "单体欠压L2",
                      "充电过流L1", "充电过流L2", "放电过流L1", "放电过流L2",
                      "短路", "MOS过温", "其他放电故障", "其他充电故障"],
             "card": "status"},
            {"offset": 4,  "type": "bits", "size": 2, "name": "不可恢复故障",
             "bits": ["压差过大", "电芯低压故障", "电芯过压故障", "采样线丢失",
                      "放电MOS故障", "充电MOS故障", "AFE故障", "NTC短路",
                      "NTC断线", "其他NTC短路", "其他NTC断线", "熔断器断", "风扇堵转"],
             "card": "status"},
            {"offset": 8,  "type": "u16", "name": "AFE保护位图", "card": "text"},
            {"offset": 10, "type": "u8", "name": "系统状态", "card": "text",
             "enum": {0: "待机", 1: "运行", 2: "静置", 3: "充电中", 4: "放电中",
                      5: "休眠", 6: "关机"}},
            {"offset": 12, "type": "bits", "size": 2, "name": "充放电状态",
             "bits": ["充电MOS开", "放电MOS开", "主动放电", "主动充电",
                      "充电中", "放电中"],
             "card": "status"},

            {"offset": 16, "type": "u16[8]", "name": "NTC温度", "unit": "℃",
             "invalid": 65535, "signed": True, "card": "tiles"},
            {"offset": 32, "type": "u16", "name": "最高电芯温度", "unit": "℃",
             "invalid": 65535, "signed": True},
            {"offset": 34, "type": "u16", "name": "最低电芯温度", "unit": "℃",
             "invalid": 65535, "signed": True},

            {"offset": 48, "type": "i32", "name": "瞬时电流", "unit": "A",
             "scale": 0.001, "sign_split": True, "card": "number"},
            {"offset": 52, "type": "i32", "name": "平均电流", "unit": "A",
             "scale": 0.001, "sign_split": True},

            {"offset": 60, "type": "u8", "name": "SOC", "unit": "%", "card": "progress"},
            {"offset": 61, "type": "u8", "name": "ASOC", "unit": "%", "card": "progress"},
            {"offset": 70, "type": "u8", "name": "SOH", "unit": "%", "card": "progress"},
            {"offset": 71, "type": "u16", "name": "循环次数", "unit": "次"},

            {"offset": 85, "type": "u16[20]", "name": "单体电压", "unit": "mV",
             "extremes": True, "card": "tiles"},
            {"offset": 125, "type": "u16", "name": "最高单体", "unit": "mV"},
            {"offset": 127, "type": "u16", "name": "最低单体", "unit": "mV"},
            {"offset": 129, "type": "u16", "name": "单体压差", "unit": "mV",
             "warn_gt": 50},

            {"offset": 133, "type": "u16", "name": "电池总压", "unit": "V",
             "scale": 0.001, "card": "number"},
            {"offset": 137, "type": "u16", "name": "输出电压(Pack)", "unit": "V",
             "scale": 0.001, "card": "number"},

            {"offset": 143, "type": "u32", "name": "剩余容量RM", "unit": "Ah",
             "scale": 0.001, "card": "number"},
            {"offset": 151, "type": "u32", "name": "满电容量RFCC", "unit": "Ah",
             "scale": 0.001}
        ],
        # ---- 0x03 设备信息 ----
        "0x03": [
            {"offset": 0,  "type": "u8", "name": "NTC数量"},
            {"offset": 1,  "type": "u8", "name": "电芯数(低5位)"},
            {"offset": 4,  "type": "ascii:4", "name": "设备号"},
            {"offset": 13, "type": "u32", "name": "标称容量", "unit": "mAh"},
            {"offset": 17, "type": "u32", "name": "实际容量", "unit": "mAh"}
        ]
    }
}

EMS_OFO = {
    "version": 1,
    "name": "EMS-OFO",
    "framing": {
        "rx_header": "AAAA",
        "tx_header": "AAAA",
        "addr_offset": 2,
        "addr_len": 2,
        "cmd_offset": 4,
        "len_offset": 5,
        "data_offset": 6,
        "checksum": {"type": "sum8_excl_headers", "headers": "AAAA", "size": 1}
    },
    "endian": "little",
    "commands": [
        {"cmd": "0xE1", "name": "系统信息", "direction": "query", "interval_ms": 3000},
        {"cmd": "0xE2", "name": "BMS信息", "direction": "query", "interval_ms": 600},
        {"cmd": "0xE6", "name": "太阳能MPPT", "direction": "query", "interval_ms": 1000},
        {"cmd": "0xEC", "name": "控制指令", "direction": "write"}
    ],
    "fields": {
        # ---- 0xE2 BMS 信息（数据域自帧内偏移 6 起，以下为数据域内偏移）----
        "0xE2": [
            {"offset": 0,  "type": "bits", "size": 2, "name": "常规保护",
             "bits": ["放电高温", "放电低温", "充电高温", "充电低温",
                      "单体过压L1", "单体过压L2", "单体欠压L1", "单体欠压L2",
                      "充电过流L1", "充电过流L2", "放电过流L1", "放电过流L2",
                      "短路", "MOS过温", "其他放电故障", "其他充电故障"],
             "card": "status"},
            {"offset": 2,  "type": "bits", "size": 2, "name": "不可恢复故障",
             "bits": ["压差过大", "电芯低压故障", "电芯过压故障", "采样线丢失",
                      "放电MOS故障", "充电MOS故障", "AFE故障", "NTC短路",
                      "NTC断线", "其他NTC短路", "其他NTC断线", "熔断器断"],
             "card": "status"},
            {"offset": 6,  "type": "u16", "name": "AFE保护位图", "card": "text"},
            {"offset": 10, "type": "bits", "size": 2, "name": "充放电状态",
             "bits": ["充电MOS开", "放电MOS开", "主动放电", "主动充电",
                      "充电中", "放电中"],
             "card": "status"},
            {"offset": 14, "type": "u8", "name": "系统状态", "card": "text",
             "enum": {0: "待机", 1: "运行", 2: "静置", 3: "充电中", 4: "放电中",
                      5: "休眠", 6: "关机"}},

            {"offset": 20, "type": "u16[8]", "name": "NTC温度", "unit": "℃",
             "invalid": 65535, "signed": True, "card": "tiles"},
            {"offset": 36, "type": "u16", "name": "最高电芯温度", "unit": "℃",
             "invalid": 65535, "signed": True},
            {"offset": 38, "type": "u16", "name": "最低电芯温度", "unit": "℃",
             "invalid": 65535, "signed": True},

            {"offset": 48, "type": "i32", "name": "瞬时电流", "unit": "A",
             "scale": 0.001, "sign_split": True, "card": "number"},
            {"offset": 52, "type": "i32", "name": "平均电流", "unit": "A",
             "scale": 0.001, "sign_split": True},

            {"offset": 64, "type": "u8", "name": "SOC", "unit": "%", "card": "progress"},
            {"offset": 65, "type": "u8", "name": "ASOC", "unit": "%", "card": "progress"},
            {"offset": 66, "type": "u8", "name": "CSOC", "unit": "%", "card": "progress"},

            {"offset": 87, "type": "u8", "name": "SOH", "unit": "%", "card": "progress"},
            {"offset": 88, "type": "u16", "name": "循环次数", "unit": "次"},

            {"offset": 98,  "type": "u16[20]", "name": "单体电压", "unit": "mV",
             "extremes": True, "card": "tiles"},
            {"offset": 138, "type": "u16", "name": "最高单体", "unit": "mV"},
            {"offset": 140, "type": "u16", "name": "最低单体", "unit": "mV"},
            {"offset": 142, "type": "u16", "name": "单体压差", "unit": "mV",
             "warn_gt": 50},

            {"offset": 146, "type": "u16", "name": "电池总压", "unit": "V",
             "scale": 0.001, "card": "number"},
            {"offset": 148, "type": "u16", "name": "Pack电压", "unit": "V",
             "scale": 0.001, "card": "number"}
        ],
        # ---- 0xE1 系统信息 ----
        "0xE1": [
            {"offset": 0,  "type": "u16", "name": "协议版本"},
            {"offset": 2,  "type": "ascii:15", "name": "EMS序号"},
            {"offset": 25, "type": "ascii:4", "name": "EMS器件号"},
            {"offset": 46, "type": "u32", "name": "总放电功率", "unit": "W",
             "card": "number"},
            {"offset": 50, "type": "u32", "name": "总充电功率", "unit": "W",
             "card": "number"},
            {"offset": 54, "type": "u32", "name": "剩余放电时间", "unit": "s",
             "card": "number"},
            {"offset": 58, "type": "u32", "name": "剩余充电时间", "unit": "s"},
            {"offset": 62, "type": "u8", "name": "错误码", "card": "text"},
            {"offset": 63, "type": "u8", "name": "保护码", "card": "text"}
        ],
        # ---- 0xE6 太阳能 MPPT（海索）----
        "0xE6": [
            {"offset": 18, "type": "bits", "size": 2, "name": "MPPT故障",
             "bits": ["母线过压", "母线欠压", "过温", "过流", "器件故障"],
             "card": "status"},
            {"offset": 20, "type": "u16", "name": "充电状态", "card": "text",
             "enum": {0: "未充电", 1: "充电中", 2: "充满停止"}},
            {"offset": 22, "type": "u16", "name": "母线电压", "unit": "V",
             "scale": 0.1, "card": "number"},
            {"offset": 24, "type": "u16", "name": "母线电流", "unit": "A",
             "scale": 0.1, "card": "number"},
            {"offset": 26, "type": "u16", "name": "母线功率", "unit": "W",
             "card": "number"},
            {"offset": 32, "type": "u16", "name": "电池电压(MPPT)", "unit": "V",
             "scale": 0.1, "card": "number"},
            {"offset": 52, "type": "u16", "name": "DC温度", "unit": "℃"}
        ]
    }
}

PRESETS = {p["name"]: p for p in (BMS_OFO, EMS_OFO)}
