import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import FluentUI 1.0
import "../Components"
import "../global"

FluScrollablePage {
    id: homePage
    launchMode: FluPageType.SingleTask
    animationEnabled: false
    property var _route: ({})
    property var argument: ({})
    header: Item {}

    // 顶部欢迎区
    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: 320

        Image {
            id: bg
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            verticalAlignment: Qt.AlignTop
            sourceSize: Qt.size(960, 640)
            source: "qrc:/ToolHub/image/bg_home_header.png"
        }
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.8; color: FluTheme.dark ? Qt.rgba(0,0,0,0) : Qt.rgba(1,1,1,0) }
                GradientStop { position: 1.0; color: FluTheme.dark ? Qt.rgba(0,0,0,1) : Qt.rgba(1,1,1,1) }
            }
        }

        FluText {
            text: qsTr("欢迎使用 ToolHub")
            font: FluTextStyle.TitleLarge
            color: FluTheme.fontPrimaryColor
            anchors {
                top: parent.top
                left: parent.left
                topMargin: 30
                leftMargin: 30
            }
        }
        FluText {
            text: qsTr("统一管理你的桌面工具 · 基于 FluentUI")
            font: FluTextStyle.Body
            color: FluTheme.fontSecondaryColor
            anchors {
                top: parent.top
                left: parent.left
                topMargin: 80
                leftMargin: 30
            }
        }
    }

    // "最近添加" section
    FluText {
        Layout.topMargin: 20
        Layout.leftMargin: 20
        text: qsTr("最近添加")
        font: FluTextStyle.Title
    }

    GridLayout {
        Layout.fillWidth: true
        Layout.topMargin: 12
        Layout.leftMargin: 20
        Layout.rightMargin: 20
        Layout.bottomMargin: 30
        columns: 2
        columnSpacing: 20
        rowSpacing: 20

        SerialCube_CardItem {
            Layout.fillWidth: true
            Layout.preferredHeight: 130
            title: qsTr("串口调试")
            desc: qsTr("串口数据收发，HEX / 文本切换，多会话，时间分包与日志统计。")
            icon: FluentIcons.Connect
            onClicked: {
                if (NavModel.navView)
                    NavModel.navView.push("qrc:/ToolHub/qml/page/T_Serial.qml")
            }
        }
    }
}
