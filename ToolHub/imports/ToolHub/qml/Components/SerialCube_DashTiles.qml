import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import FluentUI 1.0

/** 瓦片卡：数组值栅格（单体电压/温度族），extremes 时最高红/最低绿高亮。 */
FluFrame {
    id: root
    property string title: ""
    property var values: []        // 数值数组（null=无效）
    property string unit: ""
    property bool extremes: false  // 是否做最高/最低高亮
    radius: 8
    padding: 12

    // 有效值的最值
    readonly property var valid: {
        var arr = []
        for (var i = 0; i < values.length; i++)
            if (values[i] !== null && values[i] !== undefined) arr.push(values[i])
        return arr
    }
    readonly property var maxVal: extremes && valid.length ? Math.max.apply(null, valid) : null
    readonly property var minVal: extremes && valid.length ? Math.min.apply(null, valid) : null

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
                text: root.maxVal !== null ? ("↑" + root.maxVal + " ↓" + root.minVal) : ""
                font: FluTextStyle.Caption
                color: FluTheme.fontTertiaryColor
            }
        }
        GridView {
            id: tileGrid
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            cellWidth: 64
            cellHeight: 44
            interactive: false
            model: root.values.length
            delegate: Rectangle {
                width: tileGrid.cellWidth - 6
                height: tileGrid.cellHeight - 6
                radius: 4
                color: {
                    var v = root.values[index]
                    if (v === null || v === undefined) return FluTheme.dark ? Qt.rgba(1,1,1,0.04) : Qt.rgba(0,0,0,0.03)
                    if (root.extremes && v === root.maxVal) return Qt.rgba(1, 0.2, 0.2, 0.15)
                    if (root.extremes && v === root.minVal) return Qt.rgba(0.1, 0.8, 0.4, 0.15)
                    return FluTheme.dark ? Qt.rgba(1,1,1,0.06) : Qt.rgba(0,0,0,0.04)
                }
                Column {
                    anchors.centerIn: parent
                    spacing: 0
                    FluText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: (index + 1) + "#"
                        font: FluTextStyle.Caption
                        color: FluTheme.fontTertiaryColor
                    }
                    FluText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.values[index] === null || root.values[index] === undefined
                              ? "--" : root.values[index]
                        font: FluTextStyle.Caption
                        color: FluTheme.fontPrimaryColor
                    }
                }
            }
        }
    }
}
