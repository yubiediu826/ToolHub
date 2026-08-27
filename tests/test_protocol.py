"""协议引擎单元测试：帧构造/分帧(半包粘包)/校验失败/字段解码。

直接运行:  python tests/test_protocol.py
"""
import copy
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from ToolHub.protocol import checksums
from ToolHub.protocol.decoder import decode
from ToolHub.protocol.framer import ProfileFramer
from ToolHub.protocol.presets import BMS_OFO, EMS_OFO
from ToolHub.protocol.profile import Profile

bms = Profile.from_dict(dict(BMS_OFO))
ems = Profile.from_dict(dict(EMS_OFO))


def build_bms_frame(payload: bytes) -> bytes:
    frame = bytes([0x55, 0x01, 0x01, len(payload)]) + payload
    crc = checksums.crc16_modbus(frame)
    return frame + crc.to_bytes(2, "little")


def build_ems_frame(cmd: int, payload: bytes) -> bytes:
    # 线上格式：SUM = Σ(地址+CMD+LEN+数据) & 0xFF（帧头 AAAA 被扣除）
    body_wo_header = bytes([0x00, 0x00, cmd, len(payload)]) + payload
    return bytes([0xAA, 0xAA]) + body_wo_header + bytes([sum(body_wo_header) & 0xFF])


def test_crc16_known_vector():
    assert checksums.crc16_modbus(b"123456789") == 0x4B37


def test_framer_basic():
    fr = ProfileFramer(bms)
    payload = bytes([1, 2, 3])
    out = fr.feed(build_bms_frame(payload))
    assert len(out) == 1
    cmd, data, _ = out[0]
    assert cmd == "0x01" and data == payload


def test_framer_split_packets():
    fr = ProfileFramer(bms)
    f = build_bms_frame(bytes([0xAA]) * 10)
    assert fr.feed(f[:3]) == []
    r = fr.feed(f[3:])
    assert len(r) == 1 and r[0][1] == bytes([0xAA]) * 10


def test_framer_sticky_and_garbage():
    fr = ProfileFramer(bms)
    f1 = build_bms_frame(bytes([0x11]))
    f2 = build_bms_frame(bytes([0x22, 0x33]))
    out = fr.feed(bytes([0x00, 0xFF]) + f1 + f2)
    assert [(c, d) for c, d, _ in out] == [("0x01", bytes([0x11])),
                                           ("0x01", bytes([0x22, 0x33]))]


def test_framer_bad_crc_dropped():
    fr = ProfileFramer(bms)
    good = bytearray(build_bms_frame(bytes([0x01])))
    bad = bytearray(good)
    bad[-1] ^= 0xFF
    out = fr.feed(bytes(bad) + bytes(good))
    assert len(out) == 1 and out[0][1] == bytes([0x01])


def test_ems_sum_checksum():
    fr = ProfileFramer(ems)
    payload = bytes(20) + bytes([0x64])
    out = fr.feed(build_ems_frame(0xE2, payload))
    assert out and out[0][0] == "0xE2"


def test_decoder_soc_progress():
    fields = ems.fields_for("0xE2")
    soc = next(f for f in fields if f["name"] == "SOC")
    data = bytes(soc["offset"]) + bytes([98])
    vals = dict(decode(fields, data))
    assert vals["SOC"]["value"] == 98


def test_decoder_temp_signed_invalid():
    fields = ems.fields_for("0xE2")
    ntc = next(f for f in fields if f["name"] == "NTC温度")
    off = ntc["offset"]
    data = bytearray(off + 16)
    data[off:off + 2] = (25).to_bytes(2, "little")
    data[off + 2:off + 4] = (65535).to_bytes(2, "little")
    vals = dict(decode(fields, bytes(data)))
    t = vals["NTC温度"]["values"]
    assert t[0] == 25 and t[1] is None


def test_decoder_cellgrid():
    fields = ems.fields_for("0xE2")
    cells = next(f for f in fields if f["name"] == "单体电压")
    data = bytearray(cells["offset"] + 40)
    for i in range(20):
        data[cells["offset"] + i * 2:cells["offset"] + i * 2 + 2] = (3300 + i).to_bytes(2, "little")
    vals = dict(decode(fields, bytes(data)))
    c = vals["单体电压"]["values"]
    assert len(c) == 20 and c[0] == 3300 and c[19] == 3319


def test_status_bits_mask():
    fields = ems.fields_for("0xE2")
    prot = next(f for f in fields if f["name"] == "常规保护")
    mask = (1 << 0) | (1 << 12)
    data = bytearray(prot["offset"] + 2)
    data[prot["offset"]:prot["offset"] + 2] = mask.to_bytes(2, "little")
    vals = dict(decode(fields, bytes(data)))
    assert vals["常规保护"]["mask"] == mask


def test_engine_query_frame():
    """查询帧构造与分帧器对帧格式的理解一致（临时把 rx_header 换成 tx_header 做闭环）。"""
    # EMS：AA AA 00 00 CMD 00 SUM(不含帧头累加)
    body = bytes(ems.tx_header) + bytes([0x00, 0x00, 0xE2, 0x00])
    frame = bytes(body) + bytes([sum(body[2:]) & 0xFF])
    out = ProfileFramer(ems).feed(frame)
    assert out and out[0][0] == "0xE2"

    # BMS：5A 00 CMD 00 CRC16(le)；用 rx_header=5A 的克隆档做闭环
    bms_tx = Profile.from_dict(copy.deepcopy(BMS_OFO))
    bms_tx.data["framing"]["rx_header"] = BMS_OFO["framing"]["tx_header"]
    bms_tx.rx_header = bms_tx.tx_header
    body_b = bytes(bms.tx_header) + bytes([0x00, 0x03, 0x00])
    crc = checksums.crc16_modbus(body_b)
    frame_b = bytes(body_b) + crc.to_bytes(2, "little")
    out_b = ProfileFramer(bms_tx).feed(frame_b)
    assert out_b and out_b[0][0] == "0x03"


if __name__ == "__main__":
    fails = 0
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    for t in tests:
        try:
            t()
            print(f"PASS {t.__name__}")
        except AssertionError as e:
            fails += 1
            print(f"FAIL {t.__name__}: {e}")
        except Exception as e:  # noqa
            fails += 1
            print(f"ERROR {t.__name__}: {type(e).__name__} {e}")
    print()
    print(f"{len(tests) - fails}/{len(tests)} passed")
    sys.exit(1 if fails else 0)
