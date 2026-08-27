import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import FluentUI 1.0

/** 状态卡：位图 → LED 灯组（点亮=激活）。mask 为整数位图。 */
FluFrame {
    id: root
    property string title: ""
    property var bits: []          // 位名称表
    property var mask: 0
    radius: 8
    padding: 12

    ColumnLayout {
        anchors.fill: parent
        spacing: 6

        FluText {
            text: root.title
            font: FluTextStyle.Body
            color: FluTheme.fontSecondaryColor
        }
        Flow {
            Layout.fillWidth: true
            spacing: 10
            Repeater {
                model: root.bits.length
                delegate: RowLayout {
                    spacing: 4
                    Rectangle {
                        Layout.preferredWidth: 8
                        Layout.preferredHeight: 8
                        radius: 4
                        color: (Number(root.mask) & (1 << index))
                               ? FluColors.Red.normal
                               : FluTheme.fontTertiaryColor
                        opacity: (Number(root.mask) & (1 << index)) ? 1 : 0.35
                    }
                    FluText {
                        text: root.bits[index] || (index + 1 + "位")
                        font: FluTextStyle.Caption
                        color: (Number(root.mask) & (1 << index))
                               ? FluTheme.fontPrimaryColor : FluTheme.fontTertiaryColor
                    }
                }
            }
        }
    }
}
