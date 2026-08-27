"""字段表解码：数据域 bytes → 有序键值列表。

字段类型：
  u8/u16/u32/i8/i16/i32          整数（endian 按 profile；u 宽度可用 signed 承载有符号载荷）
  ascii:n                        定长 ASCII 文本
  类型[n]                        数组
  bits                           位域，值=int 掩码
通用选项：scale(乘)、offset_val(加)、invalid(原始值无效→None)、signed、enum(值→文本映射)。
"""
from __future__ import annotations

import struct

from .profile import Profile


def _parse_type(ftype: str):
    """返回 (base, count)；count=None 表示标量。支持 'u16[20]' 与 'ascii:15'。"""
    if "[" in ftype:
        base, cnt = ftype[:-1].split("[")
        return base.strip(), max(int(cnt), 0)
    base = ftype.split(":")[0]
    return base.strip(), None


_SIZES = {"u8": 1, "i8": 1, "u16": 2, "i16": 2, "u32": 4, "i32": 4}


def _scalar(data: bytes, off: int, base: str, little: bool):
    """原始无符号/i 类型值；u 宽度承载有符号载荷的转换由 present_signed 负责。"""
    size = _SIZES.get(base)
    if size is None:
        raise ValueError(f"unknown scalar type {base}")
    raw = data[off:off + size]
    if len(raw) < size:
        return None
    fmt = ("<" if little else ">") + {"u8": "B", "i8": "b", "u16": "H",
                                      "i16": "h", "u32": "I", "i32": "i"}[base]
    return struct.unpack(fmt, raw)[0]


def _decode_one(f: dict, data: bytes, little: bool) -> dict:
    """单字段 → 值字典。"""
    name = f["name"]
    ftype = f["type"]
    off = int(f.get("offset", 0))
    scale = float(f.get("scale", 1))
    offset_val = float(f.get("offset_val", 0))
    invalid = f.get("invalid")
    carrier_signed = bool(f.get("signed", False)) and not ftype.startswith("i")
    enum_map = f.get("enum") or {}

    def present(v):
        """无效过滤 + 数值换算 + 枚举映射。"""
        if v is None:
            return {"value": None}
        if invalid is not None and v == invalid:
            return {"value": None}
        if v in enum_map:
            return {"value": enum_map[v], "raw": v}
        r = v * scale + offset_val
        return {"value": round(r, 3)}

    def present_signed(v_raw):
        """invalid 比较用原始无符号值（如 u16 载荷 0xFFFF 表示无效）。"""
        if v_raw is None:
            return {"value": None}
        if invalid is not None and v_raw == invalid:
            return {"value": None}
        bits = _SIZES.get(base, 2) * 8
        v = v_raw - (1 << bits) if v_raw >= (1 << (bits - 1)) else v_raw
        return present(v)

    base, count = _parse_type(ftype)

    if base == "bits":
        v = int.from_bytes(data[off:off + int(f.get("size", 2))],
                           "little" if little else "big")
        return {"mask": v}

    if count is not None:
        step = _SIZES.get(base, 2)
        vals = []
        for i in range(count):
            raw = _scalar(data, off + i * step, base, little)
            vals.append((present_signed if carrier_signed else present)(raw)["value"])
        return {"values": vals}

    if base == "ascii":
        n = int(ftype.split(":")[1]) if ":" in ftype else 16
        text = data[off:off + n].decode("ascii", errors="replace").strip("\x00 ").rstrip()
        return {"value": text}

    raw = _scalar(data, off, base, little)
    return (present_signed if carrier_signed else present)(raw)


def decode(fields: list, data: bytes) -> list[tuple[str, dict]]:
    out: list[tuple[str, dict]] = []
    for f in fields:
        try:
            out.append((f["name"], _decode_one(f, data, True)))
        except (IndexError, ValueError):
            continue
    return out
