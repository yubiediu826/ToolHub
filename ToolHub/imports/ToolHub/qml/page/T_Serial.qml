import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import FluentUI 1.0
import "../Components"

FluScrollablePage {
    id: serialPage
    launchMode: FluPageType.SingleTask
    animationEnabled: false
    property var _route: ({})
    property var argument: ({})
    header: Item {}

    SerialCube_PageHeader {
        title: qsTr("串口监听")
        subtitle: qsTr("Serial Monitor · 实时监视串口收发 · HEX / 文本自动滚屏")
        iconSource: FluentIcons.Connect
    }

    SerialCube_Placeholder {
        iconSource: FluentIcons.Wrench
        message: qsTr("页面建设中")
        hint: qsTr("后续版本会接入具体功能")
    }

    Item { Layout.fillHeight: true }
}
