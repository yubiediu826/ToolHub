import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import FluentUI 1.0

/**
 * SerialCube_SettingsRow
 * ----------------------
 * "标签 + 右侧控件"行组件，两种模式：
 *  - wide（默认）：标签左对齐，控件区右锚固定 implicitWidth 200（设置页用）
 *  - narrow：标签固定 72px 左列，控件区填满剩余宽度（工具页窄面板用，防重叠）
 *
 * 使用:
 *   SerialCube_SettingsRow {
 *       label: qsTr("主题")
 *       Layout.fillWidth: true
 *       FluComboBox { ... }   // 直接 children 进控件区
 *   }
 */
Item {
    id: root
    property string label: ""
    property string mode: "wide"   // "wide" | "narrow"
    default property alias content: contentItem.data
    implicitHeight: 50

    FluText {
        id: labelItem
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: root.mode === "narrow" ? 72 : undefined
        elide: Text.ElideRight
        text: root.label
        font: FluTextStyle.Body
    }

    Item {
        id: contentItem
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: 200
        implicitHeight: 30
        // wide: 右锚固定；narrow: 标签右侧填满
        anchors.right: root.mode === "wide" ? parent.right : undefined
        anchors.left: root.mode === "narrow" ? labelItem.right : undefined
        anchors.leftMargin: root.mode === "narrow" ? 8 : 0
        width: root.mode === "narrow" ? parent.width - 80 : implicitWidth
    }
}
