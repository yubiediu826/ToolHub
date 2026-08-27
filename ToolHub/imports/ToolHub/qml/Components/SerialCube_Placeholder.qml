import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import FluentUI 1.0

/**
 * SerialCube_Placeholder
 * ----------------------
 * "页面建设中"占位框。用于未完工的 4 个工具页 + 4 个收藏/最近页。
 * 整框基于 FluTheme 透明度色,不硬 rgba。
 */
Item {
    id: root
    property int preferredHeight: 260
    property string message: qsTr("页面建设中")
    property string hint: qsTr("后续版本会接入具体功能")
    property int iconSource: 0  // 默认 0 = 无图标

    Layout.fillWidth: true
    Layout.preferredHeight: preferredHeight
    Layout.topMargin: 30

    // 占位框 —— 用 FluTheme 透明度色
    Rectangle {
        anchors.fill: parent
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        radius: 8
        // 0.03 透明度等效"非常浅的灰",用 FluTheme 颜色算出来
        color: FluTheme.dark
            ? Qt.rgba(1, 1, 1, 0.03)
            : Qt.rgba(0, 0, 0, 0.03)
        border.width: 1
        // 0.06 透明度等效"非常浅的边框"
        border.color: FluTheme.dark
            ? Qt.rgba(1, 1, 1, 0.06)
            : Qt.rgba(0, 0, 0, 0.06)

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 10

            FluIcon {
                Layout.alignment: Qt.AlignHCenter
                visible: root.iconSource !== 0
                iconSource: root.iconSource
                iconSize: 28
                color: FluTheme.fontSecondaryColor
            }
            FluText {
                Layout.alignment: Qt.AlignHCenter
                text: root.message
                font: FluTextStyle.BodyStrong
                color: FluTheme.fontSecondaryColor
            }
            FluText {
                Layout.alignment: Qt.AlignHCenter
                text: root.hint
                font: FluTextStyle.Caption
                color: FluTheme.fontSecondaryColor
            }
        }
    }
}
