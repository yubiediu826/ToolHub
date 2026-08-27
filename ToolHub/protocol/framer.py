"""流式分帧器：按 Profile 帧描述从字节流中重组整帧。

处理半包/粘包：滑窗找帧头 → 等长度域 → 计算总长 → 收齐后校验。
坏帧候选被消费丢弃后继续扫描后续数据（不会因单个坏帧停机）。
"""
from __future__ import annotations

from . import checksums
from .profile import Profile


class ProfileFramer:
    def __init__(self, profile: Profile):
        self.profile = profile
        self.buf = bytearray()

    def feed(self, data: bytes) -> list[tuple[str, bytes, bytes]]:
        """喂入新数据，返回本次解析出的合法帧 [(cmd_hex, payload, frame), ...]"""
        self.buf.extend(data)
        out = []
        while True:
            frame = self._try_extract()
            if frame is None:
                break
            out.append(frame)
        return out

    # ---- 内部 ----
    def _try_extract(self):
        """处理一个候选；返回帧元组，数据不足时返回 None。
        坏帧在函数内被消费并继续扫下一个候选。"""
        prof = self.profile
        header = prof.rx_header
        while True:
            start = self.buf.find(header)
            if start < 0:
                keep = len(header) - 1
                if len(self.buf) > keep:
                    del self.buf[:len(self.buf) - keep]
                return None
            if start > 0:
                del self.buf[:start]  # 丢弃头部前的垃圾

            need = prof.len_offset + 1 + prof.csum_size
            if len(self.buf) < need:
                return None  # 等长度域
            ln = self.buf[prof.len_offset]

            total = prof.data_offset + ln + prof.csum_size
            if total > 1024:  # 长度异常：假帧头
                del self.buf[0:1]
                continue
            if len(self.buf) < total:
                return None  # 半包等待

            frame = bytes(self.buf[:total])
            cmd_byte = frame[prof.cmd_offset]
            csum_calc = checksums.compute(prof.checksum, frame[:-prof.csum_size])
            stored = int.from_bytes(frame[-prof.csum_size:],
                                    "little" if prof.csum_size == 2 else "big")
            del self.buf[:total]  # 无论对错都消费掉这一帧区域

            if csum_calc != stored:
                continue  # 校验失败：继续扫下一个候选
            payload = frame[prof.data_offset:prof.data_offset + ln]
            return (f"0x{cmd_byte:02X}", payload, frame)
