import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import FluentUI 1.0

/**
 * SerialCube_PageHeader
 * -------------------
 * 页面顶部"色条 + 图标方块 + 标题 + 副标题"通用组件。
 * 用于 4 个工具页(T_Serial/T_Network/T_File/T_Data)和 4 个收藏/最近页。
 *
 * 设计依据:
 * - 色块背景用 FluTheme.primaryColor + opacity,不硬色
 * - 左侧 4px 色条同样用主题色
 * - 图标方块也用主题色填充
 * - 标题/副标题走 FluTextStyle
 */
Item {
    id: root

    // ===== 公开属性 =====
    property string title: ""
    property string subtitle: ""
    property int iconSource: 0          // FluentIcons.<Name>
    property color accentColor: FluTheme.primaryColor  // 默认主题色,可被 page 覆盖
    property int preferredHeight: 110

    // 宽度策略:父是 Layout(ColumnLayout/RowLayout)时由 Layout.fillWidth 控制;
    // 父是普通 Item 时,显式跟随父宽。两者都覆盖了默认 implicitWidth=0 的退化场景。
    Layout.fillWidth: true
    Layout.preferredHeight: preferredHeight
    width: parent ? parent.width : 0
    height: preferredHeight

    // 背景色块(主题色 + 低透明度)
    Rectangle {
        anchors.fill: parent
        color: root.accentColor
        opacity: 0.10
    }
    // 左侧色条
    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 4
        color: root.accentColor
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 28
        anchors.rightMargin: 28
        spacing: 16

        // 图标方块
        Rectangle {
            width: 52
            height: 52
            radius: 10
            color: root.accentColor

            FluIcon {
                anchors.centerIn: parent
                iconSource: root.iconSource
                iconSize: 26
                color: "white"
            }
        }

        // 标题 + 副标题
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            FluText {
                text: root.title
                font: FluTextStyle.Title
            }
            FluText {
                text: root.subtitle
                color: FluTheme.fontSecondaryColor
                font: FluTextStyle.Body
            }
        }
    }
}
