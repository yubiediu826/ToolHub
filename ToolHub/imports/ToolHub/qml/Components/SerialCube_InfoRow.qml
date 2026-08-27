import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import FluentUI 1.0

/**
 * SerialCube_InfoRow
 * ------------------
 * 关于页"标签 + 值"行。左标签次要色,右值主色。
 *
 * 使用:
 *   SerialCube_InfoRow {
 *       label: qsTr("UI 框架")
 *       value: qsTr("FluentUI / Qt 6.7 / PySide6")
 *   }
 */
RowLayout {
    id: root
    property string label: ""
    property string value: ""
    Layout.fillWidth: true

    FluText {
        text: root.label
        color: FluTheme.fontSecondaryColor
        font: FluTextStyle.Body
    }
    Item { Layout.fillWidth: true }
    FluText {
        text: root.value
        font: FluTextStyle.Body
    }
}
