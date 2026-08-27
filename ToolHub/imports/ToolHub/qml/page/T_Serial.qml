import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import FluentUI 1.0
import "../Components"

/**
 * T_Serial — 串口调试
 * 顶部 40px 工具栏：左侧页标题 + 会话标签（●已连接绿点 / 名称 / ×）+ 新建按钮；
 * 内容区为各会话的 SerialCube_SerialSessionView（StackLayout 保持实例存活，
 * 日志/设置随会话保留）。
 */
FluPage {
    id: serialPage
    launchMode: FluPageType.SingleTask
    animationEnabled: false
    padding: 0
    property var _route: ({})
    property var argument: ({})

    Component.onCompleted: SerialSessions.ensureAtLeastOne()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 8

        // ==================== 顶部工具栏（标题 + 会话标签） ====================
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            spacing: 8

            FluText {
                text: qsTr("串口调试")
                font: FluTextStyle.BodyStrong
                Layout.leftMargin: 4
            }
            Rectangle {
                Layout.preferredWidth: 1
                Layout.preferredHeight: 20
                color: FluTheme.dividerColor
            }

            // 会话标签
            Repeater {
                model: SerialSessions.sessions
                delegate: Rectangle {
                    id: sessionTab
                    required property var modelData
                    required property int index
                    Layout.preferredHeight: 32
                    Layout.preferredWidth: tabRow.implicitWidth + 24
                    radius: 4
                    color: SerialSessions.activeIndex === index
                           ? (FluTheme.dark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.05))
                           : (tabHover.hovered ? (FluTheme.dark ? Qt.rgba(1, 1, 1, 0.05) : Qt.rgba(0, 0, 0, 0.03)) : "transparent")

                    RowLayout {
                        id: tabRow
                        anchors.centerIn: parent
                        spacing: 6
                        Rectangle {
                            Layout.preferredWidth: 7
                            Layout.preferredHeight: 7
                            radius: 3.5
                            color: sessionTab.modelData.worker.opened ? FluColors.Green.normal : FluTheme.fontTertiaryColor
                        }
                        FluText {
                            text: sessionTab.modelData.name
                            font: FluTextStyle.Body
                            color: SerialSessions.activeIndex === sessionTab.index
                                   ? FluTheme.fontPrimaryColor : FluTheme.fontSecondaryColor
                        }
                        FluIconButton {
                            Layout.preferredWidth: 20
                            Layout.preferredHeight: 20
                            iconSize: 10
                            iconSource: FluentIcons.ChromeClose
                            onClicked: SerialSessions.closeSession(sessionTab.index)
                            FluTooltip { visible: parent.hovered; text: qsTr("关闭会话") }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        anchors.rightMargin: 26
                        acceptedButtons: Qt.LeftButton
                        onClicked: SerialSessions.activeIndex = sessionTab.index
                    }
                    HoverHandler { id: tabHover }
                }
            }

            FluIconButton {
                iconSource: FluentIcons.Add
                iconSize: 16
                onClicked: SerialSessions.createSession()
                FluTooltip { visible: parent.hovered; text: qsTr("新建会话") }
            }

            Item { Layout.fillWidth: true }
        }

        // ==================== 会话视图区 ====================
        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: SerialSessions.activeIndex

            Repeater {
                model: SerialSessions.sessions
                delegate: SerialCube_SerialSessionView {
                    required property var modelData
                    required property int index
                    session: modelData
                }
            }
        }

        // 空状态（所有会话都关闭时）
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: SerialSessions.sessions.length === 0
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 12
                FluIcon {
                    iconSource: FluentIcons.Connect
                    iconSize: 42
                    Layout.alignment: Qt.AlignHCenter
                    color: FluTheme.fontTertiaryColor
                }
                FluText {
                    text: qsTr("暂无串口会话")
                    color: FluTheme.fontSecondaryColor
                    Layout.alignment: Qt.AlignHCenter
                }
                FluFilledButton {
                    text: qsTr("新建会话")
                    Layout.alignment: Qt.AlignHCenter
                    onClicked: SerialSessions.createSession()
                }
            }
        }
    }
}
