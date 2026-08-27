import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import FluentUI 1.0
import "../Components"

FluScrollablePage {
    id: networkPage
    launchMode: FluPageType.SingleTask
    animationEnabled: false
    property var _route: ({})
    property var argument: ({})
    header: Item {}

    SerialCube_PageHeader {
        title: qsTr("网络工具")
        subtitle: qsTr("Network Tools · TCP / UDP 客户端 + 服务端 · 多会话管理")
        iconSource: FluentIcons.Globe
    }

    SerialCube_Placeholder {
        iconSource: FluentIcons.Wrench
        message: qsTr("页面建设中")
        hint: qsTr("后续版本会接入具体功能")
    }

    Item { Layout.fillHeight: true }
}
