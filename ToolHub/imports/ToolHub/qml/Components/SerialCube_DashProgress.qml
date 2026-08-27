import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import FluentUI 1.0

/** 进度卡：SOC/SOH 等百分比指标。 */
FluFrame {
    id: root
    property string title: ""
    property var value: null       // 0-100
    property string unit: "%"
    radius: 8
    padding: 12

    ColumnLayout {
        anchors.fill: parent
        spacing: 6

        Item {
            Layout.fillWidth: true
            height: 20
            FluText {
                anchors.left: parent.left
                text: root.title
                font: FluTextStyle.Body
                color: FluTheme.fontSecondaryColor
            }
            FluText {
                anchors.right: parent.right
                text: root.value === null || root.value === undefined ? "--"
                      : Math.round(root.value) + root.unit
                font: FluTextStyle.BodyStrong
                color: FluTheme.primaryColor
            }
        }
        FluProgressBar {
            Layout.fillWidth: true
            from: 0
            to: 100
            value: root.value === null || root.value === undefined ? 0
                   : Math.max(0, Math.min(100, Number(root.value)))
        }
    }
}
