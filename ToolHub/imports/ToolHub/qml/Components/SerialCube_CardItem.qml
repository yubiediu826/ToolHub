import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import FluentUI 1.0

/**
 * SerialCube_CardItem
 * -------------------
 * 首页工具卡片。基于 FluFrame + FluShadow,不用裸 Rectangle。
 *
 * 使用:
 *   SerialCube_CardItem {
 *       title: qsTr("串口监听")
 *       desc: qsTr("实时监视串口收发...")
 *       icon: FluentIcons.Connect
 *       onClicked: { ... }
 *   }
 */
Item {
    id: root
    property string title: ""
    property string desc: ""
    property int icon: 0
    signal clicked()

    FluFrame {
        id: cardFrame
        anchors.fill: parent
        radius: 6
        // 三态:pressed / hovered / normal — 跟 FluButton 模式对齐
        // pressed 与 hovered 同色(FluentUI 设计:按下 = 强调 = 同一色)
        color: cardHover.enabled
            ? (cardHover.pressed || cardHover.containsMouse
                ? FluTheme.itemHoverColor
                : FluTheme.itemNormalColor)
            : FluTheme.itemNormalColor

        FluShadow {
            radius: 5
            anchors.fill: parent
        }

        Row {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 16

            // 图标框
            Rectangle {
                width: 50
                height: 50
                radius: 6
                color: FluTheme.primaryColor
                opacity: 0.15
                anchors.verticalCenter: parent.verticalCenter

                FluIcon {
                    anchors.centerIn: parent
                    iconSource: root.icon
                    iconSize: 26
                    color: FluTheme.primaryColor
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 50 - 16
                spacing: 4

                FluText {
                    text: root.title
                    font: FluTextStyle.BodyStrong
                }
                FluText {
                    visible: root.desc.length > 0
                    text: root.desc
                    color: FluTheme.fontSecondaryColor
                    font: FluTextStyle.Caption
                    wrapMode: Text.WrapAnywhere
                    width: parent.width
                }
            }
        }

        MouseArea {
            id: cardHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.clicked()
        }
    }
}
