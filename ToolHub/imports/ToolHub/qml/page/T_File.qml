import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import FluentUI 1.0
import "../Components"

FluScrollablePage {
    id: filePage
    launchMode: FluPageType.SingleTask
    animationEnabled: false
    property var _route: ({})
    property var argument: ({})
    header: Item {}

    SerialCube_PageHeader {
        title: qsTr("文件处理")
        subtitle: qsTr("File Tools · 批量重命名 / 格式转换 / 元数据提取 · 拖拽即用")
        iconSource: FluentIcons.Document
    }

    SerialCube_Placeholder {
        iconSource: FluentIcons.Wrench
        message: qsTr("页面建设中")
        hint: qsTr("后续版本会接入具体功能")
    }

    Item { Layout.fillHeight: true }
}
