"""接收日志：缓冲 + 显示格式化（text/hexdump、时间戳、收发着色分方向）。"""
from __future__ import annotations

import datetime
import os

from PySide6.QtCore import QObject, Signal, Slot, Property

_MAX_LINES = 5000
_LINE_TRIM_TO = 3000


class RxLog(QObject):
    """把原始字节流格式化为带时间戳/方向的日志行，QML 直接绑定 logText。"""

    logTextChanged = Signal()
    rxCountChanged = Signal()
    txCountChanged = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._lines: list[str] = []
        self._hex_view = False
        self._show_timestamp = True
        self._rx_count = 0
        self._tx_count = 0

    # ---- 属性 ----
    @Property(str, notify=logTextChanged)
    def logText(self):
        return "\n".join(self._lines)

    @Property(bool)
    def hexView(self):
        return self._hex_view

    @hexView.setter
    def hexView(self, v: bool):
        self._hex_view = v

    @Property(bool)
    def showTimestamp(self):
        return self._show_timestamp

    @showTimestamp.setter
    def showTimestamp(self, v: bool):
        self._show_timestamp = v

    @Property(int, notify=rxCountChanged)
    def rxCount(self):
        return self._rx_count

    @Property(int, notify=txCountChanged)
    def txCount(self):
        return self._tx_count

    # ---- 数据入口 ----
    @Slot(bytes)
    def on_rx(self, data: bytes):
        self._rx_count += len(data)
        self.rxCountChanged.emit()
        self._append("RX", data)

    @Slot(bytes)
    def on_tx(self, data: bytes):
        self._tx_count += len(data)
        self.txCountChanged.emit()
        self._append("TX", data)

    def _append(self, direction: str, data: bytes):
        ts = (datetime.datetime.now().strftime("%H:%M:%S.%f")[:-3] + "  "
              if self._show_timestamp else "")
        if self._hex_view:
            payload = " ".join(f"{b:02X}" for b in data)
        else:
            payload = data.decode("utf-8", errors="replace")
        prefix = f"{ts}[{direction}] "
        # 长包按 16 字节折行（hexdump 风格）
        if self._hex_view and len(data) > 16:
            rows = [payload[i:i + 48].strip() for i in range(0, len(payload), 48)]
            self._lines.append(prefix + rows[0])
            self._lines.extend("         " + r for r in rows[1:])
        else:
            self._lines.append(prefix + payload)
        if len(self._lines) > _MAX_LINES:
            del self._lines[: len(self._lines) - _LINE_TRIM_TO]
        self.logTextChanged.emit()

    @Slot()
    def clear(self):
        self._lines.clear()
        self._rx_count = 0
        self._tx_count = 0
        self.rxCountChanged.emit()
        self.txCountChanged.emit()
        self.logTextChanged.emit()

    @Slot(str)
    @Slot(str, str)
    def save(self, path: str, default_name="serial_log.txt"):
        if os.path.isdir(path):  # QML 传目录时用默认文件名
            path = os.path.join(path, default_name)
        try:
            with open(path, "w", encoding="utf-8") as f:
                f.write("\n".join(self._lines))
        except OSError:
            pass
