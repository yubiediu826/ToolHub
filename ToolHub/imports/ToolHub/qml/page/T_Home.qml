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
        columns: 2
        columnSpacing: 20
        rowSpacing: 20

        SerialCube_CardItem {
            Layout.fillWidth: true
            Layout.preferredHeight: 130
            title: qsTr("串口监听工具")
            desc: qsTr("实时监视串口收发，支持 HEX / 文本切换，自动滚屏，HEX 收发一应俱全。")
            icon: FluentIcons.Connect
            onClicked: { }
        }
        SerialCube_CardItem {
            Layout.fillWidth: true
            Layout.preferredHeight: 130
            title: qsTr("网络调试助手")
            desc: qsTr("TCP / UDP 客户端 + 服务端，多会话管理，协议解析器。")
            icon: FluentIcons.Globe
            onClicked: { }
        }
        SerialCube_CardItem {
            Layout.fillWidth: true
            Layout.preferredHeight: 130
            title: qsTr("文件批量处理")
            desc: qsTr("重命名 / 转换格式 / 提取元数据，拖拽即用。")
            icon: FluentIcons.Document
            onClicked: { }
        }
        SerialCube_CardItem {
            Layout.fillWidth: true
            Layout.preferredHeight: 130
            title: qsTr("数据分析面板")
            desc: qsTr("CSV / JSON 导入，图表 + 透视表，导出报告。")
            icon: FluentIcons.AreaChart
            onClicked: { }
        }
    }

    // "推荐工具" section
    FluText {
        Layout.topMargin: 30
        Layout.leftMargin: 20
        text: qsTr("推荐工具")
        font: FluTextStyle.Title
    }

    GridLayout {
        Layout.fillWidth: true
        Layout.topMargin: 12
        Layout.leftMargin: 20
        Layout.rightMargin: 20
        Layout.bottomMargin: 30
        columns: 3
        columnSpacing: 20
        rowSpacing: 20

        SerialCube_CardItem {
            Layout.fillWidth: true
            Layout.preferredHeight: 100
            title: qsTr("剪贴板历史")
            icon: FluentIcons.History
            onClicked: { }
        }
        SerialCube_CardItem {
            Layout.fillWidth: true
            Layout.preferredHeight: 100
            title: qsTr("屏幕取色器")
            icon: FluentIcons.Color
            onClicked: { }
        }
        SerialCube_CardItem {
            Layout.fillWidth: true
            Layout.preferredHeight: 100
            title: qsTr("JSON 格式化")
            icon: FluentIcons.Code
            onClicked: { }
        }
        SerialCube_CardItem {
            Layout.fillWidth: true
            Layout.preferredHeight: 100
            title: qsTr("二维码生成")
            icon: FluentIcons.QRCode
            onClicked: { }
        }
        SerialCube_CardItem {
            Layout.fillWidth: true
            Layout.preferredHeight: 100
            title: qsTr("时间戳转换")
            icon: FluentIcons.History
            onClicked: { }
        }
        SerialCube_CardItem {
            Layout.fillWidth: true
            Layout.preferredHeight: 100
            title: qsTr("编码转换")
            icon: FluentIcons.Page
            onClicked: { }
        }
    }
}
