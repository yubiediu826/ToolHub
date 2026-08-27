"""多会话管理：每个会话独立持有 SerialWorker + RxLog + 视图状态。

QML 通过 SerialSessions 上下文属性访问；会话对象生命周期由 Manager 持有。
"""
from __future__ import annotations

from PySide6.QtCore import QObject, Property, Signal, Slot

from ToolHub.serialport.serial_worker import SerialWorker
from ToolHub.serialport.rx_log import RxLog


class SerialSession(QObject):
    """单个串口会话：worker/log + 视图状态（面板折叠、会话名）。"""

    nameChanged = Signal()
    panelCollapsedChanged = Signal()

    def __init__(self, index: int, parent=None):
        super().__init__(parent)
        self._index = index
        self._base_name = f"会话 {index}"
        self._worker = SerialWorker(self)
        self._log = RxLog(self)
        self._worker.bytesReceived.connect(self._log.on_rx)
        self._worker.bytesSent.connect(self._log.on_tx)
        self._panel_collapsed = False
        self._worker.portOpenedChanged.connect(self.nameChanged)

    @Property(str, notify=nameChanged)
    def name(self):
        return self._worker.portName if self._worker.opened else self._base_name

    @Property(bool, notify=panelCollapsedChanged)
    def panelCollapsed(self):
        return self._panel_collapsed

    @panelCollapsed.setter
    def panelCollapsed(self, v: bool):
        self._panel_collapsed = bool(v)
        self.panelCollapsedChanged.emit()

    @Property(QObject, constant=True)
    def worker(self):
        return self._worker

    @Property(QObject, constant=True)
    def log(self):
        return self._log

    @Slot()
    def closePort(self):
        self._worker.close_port()


class SerialSessionManager(QObject):
    sessionsChanged = Signal()
    activeChanged = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._sessions: list[SerialSession] = []
        self._active = -1

    @Property("QVariantList", notify=sessionsChanged)
    def sessions(self):
        return self._sessions

    @Property(int, notify=activeChanged)
    def activeIndex(self):
        return self._active

    @activeIndex.setter
    def activeIndex(self, v: int):
        v = int(v)
        if 0 <= v < len(self._sessions) and v != self._active:
            self._active = v
            self.activeChanged.emit()

    @Property(QObject, notify=activeChanged)
    def activeSession(self):
        if 0 <= self._active < len(self._sessions):
            return self._sessions[self._active]
        return None

    @Slot()
    def createSession(self):
        # 序号取历史最大值 +1，关闭后会话号不回收，避免混淆
        used = [int(s._base_name.split()[-1]) for s in self._sessions]
        idx = max(used, default=0) + 1
        session = SerialSession(idx, self)
        self._sessions.append(session)
        self._active = len(self._sessions) - 1
        self.sessionsChanged.emit()
        self.activeChanged.emit()
        return session

    @Slot(int)
    def closeSession(self, index: int):
        if not (0 <= index < len(self._sessions)):
            return
        session = self._sessions.pop(index)
        session.closePort()
        session.setParent(None)
        session.deleteLater()
        if self._sessions:
            self._active = min(self._active, len(self._sessions) - 1)
            if self._active < 0:
                self._active = 0
        else:
            self._active = -1
        self.sessionsChanged.emit()
        self.activeChanged.emit()

    @Slot()
    def ensureAtLeastOne(self):
        """页面打开时保证至少一个会话。"""
        if not self._sessions:
            self.createSession()
