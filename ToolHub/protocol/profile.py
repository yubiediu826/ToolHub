"""协议档案（Profile）模型与 JSON 加载/保存。

帧描述 + 命令表 + 字段表全部数据驱动；BMS/EMS 预设见 presets.py。
"""
from __future__ import annotations

import json


class Profile:
    """解析档。字段见 presets.py 中的示例结构（version:1）。"""

    def __init__(self, data: dict):
        self._check(data)
        self.data = data
        # 常用项提为属性，避免散落的字典访问
        fr = data["framing"]
        self.name: str = data.get("name", "未命名")
        self.rx_header: bytes = bytes.fromhex(fr["rx_header"])
        self.tx_header: bytes = bytes.fromhex(fr["tx_header"])
        self.addr_offset: int = fr.get("addr_offset", len(self.rx_header))
        self.addr_len: int = fr.get("addr_len", 0)
        self.cmd_offset: int = fr["cmd_offset"]
        self.len_offset: int = fr["len_offset"]
        self.data_offset: int = fr["data_offset"]
        self.checksum: dict = fr["checksum"]
        self.csum_size: int = self.checksum.get("size", 2)
        self.endian: str = fr.get("endian", "little")
        self.commands: list[dict] = data.get("commands", [])
        # 键统一小写，避免 "0xE2"/"0xe2" 查询不一致
        self.fields: dict[str, list] = {k.lower(): v for k, v in data.get("fields", {}).items()}

    @staticmethod
    def _check(data: dict):
        for key in ("name", "framing"):
            if key not in data:
                raise ValueError(f"profile missing key: {key}")
        fr = data["framing"]
        for key in ("rx_header", "cmd_offset", "len_offset", "data_offset", "checksum"):
            if key not in fr:
                raise ValueError(f"framing missing key: {key}")

    # ---- 命令表 ----
    def commands(self) -> list[dict]:
        return self.commands

    def query_commands(self) -> list[dict]:
        return [c for c in self.commands if c.get("direction") == "query"]

    def fields_for(self, cmd_hex: str) -> list:
        return self.fields.get(cmd_hex.lower(), [])

    # ---- 派生：仪表盘卡片 schema（顺序稳定，供 QML Repeater 使用）----
    def card_schema(self) -> list[dict]:
        """按命令声明顺序生成卡片描述列表。
        {key, title, card, unit, opts...}；key 全局唯一 = f"{cmd}:{name}"。"""
        cards = []
        seen = set()
        for cmd_hex, field_list in self.fields.items():
            for f in field_list:
                ctype = f.get("card")
                if not ctype:
                    continue
                key = f"{cmd_hex}:{f['name']}"
                if key in seen:
                    continue
                seen.add(key)
                cards.append({
                    "key": key,
                    "cmd": cmd_hex,
                    "title": f["name"],
                    "card": ctype,
                    "unit": f.get("unit", ""),
                    "bits": f.get("bits", []),
                    "extremes": f.get("extremes", False),
                })
        return cards

    # ---- 序列化 ----
    def to_json(self) -> str:
        return json.dumps(self.data, ensure_ascii=False, indent=2)

    @staticmethod
    def from_json(text: str) -> "Profile":
        return Profile(json.loads(text))

    @staticmethod
    def from_dict(data: dict) -> "Profile":
        return Profile(data)
