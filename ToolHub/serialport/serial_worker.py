"""串口 Worker：pyserial 封装，I/O 在 QThread，UI 线程只收 Signal。

高频接收数据在 Reader 线程内缓冲，由主线程 16ms 定时器批量 emit（code-conventions 第 4 节）。
"""
from __future__ import annotations

import serial  # pyserial
from serial.tools import list_ports
from PySide6.QtCore import QObject, QTimer, Signal, Slot, Property

BAUD_RATES = [1200, 2400, 4800, 9600, 19200, 38400, 57600, 115200,
              230400, 460800, 921600, 1000000, 2000000]
DATA_BITS = [8, 7, 6, 5]
PARITIES = ["None", "Even", "Odd", "Mark", "Space"]
STOP_BITS = [1, 1.5, 2]
FLOW_CONTROLS = ["None", "RTS/CTS", "XON/XOFF"]

_PARITY_MAP = {"None": serial.PARITY_NONE, "Even": serial.PARITY_EVEN,
               "Odd": serial.PARITY_ODD, "Mark": serial.PARITY_MARK,
               "Space": serial.PARITY_SPACE}
_STOPBIT_MAP = {1: serial.STOPBITS_ONE, 1.5: serial.STOPBITS_ONE_POINT_FIVE,
                2: serial.STOPBITS_TWO}
_FLOW_MAP = {"None": (False, False), "RTS/CTS": (True, False), "XON/XOFF": (False, True)}


class _Reader(QObject):
    """运行在串口线程中的读循环对象。"""

    def __init__(self, port: serial.Serial):
        super().__init__()
        self._port = port
        self._running = True
        self.pending = bytearray()

    def run(self):
        while self._running:
            try:
                data = self._port.read(4096)
            except (serial.SerialException, OSError):
                self._running = False
                break
            if data:
                self.pending.extend(data)


class SerialWorker(QObject):
    portOpenedChanged = Signal()
    errorOccurred = Signal(str)
    bytesReceived = Signal(bytes)   # 原始数据（协议解析等复用）
    bytesSent = Signal(bytes)

    def __init__(self, parent=None):
        super().__init__(parent)
        self._opened = False
        self._local_echo = False
        self._port: serial.Serial | None = None
        self._thread = None
        self._reader: _Reader | None = None
        self._params = {"port": "", "baud": 115200, "databits": 8,
                        "parity": "None", "stopbits": 1, "flow": "None"}
        # 16ms 批量上报，避免每字节一次 Signal
        self._flush_timer = QTimer(self)
        self._flush_timer.setInterval(16)
        self._flush_timer.timeout.connect(self._flush_rx)

    @Property(bool, notify=portOpenedChanged)
    def opened(self):
        return self._opened

    @Property(bool)
    def localEcho(self):
        return self._local_echo

    @localEcho.setter
    def localEcho(self, v: bool):
        self._local_echo = v

    @Slot()
    def list_ports(self):
        return [f"{p.device} — {p.description}" for p in list_ports.comports()]

    @Slot(str, int, int, str, float, str)
    def set_params(self, port, baud, databits, parity, stopbits, flow):
        self._params = {"port": port, "baud": int(baud), "databits": int(databits),
                        "parity": parity, "stopbits": float(stopbits), "flow": flow}

    @Slot()
    def open_port(self):
        if self._opened:
            return
        p = self._params
        rtscts, xonxoff = _FLOW_MAP.get(p["flow"], (False, False))
        try:
            self._port = serial.Serial(
                port=p["port"], baudrate=p["baud"], bytesize=p["databits"],
                parity=_PARITY_MAP.get(p["parity"], serial.PARITY_NONE),
                stopbits=_STOPBIT_MAP.get(p["stopbits"], serial.STOPBITS_ONE),
                rtscts=rtscts, xonxoff=xonxoff, timeout=0.02)
        except (serial.SerialException, OSError) as e:
            self.errorOccurred.emit(str(e))
            return
        import threading
        self._reader = _Reader(self._port)
        self._thread = threading.Thread(target=self._reader.run, daemon=True)
        self._thread.start()
        self._opened = True
        self._flush_timer.start()
        self.portOpenedChanged.emit()

    @Slot()
    def close_port(self):
        if not self._opened:
            return
        self._flush_timer.stop()
        self._flush_rx()
        if self._reader:
            self._reader._running = False
        if self._thread:
            self._thread.join(timeout=1.0)
        try:
            self._port.close()
        except (serial.SerialException, OSError):
            pass
        self._reader = None
        self._thread = None
        self._port = None
        self._opened = False
        self.portOpenedChanged.emit()

    @Slot(str, bool, int)
    def send(self, text, hex_mode, eol=0):
        """eol: 0=无 1=CR 2=LF 3=CRLF（仅文本模式生效）"""
        if not self._opened or not text:
            return
        if not hex_mode:
            suffix = {0: "", 1: "\r", 2: "\n", 3: "\r\n"}.get(int(eol), "")
            text = text + suffix
        try:
            data = (bytes.fromhex(text.replace(" ", "").replace(",", "").replace("\r", "").replace("\n", ""))
                    if hex_mode else text.encode("utf-8", errors="replace"))
        except ValueError:
            self.errorOccurred.emit("HEX 输入格式无效")
            return
        try:
            self._port.write(data)
            self.bytesSent.emit(data)
            if self._local_echo:
                self.bytesReceived.emit(data)
        except (serial.SerialException, OSError) as e:
            self.errorOccurred.emit(str(e))

    def _flush_rx(self):
        r = self._reader
        if r and r.pending:
            chunk = bytes(r.pending)
            r.pending.clear()
            self.bytesReceived.emit(chunk)
