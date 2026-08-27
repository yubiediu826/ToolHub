import os
import sys

from PySide6.QtCore import QCoreApplication, QTranslator, QUrl, QLocale
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine

from FluentUI import FluentUI
from FluentUI.FluLogger import LogSetup, Logger
from ToolHub.imports import resource_rc as rc
from ToolHub.serialport.session_manager import SerialSessionManager


def main():
    os.environ["QT_QUICK_CONTROLS_STYLE"] = "Basic"
    # 2026-08-26: 给 Qt.labs.settings 显式命名空间,避免落默认组织污染
    # (Windows 注册表: HKEY_CURRENT_USER\Software\ToolHub\ToolHub)
    QCoreApplication.setOrganizationName("ToolHub")
    QCoreApplication.setApplicationName("ToolHub")
    LogSetup("ToolHub")
    Logger().debug(f"Load the resource '{rc.__name__}'")
    app = QGuiApplication(sys.argv)

    translator = QTranslator()
    uiLanguages = QLocale.system().uiLanguages()
    for locale in uiLanguages:
        # 匹配 resource.qrc 注册的 qrc:/ToolHub/i18n/ToolHub_<locale>.qm
        baseName = "ToolHub_" + QLocale(locale).name()
        if translator.load(":/ToolHub/i18n/" + baseName):
            app.installTranslator(translator)
            break

    engine = QQmlApplicationEngine()
    session_manager = SerialSessionManager()
    engine.rootContext().setContextProperty("SerialSessions", session_manager)
    FluentUI.registerTypes(engine)
    url = QUrl("qrc:/ToolHub/qml/App.qml")
    engine.load(url)
    if not engine.rootObjects():
        sys.exit(-1)
    return app.exec()


if __name__ == "__main__":
    main()
