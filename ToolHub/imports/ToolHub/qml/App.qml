import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import FluentUI 1.0

FluLauncher {
    id: app
    Component.onCompleted: {
        FluApp.init(app)
        FluApp.windowIcon = "qrc:/ToolHub/image/logo.ico"
        FluRouter.routes = {
            "/": "qrc:/ToolHub/qml/main.qml",
            "/home": "qrc:/ToolHub/qml/page/T_Home.qml",
            "/settings": "qrc:/ToolHub/qml/page/T_Settings.qml",
            "/about": "qrc:/ToolHub/qml/page/T_About.qml",
            "/tool/serial": "qrc:/ToolHub/qml/page/T_Serial.qml",
            "/tool/network": "qrc:/ToolHub/qml/page/T_Network.qml",
            "/tool/file": "qrc:/ToolHub/qml/page/T_File.qml",
            "/tool/data": "qrc:/ToolHub/qml/page/T_Data.qml"
        }
        FluRouter.navigate("/")
    }
}


