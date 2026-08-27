"""协议引擎 Qt 层：绑定串口会话 → 分帧 → 解码 → 信号驱动仪表盘。

QML 通过上下文属性 ProtocolTool 访问；轮询/离线判定等业务都在这里。
"""
from __future__ import annotations

import datetime
import time

from PySide6.QtCore import QObject, QTimer, Signal, Slot, Property

from ToolHub.protocol import checksums
from ToolHub.protocol.decoder import decode
from ToolHub.protocol.framer import ProfileFramer
from ToolHub.protocol.presets import PRESETS
from ToolHub.protocol.profile import Profile

MAX_LOG_LINES = 400


class ProtocolEngine(QObject):
    profilesChanged = Signal()
    currentProfileChanged = Signal()
    cardsChanged = Signal()
    valuesChanged = Signal()
    boundChanged = Signal()
    pollRunningChanged = Signal()
    parseLogChanged = Signal()
    offlineChanged = Signal()

    POLL_STEP_MS = 300          # 顺序轮询发送节拍
    STALE_MS = 2000             # 无合法帧判离线
    STATS_INTERVAL_MS = 1000    # 离线看门狗

    def __init__(self, session_manager, parent=None):
        super().__init__(parent)
        self._sm = session_manager
        self._profile: Profile | None = None
        self._profile_name = ""
        self._framer: ProfileFramer | None = None
        self._session = None
        self._values: dict = {}
        self._poll_list: list[dict] = []
        self._poll_idx = 0
        self._log_lines: list[str] = []
        self._last_rx_mono = 0.0

        self._poll_timer = QTimer(self)
        self._poll_timer.setInterval(self.POLL_STEP_MS)
        self._poll_timer.timeout.connect(self._poll_next)

        self._stale_timer = QTimer(self)
        self._stale_timer.setInterval(self.STATS_INTERVAL_MS)
        self._stale_timer.timeout.connect(self._check_stale)
        self._stale_timer.start()

    # ---- 预设与档案 ----
    @Property("QVariantList", notify=profilesChanged)
    def profileNames(self):
        return list(PRESETS.keys())

    @Property(str, notify=currentProfileChanged)
    def currentProfileName(self):
        return self._profile_name

    @Slot(str)
    def loadProfile(self, name: str):
        data = PRESETS.get(name)
        if not data:
            return
        try:
            prof = Profile.from_dict(dict(data))
        except (ValueError, KeyError):
            return
        self._profile = prof
        self._profile_name = name
        self._framer = ProfileFramer(prof)
        self._values.clear()
        self.valuesChanged.emit()
        self.cardsChanged.emit()
        self.currentProfileChanged.emit()

    @Property("QVariantList", notify=cardsChanged)
    def cards(self):
        if not self._profile:
            return []
        cards = []
        for c in self._profile.card_schema():
            d = dict(c)
            d.pop("cmd", None)
            cards.append(d)
        return cards

    @Property("QVariantMap", notify=valuesChanged)
    def values(self):
        return dict(self._values)

    # ---- 会话绑定 ----
    @Slot(int)
    def attach(self, session_index: int):
        sessions = self._sm.sessions
        if not (0 <= session_index < len(sessions)):
            return
        self.detach()
        session = sessions[session_index]
        self._session = session
        session.worker.bytesReceived.connect(self._on_bytes)
        self.boundChanged.emit()

    @Slot()
    def detach(self):
        if self._session is None:
            return
        try:
            self._session.worker.bytesReceived.disconnect(self._on_bytes)
        except (RuntimeError, TypeError):
            pass
        self.stopPoll()
        self._session = None
        self.boundChanged.emit()

    @Property(bool, notify=boundChanged)
    def bound(self):
        return self._session is not None

    # ---- 轮询 ----
    @Slot(bool)
    def setPolling(self, on: bool):
        if on:
            self.startPoll()
        else:
            self.stopPoll()

    @Slot()
    def startPoll(self):
        if not self.bound or not self._framer or self._poll_timer.isActive():
            return
        self._poll_list = self._profile.query_commands() if self._profile else []
        if not self._poll_list:
            return
        self._poll_idx = 0
        self._poll_timer.start()
        self.pollRunningChanged.emit()

    @Slot()
    def stopPoll(self):
        if self._poll_timer.isActive():
            self._poll_timer.stop()
            self.pollRunningChanged.emit()

    @Property(bool, notify=pollRunningChanged)
    def polling(self):
        return self._poll_timer.isActive()

    def _poll_next(self):
        if not self._poll_list or not self.bound:
            self.stopPoll()
            return
        c = self._poll_list[self._poll_idx % len(self._poll_list)]
        self._poll_idx += 1
        frame = self.build_query_frame(c["cmd"])
        if frame:
            self._session.worker.send(frame.hex().upper(), True, 0)

    def build_query_frame(self, cmd_hex: str) -> bytes | None:
        """按 TX 帧描述构造查询帧（数据域空，LEN=0）。"""
        if not self._profile:
            return None
        prof = self._profile
        try:
            cmd_byte = int(cmd_hex, 16)
        except ValueError:
            return None
        body = bytearray(prof.tx_header)
        if prof.addr_len:
            body += b"\x00" * prof.addr_len
        body += bytes([cmd_byte]) + b"\x00"
        csum = checksums.compute(prof.checksum, bytes(body))
        tail = csum.to_bytes(prof.csum_size, "little" if prof.csum_size == 2 else "big")
        return bytes(body + tail)

    # ---- 数据流 ----
    def _on_bytes(self, data):
        if not self._framer:
            return
        for cmd_hex, payload, frame in self._framer.feed(bytes(data)):
            self._last_rx_mono = time.monotonic()
            self._push_log(cmd_hex, payload)
            fields = self._profile.fields_for(cmd_hex) if self._profile else []
            for key, val in decode(fields, payload):
                merged = dict(self._values.get(key, {}))
                merged.update(val)
                self._values[key] = merged
            self.valuesChanged.emit()

    def _check_stale(self):
        if not self._framer or self._last_rx_mono == 0.0:
            return
        stale_after = self.STALE_MS / 1000 * 2.5
        offline_now = (time.monotonic() - self._last_rx_mono) > stale_after
        if offline_now != self._offline:
            self._offline = offline_now
            self.offlineChanged.emit()

    _offline = True

    @Property(bool, notify=offlineChanged)
    def offline(self):
        return self._offline

    # ---- 解析日志 ----
    def _push_log(self, cmd_hex: str, payload: bytes):
        ts = datetime.datetime.now().strftime("%H:%M:%S.%f")[:-3]
        hexs = " ".join(f"{b:02X}" for b in payload[:48])
        if len(payload) > 48:
            hexs += " …"
        self._log_lines.append(f"{ts} [{cmd_hex}] {hexs}")
        kv_parts = []
        for key, val in decode(self._profile.fields_for(cmd_hex) if self._profile else [],
                               payload) if self._profile else []:
            if "mask" in val:
                bits = next((f.get("bits", []) for f in self._profile.fields_for(cmd_hex)
                             if f["name"] == key), [])
                on = [n for i, n in enumerate(bits) if val["mask"] & (1 << i)]
                text = ",".join(on) if on else "-"
                kv_parts.append(f"{key}: {text}")
            elif "values" in val:
                vv = [x for x in val["values"] if x is not None]
                kv_parts.append(f"{key}: [{len(vv)}项] {'/'.join(str(x) for x in vv[:8])}…")
            else:
                kv_parts.append(f"{key}: {val['value']}")
        line_kv = "  |  ".join(kv_parts[:14])
        if line_kv:
            self._log_lines.append("      ↳ " + line_kv)
        if len(self._log_lines) > MAX_LOG_LINES:
            del self._log_lines[: len(self._log_lines) - MAX_LOG_LINES]
        self.parseLogChanged.emit()

    @Property(str, notify=parseLogChanged)
    def parseLogText(self):
        return "\n".join(self._log_lines)

    @Slot()
    def clearLog(self):
        self._log_lines.clear()
        self.parseLogChanged.emit()

    # ---- 测试钩子：直接喂帧（绕过串口）----
    @Slot(str)
    def injectHexFrame(self, hex_str: str):
        if not self._framer:
            return
        try:
            raw = bytes.fromhex(hex_str.replace(" ", ""))
        except ValueError:
            return
        self._on_bytes(raw)
