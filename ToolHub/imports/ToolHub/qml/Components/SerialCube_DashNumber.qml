import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import FluentUI 1.0

/** 数值卡：标题 + 大数值 + 单位。value 为 null 时显示 "--"。 */
FluFrame {
    id: root
    property string title: ""
    property var value: null       // number 或 string
    property string unit: ""
    radius: 8
    padding: 12

    ColumnLayout {
        anchors.fill: parent
        spacing: 4

        FluText {
            text: root.title
            font: FluTextStyle.Body
            color: FluTheme.fontSecondaryColor
        }
        RowLayout {
            spacing: 4
            FluText {
                text: root.value === null || root.value === undefined ? "--"
                      : (typeof root.value === "number" ? root.value.toFixed(2) : root.value)
                font: FluTextStyle.Title
                color: FluTheme.fontPrimaryColor
            }
            FluText {
                text: root.unit
                font: FluTextStyle.Body
                color: FluTheme.fontTertiaryColor
                visible: root.unit !== ""
                Layout.alignment: Qt.AlignBottom
                Layout.bottomMargin: 4
            }
        }
    }
}
