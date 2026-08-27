import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import FluentUI 1.0
import "../Components"

FluScrollablePage {
    id: aboutPage
    launchMode: FluPageType.SingleTask
    animationEnabled: false
    property var _route: ({})
    property var argument: ({})
    header: Item {}

    ColumnLayout {
        Layout.fillWidth: true
        Layout.topMargin: 30
        Layout.alignment: Qt.AlignHCenter
        spacing: 12

        // Logo
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            width: 80
            height: 80
            radius: 12
            color: FluTheme.primaryColor
            opacity: 0.2

            FluIcon {
                anchors.centerIn: parent
                iconSource: FluentIcons.Toolbox
                iconSize: 42
                color: FluTheme.primaryColor
            }
        }

        FluText {
            Layout.alignment: Qt.AlignHCenter
            text: "ToolHub"
            font: FluTextStyle.TitleLarge
        }
        FluText {
            Layout.alignment: Qt.AlignHCenter
            text: qsTr("版本 1.0.0")
            color: FluTheme.fontSecondaryColor
            font: FluTextStyle.Body
        }
        FluText {
            Layout.alignment: Qt.AlignHCenter
            text: qsTr("基于 FluentUI / PySide6 构建")
            color: FluTheme.fontSecondaryColor
            font: FluTextStyle.Caption
        }
    }

    // 分隔线(用 FluDivider)
    FluDivider {
        Layout.fillWidth: true
        Layout.topMargin: 40
        Layout.leftMargin: 40
        Layout.rightMargin: 40
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.topMargin: 20
        Layout.leftMargin: 40
        Layout.rightMargin: 40
        spacing: 10

        SerialCube_InfoRow { label: qsTr("项目类型"); value: qsTr("tool-launcher") }
        SerialCube_InfoRow { label: qsTr("UI 框架"); value: qsTr("FluentUI / Qt 6.7 / PySide6") }
        SerialCube_InfoRow { label: qsTr("Python"); value: qsTr("3.11.9") }
        SerialCube_InfoRow { label: qsTr("工作流"); value: qsTr("SerialCube 通用工作流") }
        SerialCube_InfoRow { label: qsTr("源码许可"); value: qsTr("MIT") }
    }

    // 致谢
    ColumnLayout {
        Layout.fillWidth: true
        Layout.topMargin: 40
        Layout.leftMargin: 40
        Layout.rightMargin: 40
        Layout.bottomMargin: 30
        spacing: 6

        FluText {
            text: qsTr("致谢")
            font: FluTextStyle.BodyStrong
        }
        FluText {
            text: "zhuzichu520 / FluentUI"
            color: FluTheme.fontSecondaryColor
            font: FluTextStyle.Caption
        }
        FluText {
            text: "Qt Project / PySide6"
            color: FluTheme.fontSecondaryColor
            font: FluTextStyle.Caption
        }
    }
}
