import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import FluentUI 1.0
import "../Components"

/**
 * T_Protocol — 协议解析 + 卡片仪表盘
 * 复用串口调试页的活动会话连接（被动解析）；勾选轮询后按预设命令表主动发查询帧。
 * 引擎/业务全部在 ProtocolTool（Python），本页只做展示与交互。
 */
FluPage {
    id: protoPage
    launchMode: FluPageType.SingleTask
    animationEnabled: false
    padding: 0
    property var _route: ({})
    property var argument: ({})

    Component.onCompleted: {
        if (ProtocolTool.currentProfileName === "" && ProtocolTool.profileNames.length > 0)
            ProtocolTool.loadProfile(ProtocolTool.profileNames[0])
        refreshSessionCombo()
    }

    function refreshSessionCombo() {
        var names = []
        var sessions = SerialSessions.sessions
        for (var i = 0; i < sessions.length; i++)
            names.push(sessions[i].name)
        sessionCombo.model = names
        if (ProtocolTool.bound && sessionCombo.currentIndex < 0)
            sessionCombo.currentIndex = 0
    }

    function applyBinding() {
        if (sessionCombo.currentIndex >= 0)
            ProtocolTool.attach(sessionCombo.currentIndex)
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        anchors.topMargin: 0
        anchors.bottomMargin: 8
        spacing: 8

        // ==================== 顶部工具栏 ====================
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            spacing: 8

            FluText { text: qsTr("协议解析"); font: FluTextStyle.BodyStrong; Layout.leftMargin: 4 }
            Rectangle { Layout.preferredWidth: 1; Layout.preferredHeight: 20; color: FluTheme.dividerColor }

            FluText { text: qsTr("预设"); color: FluTheme.fontSecondaryColor }
            FluComboBox {
                id: profileCombo
                Layout.preferredWidth: 140
                model: ProtocolTool.profileNames
                onActivated: ProtocolTool.loadProfile(currentText)
                Connections {
                    target: ProtocolTool
                    function onCurrentProfileChanged() {
                        profileCombo.currentIndex = ProtocolTool.profileNames.indexOf(ProtocolTool.currentProfileName)
                    }
                }
            }

            Rectangle { Layout.preferredWidth: 1; Layout.preferredHeight: 20; color: FluTheme.dividerColor }

            FluText { text: qsTr("绑定会话"); color: FluTheme.fontSecondaryColor }
            FluComboBox {
                id: sessionCombo
                Layout.preferredWidth: 150
                onActivated: protoPage.applyBinding()
            }
            FluIconButton {
                iconSource: FluentIcons.Sync
                iconSize: 14
                onClicked: protoPage.refreshSessionCombo()
                FluTooltip { visible: parent.hovered; text: qsTr("刷新会话列表") }
            }

            FluToggleButton {
                text: ProtocolTool.polling ? qsTr("停止轮询") : qsTr("启动轮询")
                checked: ProtocolTool.polling
                onClicked: ProtocolTool.setPolling(!checked)
            }

            Item { Layout.fillWidth: true }
            Connections {
                target: SerialSessions
                function onSessionsChanged() { protoPage.refreshSessionCombo() }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // ==================== 左侧配置栏 ====================
            Flickable {
                id: leftFlick
                Layout.preferredWidth: 280
                Layout.fillHeight: true
                clip: true
                contentWidth: width
                contentHeight: leftCol.implicitHeight
                boundsBehavior: Flickable.StopAtBounds
                HoverHandler { id: leftHover }

                ColumnLayout {
                    id: leftCol
                    width: leftFlick.width
                    spacing: 12

                    // ---- 协议档案 ----
                    FluFrame {
                        Layout.fillWidth: true
                        Layout.preferredHeight: profCol.implicitHeight + 24
                        radius: 8
                        padding: 12
                        ColumnLayout {
                            id: profCol
                            anchors.fill: parent
                            spacing: 4
                            FluText { text: qsTr("协议档案"); font: FluTextStyle.BodyStrong }
                            FluText {
                                Layout.fillWidth: true
                                text: ProtocolTool.currentProfileName === ""
                                      ? qsTr("未加载预设") : ProtocolTool.currentProfileName
                                font: FluTextStyle.Caption
                                color: FluTheme.fontSecondaryColor
                                wrapMode: Text.WrapAnywhere
                            }
                            FluText {
                                Layout.fillWidth: true
                                text: ProtocolTool.offline ? qsTr("● 数据未刷新") : qsTr("● 数据刷新中")
                                font: FluTextStyle.Caption
                                color: ProtocolTool.offline ? FluTheme.fontTertiaryColor : FluColors.Green.normal
                            }
                        }
                    }

                    // ---- 轮询命令 ----
                    FluFrame {
                        Layout.fillWidth: true
                        Layout.preferredHeight: cmdCol.implicitHeight + 24
                        radius: 8
                        padding: 12
                        ColumnLayout {
                            id: cmdCol
                            anchors.fill: parent
                            spacing: 4
                            FluText { text: qsTr("轮询命令"); font: FluTextStyle.BodyStrong }
                            Repeater {
                                model: ProtocolTool.polling
                                delegate: FluText {
                                    text: modelData.name + " (" + modelData.cmd + ")"
                                    font: FluTextStyle.Caption
                                    color: FluTheme.fontSecondaryColor
                                }
                            }
                            FluText {
                                text: ProtocolTool.polling
                                      ? qsTr("按预设间隔顺序轮询中…")
                                      : qsTr("启动轮询后自动发查询帧")
                                font: FluTextStyle.Caption
                                color: FluTheme.fontTertiaryColor
                                wrapMode: Text.WrapAnywhere
                                Layout.fillWidth: true
                            }
                        }
                    }

                    // ---- 日志 ----
                    FluFrame {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 80
                        radius: 8
                        padding: 12
                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 4
                            FluText { text: qsTr("解析日志"); font: FluTextStyle.BodyStrong }
                            FluButton {
                                text: qsTr("清空日志")
                                onClicked: ProtocolTool.clearLog()
                            }
                        }
                    }
                }
                ScrollBar.vertical: FluScrollBar {
                    opacity: leftHover.hovered ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }
            }

            // ==================== 右侧：仪表盘 + 解析日志 ====================
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.leftMargin: 12
                spacing: 12

                // ---- 仪表盘 ----
                FluFrame {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 8
                    padding: 12
                    opacity: ProtocolTool.offline ? 0.55 : 1

                    Flickable {
                        anchors.fill: parent
                        contentWidth: width
                        contentHeight: dashGrid.implicitHeight + 8
                        boundsBehavior: Flickable.StopAtBounds
                        clip: true

                        GridLayout {
                            id: dashGrid
                            width: parent.width
                            columns: Math.max(2, Math.floor(width / 280))
                            columnSpacing: 12
                            rowSpacing: 12

                            Repeater {
                                model: ProtocolTool.cards
                                delegate: Loader {
                                    required property var modelData
                                    required property int index
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: modelData.card === "tiles" ? 180 : 84
                                    sourceComponent: {
                                        if (modelData.card === "progress") return progressComp
                                        if (modelData.card === "status") return statusComp
                                        if (modelData.card === "tiles") return tilesComp
                                        if (modelData.card === "text") return textComp
                                        return numberComp
                                    }
                                    property var cardData: modelData

                                    Component {
                                        id: numberComp
                                        SerialCube_DashNumber {
                                            title: cardData.title
                                            unit: cardData.unit
                                            value: {
                                                var v = ProtocolTool.values[cardData.key]
                                                return v ? v.value : null
                                            }
                                        }
                                    }
                                    Component {
                                        id: progressComp
                                        SerialCube_DashProgress {
                                            title: cardData.title
                                            value: {
                                                var v = ProtocolTool.values[cardData.key]
                                                return v ? v.value : null
                                            }
                                        }
                                    }
                                    Component {
                                        id: statusComp
                                        SerialCube_DashStatus {
                                            title: cardData.title
                                            bits: cardData.bits
                                            mask: {
                                                var v = ProtocolTool.values[cardData.key]
                                                return v ? v.mask : 0
                                            }
                                        }
                                    }
                                    Component {
                                        id: tilesComp
                                        SerialCube_DashTiles {
                                            title: cardData.title
                                            unit: cardData.unit
                                            extremes: cardData.extremes
                                            values: {
                                                var v = ProtocolTool.values[cardData.key]
                                                return v ? v.values : []
                                            }
                                        }
                                    }
                                    Component {
                                        id: textComp
                                        SerialCube_DashNumber {
                                            title: cardData.title
                                            value: {
                                                var v = ProtocolTool.values[cardData.key]
                                                return v ? v.value : null
                                            }
                                        }
                                    }
                                }
                            }

                            // 空状态
                            FluText {
                                anchors.centerIn: parent
                                visible: ProtocolTool.cards.length === 0
                                text: qsTr("选择预设后此处生成仪表盘卡片")
                                color: FluTheme.fontTertiaryColor
                            }
                        }
                    }
                }

                // ---- 解析日志 ----
                FluFrame {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 150
                    radius: 8
                    padding: 12
                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 4
                        Flickable {
                            id: logFlick
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            contentWidth: width
                            contentHeight: parseLogText.implicitHeight + 8
                            boundsBehavior: Flickable.StopAtBounds
                            property bool stickBottom: true
                            onContentHeightChanged: {
                                if (stickBottom) contentY = Math.max(0, contentHeight - height)
                            }
                            onDragEnded: stickBottom = (contentY + height >= contentHeight - 30)
                            FluText {
                                id: parseLogText
                                width: logFlick.width - 8
                                text: ProtocolTool.parseLogText
                                font.family: "Consolas"
                                font.pixelSize: FluTextStyle.Caption.pixelSize
                                wrapMode: Text.WrapAnywhere
                                color: FluTheme.fontPrimaryColor
                            }
                            ScrollBar.vertical: FluScrollBar { }
                        }
                    }
                }
            }
        }
    }
}
