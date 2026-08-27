import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import FluentUI 1.0
import "../Components"

FluScrollablePage {
    id: dataPage
    launchMode: FluPageType.SingleTask
    animationEnabled: false
    property var _route: ({})
    property var argument: ({})
    header: Item {}

    SerialCube_PageHeader {
        title: qsTr("数据分析")
        subtitle: qsTr("Data Analysis · CSV / JSON 导入 · 图表 + 透视表 · 导出报告")
        iconSource: FluentIcons.AreaChart
    }

    SerialCube_Placeholder {
        iconSource: FluentIcons.Wrench
        message: qsTr("页面建设中")
        hint: qsTr("后续版本会接入具体功能")
    }

    Item { Layout.fillHeight: true }
}
