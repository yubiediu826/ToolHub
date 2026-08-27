"""接收日志：缓冲 + 显示格式化 + 收发统计。

对应 SerialTool 数据区设置：显示方式(文本/HEX)、字符编码、自动换行、
显示时间戳、时间分包、最大行数、冻结显示；状态栏 RX/TX 字节/包/速率统计。
"""
from __future__ import annotations

import datetime
import os

from PySide6.QtCore import QObject, QTimer, Signal, Slot, Property

_DEFAULT_MAX_LINES = 10000
_TRIM_KEEP = 0.8  # 超限时裁剪到 80%，避免频繁裁剪


def _fmt_bytes(n: int) -> str:
    if n >= 1024 * 1024:
        return f"{n / 1024 / 1024:.2f} MB"
    if n >= 1024:
        return f"{n / 1024:.1f} KB"
    return f"{n} B"


class RxLog(QObject):
    """QML 直接绑定 logText 与统计属性；原始字节经 on_rx/on_tx 进入。"""

    logTextChanged = Signal()
    statsChanged = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._lines: list[str] = []
        self._hex_view = False
        self._timestamp_mode = 1        # 0=关闭 1=时间 2=日期时间
        self._encoding = "auto"         # auto / utf-8 / gbk
        self._auto_wrap = True
        self._time_packet_ms = 20       # 0=不分包（每个读取块立即成行）
        self._max_lines = _DEFAULT_MAX_LINES
        self._frozen = False
        self._show_tx = True

        self._rx_bytes = 0
        self._tx_bytes = 0
        self._rx_packets = 0
        self._tx_packets = 0
        self._rx_rate = 0
        self._tx_rate = 0
        self._rx_rate_window = 0
        self._tx_rate_window = 0

        # 时间分包：同方向数据在窗口期内并入同一条目
        self._rx_group = bytearray()
        self._tx_group = bytearray()
        self._flush_timer = QTimer(self)
        self._flush_timer.setInterval(max(self._time_packet_ms, 1))
        self._flush_timer.timeout.connect(self._flush_groups)
        self._flush_timer.start()

        self._rate_timer = QTimer(self)
        self._rate_timer.setInterval(1000)
        self._rate_timer.timeout.connect(self._tick_rate)
        self._rate_timer.start()

    # ---- 显示设置属性 ----
    @Property(str, notify=logTextChanged)
    def logText(self):
        return "\n".join(self._lines)

    @Property(bool)
    def hexView(self):
        return self._hex_view

    @hexView.setter
    def hexView(self, v: bool):
        self._hex_view = v

    @Property(int)
    def timestampMode(self):
        return self._timestamp_mode

    @timestampMode.setter
    def timestampMode(self, v: int):
        self._timestamp_mode = int(v)

    @Property(str)
    def encoding(self):
        return self._encoding

    @encoding.setter
    def encoding(self, v: str):
        self._encoding = v

    @Property(bool)
    def autoWrap(self):
        return self._auto_wrap

    @autoWrap.setter
    def autoWrap(self, v: bool):
        self._auto_wrap = v

    @Property(int)
    def timePacketMs(self):
        return self._time_packet_ms

    @timePacketMs.setter
    def timePacketMs(self, v: int):
        self._time_packet_ms = max(int(v), 0)
        self._flush_timer.setInterval(max(self._time_packet_ms, 1))

    @Property(int)
    def maxLines(self):
        return self._max_lines

    @maxLines.setter
    def maxLines(self, v: int):
        self._max_lines = max(int(v), 100)

    @Property(bool)
    def frozen(self):
        return self._frozen

    @frozen.setter
    def frozen(self, v: bool):
        self._frozen = v

    @Property(bool)
    def showTx(self):
        return self._show_tx

    @showTx.setter
    def showTx(self, v: bool):
        self._show_tx = v

    # ---- 统计属性 ----
    @Property(int, notify=statsChanged)
    def rxBytes(self):
        return self._rx_bytes

    @Property(int, notify=statsChanged)
    def txBytes(self):
        return self._tx_bytes

    @Property(int, notify=statsChanged)
    def rxPackets(self):
        return self._rx_packets

    @Property(int, notify=statsChanged)
    def txPackets(self):
        return self._tx_packets

    @Property(int, notify=statsChanged)
    def rxRate(self):
        return self._rx_rate

    @Property(int, notify=statsChanged)
    def txRate(self):
        return self._tx_rate

    @staticmethod
    def fmtBytes(n: int) -> str:
        return _fmt_bytes(n)

    # ---- 数据入口 ----
    @Slot(bytes)
    def on_rx(self, data: bytes):
        self._rx_bytes += len(data)
        self._rx_rate_window += len(data)
        if not self._frozen:
            self._rx_group.extend(data)
        self.statsChanged.emit()

    @Slot(bytes)
    def on_tx(self, data: bytes):
        self._tx_bytes += len(data)
        self._tx_rate_window += len(data)
        if not self._frozen and self._show_tx:
            self._tx_group.extend(data)
        self.statsChanged.emit()

    def _flush_groups(self):
        if self._rx_group:
            self._append_line("RX", bytes(self._rx_group))
            self._rx_packets += 1
            self._rx_group.clear()
            self.statsChanged.emit()
        if self._tx_group:
            self._append_line("TX", bytes(self._tx_group))
            self._tx_packets += 1
            self._tx_group.clear()
            self.statsChanged.emit()

    def _tick_rate(self):
        self._rx_rate = self._rx_rate_window
        self._tx_rate = self._tx_rate_window
        self._rx_rate_window = 0
        self._tx_rate_window = 0
        self.statsChanged.emit()

    def _decode(self, data: bytes) -> str:
        if self._encoding == "utf-8":
            return data.decode("utf-8", errors="replace")
        if self._encoding == "gbk":
            return data.decode("gbk", errors="replace")
        try:  # auto
            return data.decode("utf-8")
        except UnicodeDecodeError:
            return data.decode("gbk", errors="replace")

    def _append_line(self, direction: str, data: bytes):
        ts = ""
        if self._timestamp_mode == 1:
            ts = datetime.datetime.now().strftime("%H:%M:%S.%f")[:-3] + "  "
        elif self._timestamp_mode == 2:
            ts = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S") + "  "
        prefix = f"{ts}[{direction}] "
        if self._hex_view:
            payload = " ".join(f"{b:02X}" for b in data)
            lines = [prefix + payload[i:i + 48].rstrip()
                     for i in range(0, len(payload), 48)]
            self._lines.extend(lines)
        else:
            text = self._decode(data)
            if not self._auto_wrap:
                text = text.replace("\r", "\\r").replace("\n", "\\n")
            lines = text.split("\n")
            lines[0] = prefix + lines[0]
            self._lines.extend(lines)
        limit = self._max_lines
        if len(self._lines) > limit:
            keep = int(limit * _TRIM_KEEP)
            del self._lines[: len(self._lines) - keep]
        self.logTextChanged.emit()

    # ---- 操作 ----
    @Slot()
    def clear(self):
        self._lines.clear()
        self._rx_bytes = self._tx_bytes = 0
        self._rx_packets = self._tx_packets = 0
        self._rx_rate = self._tx_rate = 0
        self._rx_rate_window = self._tx_rate_window = 0
        self.logTextChanged.emit()
        self.statsChanged.emit()

    @Slot(str, str)
    def save(self, path: str = "", default_name: str = ""):
        if not path:
            path = os.path.join(os.path.expanduser("~"), "Downloads")
        if os.path.isdir(path):
            name = default_name or ("serial_log_%s.txt"
                                    % datetime.datetime.now().strftime("%Y%m%d_%H%M%S"))
            path = os.path.join(path, name)
        try:
            with open(path, "w", encoding="utf-8") as f:
                f.write("\n".join(self._lines))
        except OSError:
            pass
