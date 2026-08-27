"""校验算法：CRC16-Modbus 查表法 / 扣除帧头的加和校验。"""


def crc16_modbus(data: bytes) -> int:
    """反射多项式 0xA001、初值 0xFFFF 的标准 Modbus CRC16（半字节查表法，
    与 BMS/EMS 上位机中的 crctalbeabs 实现等价）。"""
    table = (0x0000, 0xCC01, 0xD801, 0x1400, 0xF001, 0x3C00,
             0x2800, 0xE401, 0xA001, 0x6C00, 0x7800, 0xB401,
             0x5000, 0x9C01, 0x8801, 0x4400)
    crc = 0xFFFF
    for ch in data:
        crc = table[(ch ^ crc) & 0x0F] ^ (crc >> 4)
        crc = table[((ch >> 4) ^ crc) & 0x0F] ^ (crc >> 4)
    return crc & 0xFFFF


def sum8_excl_headers(data: bytes, headers: bytes) -> int:
    """全帧累加和（不含末校验字节自身）再扣除帧头字节序列后取 u8。
    与 EMS 上位机 check_sum() 一致：双 0xAA 帧头相互抵消。"""
    return (sum(data[:len(data)]) - sum(headers)) & 0xFF


def xor8(data: bytes) -> int:
    v = 0
    for b in data:
        v ^= b
    return v


def compute(ck: dict, frame_wo_sum: bytes) -> int:
    """按 profile.checksum 描述计算校验值。
    ck: {"type": "crc16_modbus"|"sum8_excl_headers"|"xor8", "headers": "AABB"(hex,可选)}"""
    t = ck.get("type")
    if t == "crc16_modbus":
        return crc16_modbus(frame_wo_sum)
    if t == "sum8_excl_headers":
        hx = ck.get("headers", "")
        hb = bytes.fromhex(hx) if hx else b""
        return sum8_excl_headers(frame_wo_sum, hb)
    if t == "xor8":
        return xor8(frame_wo_sum)
    raise ValueError(f"unknown checksum type: {t}")
