import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import FluentUI 1.0

/**
 * SerialCube_SettingsRow
 * ----------------------
 * 设置页"标签 + 右侧控件"行组件。
 *
 * 使用:
 *   SerialCube_SettingsRow {
 *       label: qsTr("主题")
 *       Layout.fillWidth: true
 *       FluComboBox { ... }   // 直接 children 进右侧
 *   }
 */
Item {
    id: root
    property string label: ""
    default property alias content: contentItem.data
    implicitHeight: 50

    FluText {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: root.label
        font: FluTextStyle.Body
    }

    Item {
        id: contentItem
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: 200
        implicitHeight: 30
    }
}
