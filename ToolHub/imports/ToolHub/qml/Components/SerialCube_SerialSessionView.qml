import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import FluentUI 1.0

/**
 * SerialCube_SerialSessionView
 * ---------------------------
 * 单个串口会话的完整视图：左设置面板（可折叠）+ 数据区 + 发送区 + 底部状态栏。
 * 所有业务绑定 session.worker / session.log（Python），本组件只做展示与交互。
 */
Item {
    id: sessionView

    property var session: null
    readonly property var worker: session ? session.worker : null
    readonly property var log: session ? session.log : null

    // 发送历史（最多 10 条，随会话保存在视图实例内）
    property var sendHistory: []
    property int logFontPx: FluTextStyle.Body.pixelSize
    readonly property int defaultLogFontPx: FluTextStyle.Body.pixelSize

    Component.onCompleted: {
        sessionView.applyThemeColors()
        refreshPorts()
    }

    function applyThemeColors() {
        if (!session) return
        // RX 绿 / TX 蓝：颜色由主题注入 Python，数据内容保持前景色
        session.log.rxColor = FluColors.Green.normal.toString()
        session.log.txColor = FluTheme.primaryColor.toString()
    }

    Connections {
        target: FluTheme
        function onPrimaryColorChanged() { sessionView.applyThemeColors() }
    }

    function fmtBytes(n) {
        if (n >= 1048576) return (n / 1048576).toFixed(2) + " MB"
        if (n >= 1024) return (n / 1024).toFixed(1) + " KB"
        return n + " B"
    }

    function refreshPorts() {
        portCombo.model = worker.list_ports()
        if (portCombo.model.length > 0 && portCombo.currentIndex < 0)
            portCombo.currentIndex = 0
    }

    function currentDevice() {
        var t = portCombo.editText.length > 0 ? portCombo.editText : portCombo.currentText
        return t.split(" — ")[0].trim()
    }

    function doSend() {
        var text = sendInput.text
        if (text.length === 0 || !worker.opened) return
        worker.localEcho = echoSwitch.checked
        worker.send(text, hexSwitch.checked, eolCombo.currentIndex)
        var idx = sendHistory.indexOf(text)
        if (idx !== -1) sendHistory.splice(idx, 1)
        sendHistory.unshift(text)
        if (sendHistory.length > 10) sendHistory.length = 10
        historyCombo.model = sendHistory
    }


    RowLayout {
        anchors.fill: parent
        spacing: 0

        // ==================== 左侧设置面板（可折叠） ====================
        Item {
            id: panelShell
            Layout.preferredWidth: session.panelCollapsed ? 0 : 280
            Layout.maximumWidth: session.panelCollapsed ? 0 : 280
            Layout.fillHeight: true
            clip: true

            Behavior on Layout.preferredWidth {
                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
            }

            Flickable {
                id: leftFlick
                anchors.fill: parent
                clip: true
                contentWidth: width
                contentHeight: leftCol.implicitHeight
                boundsBehavior: Flickable.StopAtBounds
                HoverHandler { id: panelHover }

                ColumnLayout {
                    id: leftCol
                    width: leftFlick.width
                    spacing: 12

                    // ---- 连接设置 ----
                    FluFrame {
                        Layout.fillWidth: true
                        Layout.preferredHeight: connCol.implicitHeight + 24
                        radius: 8
                        padding: 12
                        ColumnLayout {
                            id: connCol
                            anchors.fill: parent
                            spacing: 0
                            FluText {
                                text: qsTr("连接设置")
                                font: FluTextStyle.BodyStrong
                                Layout.bottomMargin: 4
                            }
                            SerialCube_SettingsRow {
                                label: qsTr("串口")
                                mode: "narrow"
                                Layout.fillWidth: true
                                Layout.preferredHeight: 40
                                RowLayout {
                                    width: parent.width
                                    spacing: 4
                                    FluComboBox {
                                        id: portCombo
                                        Layout.fillWidth: true
                                    }
                                    FluIconButton {
                                        iconSource: FluentIcons.Sync
                                        iconSize: 14
                                        onClicked: sessionView.refreshPorts()
                                        FluTooltip { visible: parent.hovered; text: qsTr("刷新端口列表") }
                                    }
                                }
                            }
                            SerialCube_SettingsRow {
                                label: qsTr("波特率")
                                mode: "narrow"
                                Layout.fillWidth: true
                                Layout.preferredHeight: 40
                                FluComboBox {
                                    id: baudCombo
                                    width: parent.width
                                    editable: true
                                    model: [9600, 19200, 38400, 57600, 115200, 230400, 460800, 921600]
                                    currentIndex: 4
                                }
                            }
                            SerialCube_SettingsRow {
                                label: qsTr("数据位")
                                mode: "narrow"
                                Layout.fillWidth: true
                                Layout.preferredHeight: 40
                                FluComboBox { id: dataBitsCombo; width: parent.width; model: [8, 7, 6, 5] }
                            }
                            SerialCube_SettingsRow {
                                label: qsTr("校验位")
                                mode: "narrow"
                                Layout.fillWidth: true
                                Layout.preferredHeight: 40
                                FluComboBox { id: parityCombo; width: parent.width; model: ["None", "Even", "Odd", "Mark", "Space"] }
                            }
                            SerialCube_SettingsRow {
                                label: qsTr("停止位")
                                mode: "narrow"
                                Layout.fillWidth: true
                                Layout.preferredHeight: 40
                                FluComboBox { id: stopBitsCombo; width: parent.width; model: [1, 1.5, 2] }
                            }
                            SerialCube_SettingsRow {
                                label: qsTr("流控")
                                mode: "narrow"
                                Layout.fillWidth: true
                                Layout.preferredHeight: 40
                                FluComboBox { id: flowCombo; width: parent.width; model: ["None", "RTS/CTS", "XON/XOFF"] }
                            }
                            FluFilledButton {
                                Layout.fillWidth: true
                                Layout.margins: 8
                                text: worker.opened ? qsTr("关闭串口") : qsTr("打开串口")
                                onClicked: {
                                    if (worker.opened) {
                                        worker.close_port()
                                    } else {
                                        var dev = sessionView.currentDevice()
                                        if (!dev) {
                                            showError(qsTr("未选择串口"))
                                            return
                                        }
                                        worker.set_params(
                                            dev,
                                            parseInt(baudCombo.editText) || 115200,
                                            parseInt(dataBitsCombo.currentText) || 8,
                                            parityCombo.currentText,
                                            parseFloat(stopBitsCombo.currentText) || 1,
                                            flowCombo.currentText)
                                        worker.open_port()
                                    }
                                }
                            }
                        }
                    }

                    // ---- 数据区设置 ----
                    FluFrame {
                        Layout.fillWidth: true
                        Layout.preferredHeight: dataCol.implicitHeight + 24
                        radius: 8
                        padding: 12
                        ColumnLayout {
                            id: dataCol
                            anchors.fill: parent
                            spacing: 0
                            FluText {
                                text: qsTr("数据区")
                                font: FluTextStyle.BodyStrong
                                Layout.bottomMargin: 4
                            }
                            SerialCube_SettingsRow {
                                label: qsTr("显示方式")
                                mode: "narrow"
                                Layout.fillWidth: true
                                Layout.preferredHeight: 40
                                FluComboBox {
                                    id: viewModeCombo
                                    width: parent.width
                                    model: [qsTr("文本"), "HEX"]
                                    onActivated: sessionView.log.hexView = (currentIndex === 1)
                                }
                            }
                            SerialCube_SettingsRow {
                                label: qsTr("字符编码")
                                mode: "narrow"
                                Layout.fillWidth: true
                                Layout.preferredHeight: 40
                                FluComboBox {
                                    id: encCombo
                                    width: parent.width
                                    model: [qsTr("自动"), "UTF-8", "GBK"]
                                    onActivated: sessionView.log.encoding = ["auto", "utf-8", "gbk"][currentIndex]
                                }
                            }
                            SerialCube_SettingsRow {
                                label: qsTr("自动换行")
                                mode: "narrow"
                                Layout.fillWidth: true
                                Layout.preferredHeight: 40
                                FluToggleSwitch {
                                    checked: true
                                    onToggled: sessionView.log.autoWrap = checked
                                }
                            }
                            SerialCube_SettingsRow {
                                label: qsTr("时间戳")
                                mode: "narrow"
                                Layout.fillWidth: true
                                Layout.preferredHeight: 40
                                RowLayout {
                                    width: parent.width
                                    spacing: 8
                                    FluToggleSwitch {
                                        id: tsSwitch
                                        checked: true
                                        Layout.preferredWidth: 40
                                        onToggled: sessionView.log.timestampMode = checked ? tsModeCombo.currentIndex + 1 : 0
                                    }
                                    FluComboBox {
                                        id: tsModeCombo
                                        Layout.fillWidth: true
                                        enabled: tsSwitch.checked
                                        model: [qsTr("时间"), qsTr("日期时间")]
                                        onActivated: if (tsSwitch.checked) sessionView.log.timestampMode = currentIndex + 1
                                    }
                                }
                            }
                            SerialCube_SettingsRow {
                                label: qsTr("时间分包")
                                mode: "narrow"
                                Layout.fillWidth: true
                                Layout.preferredHeight: 40
                                RowLayout {
                                    width: parent.width
                                    spacing: 8
                                    FluToggleSwitch {
                                        id: packetSwitch
                                        checked: true
                                        Layout.preferredWidth: 40
                                        onToggled: sessionView.log.timePacketMs = checked ? (parseInt(packetMsBox.text) || 0) : 0
                                    }
                                    FluTextBox {
                                        id: packetMsBox
                                        Layout.preferredWidth: 56
                                        Layout.fillWidth: true
                                        enabled: packetSwitch.checked
                                        text: "20"
                                        onTextChanged: if (packetSwitch.checked) sessionView.log.timePacketMs = parseInt(text) || 0
                                    }
                                    FluText { text: "ms"; font: FluTextStyle.Caption; color: FluTheme.fontSecondaryColor }
                                }
                            }
                            SerialCube_SettingsRow {
                                label: qsTr("最大行数")
                                mode: "narrow"
                                Layout.fillWidth: true
                                Layout.preferredHeight: 40
                                FluTextBox {
                                    width: parent.width
                                    text: "10000"
                                    onTextChanged: sessionView.log.maxLines = parseInt(text) || 10000
                                }
                            }
                            SerialCube_SettingsRow {
                                label: qsTr("冻结显示")
                                mode: "narrow"
                                Layout.fillWidth: true
                                Layout.preferredHeight: 40
                                FluToggleSwitch {
                                    onToggled: sessionView.log.frozen = checked
                                }
                            }
                            RowLayout {
                                Layout.fillWidth: true
                                Layout.margins: 8
                                spacing: 8
                                FluButton {
                                    Layout.fillWidth: true
                                    text: qsTr("保存")
                                    onClicked: {
                                        sessionView.log.save("")
                                        showSuccess(qsTr("日志已保存到 Downloads 目录"))
                                    }
                                }
                                FluButton {
                                    Layout.fillWidth: true
                                    text: qsTr("清空")
                                    onClicked: sessionView.log.clear()
                                }
                            }
                        }
                    }

                    // ---- 发送区设置 ----
                    FluFrame {
                        Layout.fillWidth: true
                        Layout.preferredHeight: sendCol.implicitHeight + 24
                        radius: 8
                        padding: 12
                        ColumnLayout {
                            id: sendCol
                            anchors.fill: parent
                            spacing: 0
                            FluText {
                                text: qsTr("发送区")
                                font: FluTextStyle.BodyStrong
                                Layout.bottomMargin: 4
                            }
                            SerialCube_SettingsRow {
                                label: "HEX " + qsTr("发送")
                                mode: "narrow"
                                Layout.fillWidth: true
                                Layout.preferredHeight: 40
                                FluToggleSwitch { id: hexSwitch }
                            }
                            SerialCube_SettingsRow {
                                label: qsTr("追加换行")
                                mode: "narrow"
                                Layout.fillWidth: true
                                Layout.preferredHeight: 40
                                FluComboBox {
                                    id: eolCombo
                                    width: parent.width
                                    model: [qsTr("无"), "CR", "LF", "CRLF"]
                                }
                            }
                            SerialCube_SettingsRow {
                                label: qsTr("定时发送")
                                mode: "narrow"
                                Layout.fillWidth: true
                                Layout.preferredHeight: 40
                                RowLayout {
                                    width: parent.width
                                    spacing: 8
                                    FluToggleSwitch {
                                        id: timedSwitch
                                        Layout.preferredWidth: 40
                                    }
                                    FluTextBox {
                                        id: timedMsBox
                                        Layout.preferredWidth: 56
                                        Layout.fillWidth: true
                                        enabled: timedSwitch.checked
                                        text: "1000"
                                    }
                                    FluText { text: "ms"; font: FluTextStyle.Caption; color: FluTheme.fontSecondaryColor }
                                }
                            }
                            SerialCube_SettingsRow {
                                label: qsTr("本地回显")
                                mode: "narrow"
                                Layout.fillWidth: true
                                Layout.preferredHeight: 40
                                FluToggleSwitch { id: echoSwitch }
                            }
                        }
                    }
                }

                ScrollBar.vertical: FluScrollBar {
                    opacity: panelHover.hovered ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }
            }
        }

        // ==================== 右侧：数据区 + 发送区 ====================
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.leftMargin: session.panelCollapsed ? 8 : 12
            spacing: 12

            // ---- 数据区 ----
            FluFrame {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 8
                padding: 12
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 8

                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 30
                        RowLayout {
                            anchors.fill: parent
                            spacing: 12
                            FluText { text: qsTr("数据区"); font: FluTextStyle.BodyStrong }
                            FluText { text: "← " + qsTr("收"); font: FluTextStyle.Body; color: FluColors.Green.normal }
                            FluText { text: "→ " + qsTr("发"); font: FluTextStyle.Body; color: FluTheme.primaryColor }
                            Item { Layout.fillWidth: true }
                            FluButton {
                                text: "A-"
                                onClicked: sessionView.logFontPx = Math.max(sessionView.logFontPx - 1, 10)
                            }
                            FluButton {
                                text: "A+"
                                onClicked: sessionView.logFontPx = Math.min(sessionView.logFontPx + 1, 28)
                            }
                        }
                    }

                    Flickable {
                        id: logFlick
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        contentWidth: width
                        contentHeight: logTextItem.implicitHeight + 16
                        boundsBehavior: Flickable.StopAtBounds
                        property bool stickBottom: true
                        onContentHeightChanged: {
                            if (stickBottom) contentY = Math.max(0, contentHeight - height)
                        }
                        onDragEnded: stickBottom = (contentY + height >= contentHeight - 40)

                        FluText {
                            id: logTextItem
                            width: logFlick.width - 12
                            x: 4
                            y: 8
                            text: sessionView.log.logText
                            font.family: "Consolas"
                            font.pixelSize: sessionView.logFontPx
                            wrapMode: Text.WrapAnywhere
                            color: FluTheme.fontPrimaryColor
                            textFormat: Text.PlainText
                        }
                        ScrollBar.vertical: FluScrollBar { }

                        FluText {
                            anchors.centerIn: parent
                            visible: sessionView.log.logText === ""
                            text: qsTr("暂无数据 · 打开串口后收发内容将显示在这里")
                            color: FluTheme.fontTertiaryColor
                            font: FluTextStyle.Body
                        }
                    }
                }
            }

            // ---- 发送区 ----
            FluFrame {
                Layout.fillWidth: true
                Layout.preferredHeight: 170
                radius: 8
                padding: 12
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 8

                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 30
                        RowLayout {
                            anchors.fill: parent
                            spacing: 4
                            FluText { text: qsTr("发送区"); font: FluTextStyle.BodyStrong }
                            Item { Layout.preferredWidth: 8 }
                            FluIcon {
                                visible: timedSwitch.checked
                                iconSource: FluentIcons.Sync
                                iconSize: 14
                                color: FluTheme.primaryColor
                            }
                            FluText {
                                visible: timedSwitch.checked
                                text: qsTr("每 %1ms 循环发送").arg(timedMsBox.text)
                                font: FluTextStyle.Caption
                                color: FluTheme.primaryColor
                            }
                            Item { Layout.fillWidth: true }
                        }
                    }

                    FluMultilineTextBox {
                        id: sendInput
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        placeholderText: worker.opened ? qsTr("输入要发送的内容（HEX 模式输入如 5A 01 02）") : qsTr("打开串口后可发送数据")
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        FluComboBox {
                            id: historyCombo
                            Layout.preferredWidth: 160
                            enabled: count > 0
                            displayText: qsTr("历史")
                            onActivated: {
                                sendInput.text = currentText
                                currentIndex = -1
                            }
                        }
                        FluButton {
                            text: qsTr("清空")
                            onClicked: sendInput.text = ""
                        }
                        Item { Layout.fillWidth: true }
                        FluFilledButton {
                            Layout.minimumWidth: 110
                            text: qsTr("发 送")
                            enabled: worker.opened
                            onClicked: sessionView.doSend()
                        }
                    }
                }
            }

            // ---- 底部状态栏（本会话） ----
            RowLayout {
                Layout.fillWidth: true
                spacing: 16
                Rectangle {
                    Layout.preferredWidth: 8
                    Layout.preferredHeight: 8
                    radius: 4
                    color: worker.opened ? FluColors.Green.normal : FluColors.Red.normal
                }
                FluText {
                    font: FluTextStyle.Caption
                    color: worker.opened ? FluTheme.fontPrimaryColor : FluTheme.fontSecondaryColor
                    text: worker.opened ? qsTr("已连接 %1").arg(worker.portName) : qsTr("未连接")
                }
                FluText {
                    font: FluTextStyle.Caption
                    color: FluTheme.fontSecondaryColor
                    text: "RX " + sessionView.fmtBytes(log.rxBytes) + " · " + log.rxPackets + qsTr(" 包 · ") + sessionView.fmtBytes(log.rxRate) + "/s"
                }
                FluText {
                    font: FluTextStyle.Caption
                    color: FluTheme.fontSecondaryColor
                    text: "TX " + sessionView.fmtBytes(log.txBytes) + " · " + log.txPackets + qsTr(" 包 · ") + sessionView.fmtBytes(log.txRate) + "/s"
                }
                Item { Layout.fillWidth: true }
            }
        }
    }

    // 折叠/展开箭头：悬浮在面板右缘（折叠后贴左缘），不占布局槽
    FluIconButton {
        z: 10
        x: session.panelCollapsed ? 0 : panelShell.width - 14
        anchors.verticalCenter: parent.verticalCenter
        iconSource: session.panelCollapsed ? FluentIcons.ChevronRight : FluentIcons.ChevronLeft
        iconSize: 14
        onClicked: session.panelCollapsed = !session.panelCollapsed
        FluTooltip { visible: parent.hovered; text: qsTr("折叠/展开设置面板") }
    }

    Connections {
        target: worker
        function onErrorOccurred(message) {
            showError(qsTr("串口错误"), message)
        }
    }

    Timer {
        id: sendTimer
        repeat: true
        running: timedSwitch.checked && worker.opened && sendInput.text.length > 0
        interval: Math.max(parseInt(timedMsBox.text) || 1000, 10)
        onTriggered: sessionView.doSend()
    }
}
