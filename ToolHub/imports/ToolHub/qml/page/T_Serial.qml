import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import FluentUI 1.0
import "../Components"

/**
 * T_Serial — 串口调试
 * 布局参考 VOFA+/SerialTool：左侧参数设置栏 + 右侧数据区/发送区 + 底部状态栏。
 * 业务全部在 SerialWorker/SerialLog（Python），本文件只做展示与交互。
 */
FluPage {
    id: serialPage
    launchMode: FluPageType.SingleTask
    animationEnabled: false
    padding: 0
    property var _route: ({})
    property var argument: ({})

    // 发送历史（最多 10 条）
    property var sendHistory: []
    // 日志字号（A-/A+ 调节）
    property int logFontPx: FluTextStyle.Body.pixelSize

    function fmtBytes(n) {
        if (n >= 1048576) return (n / 1048576).toFixed(2) + " MB"
        if (n >= 1024) return (n / 1024).toFixed(1) + " KB"
        return n + " B"
    }

    function refreshPorts() {
        portCombo.model = SerialWorker.list_ports()
        if (portCombo.model.length > 0 && portCombo.currentIndex < 0)
            portCombo.currentIndex = 0
    }

    function currentDevice() {
        var t = portCombo.editText.length > 0 ? portCombo.editText : portCombo.currentText
        return t.split(" — ")[0].trim()
    }

    function doSend() {
        var text = sendInput.text
        if (text.length === 0 || !SerialWorker.opened) return
        SerialWorker.localEcho = echoSwitch.checked
        SerialWorker.send(text, hexSwitch.checked, eolCombo.currentIndex)
        var idx = sendHistory.indexOf(text)
        if (idx !== -1) sendHistory.splice(idx, 1)
        sendHistory.unshift(text)
        if (sendHistory.length > 10) sendHistory.length = 10
        historyCombo.model = sendHistory
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 12

        SerialCube_PageHeader {
            title: qsTr("串口调试")
            subtitle: qsTr("Serial Debug · 串口数据收发 · HEX/文本 · 日志打印")
            iconSource: FluentIcons.Connect
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12

            // ==================== 左侧设置栏（可滚动） ====================
            Flickable {
                id: leftFlick
                Layout.preferredWidth: 280
                Layout.fillHeight: true
                clip: true
                contentWidth: width
                contentHeight: leftCol.implicitHeight
                boundsBehavior: Flickable.StopAtBounds

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
                                Layout.fillWidth: true
                                Layout.preferredHeight: 40
                                RowLayout {
                                    width: 200
                                    spacing: 4
                                    FluComboBox {
                                        id: portCombo
                                        Layout.fillWidth: true
                                    }
                                    FluIconButton {
                                        iconSource: FluentIcons.Sync
                                        iconSize: 14
                                        onClicked: serialPage.refreshPorts()
                                        FluTooltip { visible: parent.hovered; text: qsTr("刷新端口列表") }
                                    }
                                }
                            }
                            SerialCube_SettingsRow {
                                label: qsTr("波特率")
                                Layout.fillWidth: true
                                Layout.preferredHeight: 40
                                FluComboBox {
                                    id: baudCombo
                                    width: 200
                                    editable: true
                                    model: [9600, 19200, 38400, 57600, 115200, 230400, 460800, 921600]
                                    currentIndex: 4
                                }
                            }
                            SerialCube_SettingsRow {
                                label: qsTr("数据位")
                                Layout.fillWidth: true
                                Layout.preferredHeight: 40
                                FluComboBox { id: dataBitsCombo; width: 200; model: [8, 7, 6, 5] }
                            }
                            SerialCube_SettingsRow {
                                label: qsTr("校验位")
                                Layout.fillWidth: true
                                Layout.preferredHeight: 40
                                FluComboBox { id: parityCombo; width: 200; model: ["None", "Even", "Odd", "Mark", "Space"] }
                            }
                            SerialCube_SettingsRow {
                                label: qsTr("停止位")
                                Layout.fillWidth: true
                                Layout.preferredHeight: 40
                                FluComboBox { id: stopBitsCombo; width: 200; model: [1, 1.5, 2] }
                            }
                            SerialCube_SettingsRow {
                                label: qsTr("流控")
                                Layout.fillWidth: true
                                Layout.preferredHeight: 40
                                FluComboBox { id: flowCombo; width: 200; model: ["None", "RTS/CTS", "XON/XOFF"] }
                            }
                            FluFilledButton {
                                Layout.fillWidth: true
                                Layout.margins: 8
                                text: SerialWorker.opened ? qsTr("关闭串口") : qsTr("打开串口")
                                onClicked: {
                                    if (SerialWorker.opened) {
                                        SerialWorker.close_port()
                                    } else {
                                        var dev = serialPage.currentDevice()
                                        if (!dev) {
                                            showError(qsTr("未选择串口"))
                                            return
                                        }
                                        SerialWorker.set_params(
                                            dev,
                                            parseInt(baudCombo.editText) || 115200,
                                            parseInt(dataBitsCombo.currentText) || 8,
                                            parityCombo.currentText,
                                            parseFloat(stopBitsCombo.currentText) || 1,
                                            flowCombo.currentText)
                                        SerialWorker.open_port()
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
                                Layout.fillWidth: true
                                Layout.preferredHeight: 40
                                FluComboBox {
                                    width: 200
                                    model: [qsTr("文本"), "HEX"]
                                    onActivated: SerialLog.hexView = (currentIndex === 1)
                                }
                            }
                            SerialCube_SettingsRow {
                                label: qsTr("字符编码")
                                Layout.fillWidth: true
                                Layout.preferredHeight: 40
                                FluComboBox {
                                    width: 200
                                    model: [qsTr("自动"), "UTF-8", "GBK"]
                                    onActivated: SerialLog.encoding = ["auto", "utf-8", "gbk"][currentIndex]
                                }
                            }
                            SerialCube_SettingsRow {
                                label: qsTr("自动换行")
                                Layout.fillWidth: true
                                Layout.preferredHeight: 40
                                FluToggleSwitch {
                                    checked: true
                                    onToggled: SerialLog.autoWrap = checked
                                }
                            }
                            SerialCube_SettingsRow {
                                label: qsTr("显示时间戳")
                                Layout.fillWidth: true
                                Layout.preferredHeight: 40
                                RowLayout {
                                    width: 200
                                    spacing: 8
                                    FluToggleSwitch {
                                        id: tsSwitch
                                        checked: true
                                        onToggled: SerialLog.timestampMode = checked ? tsModeCombo.currentIndex + 1 : 0
                                    }
                                    FluComboBox {
                                        id: tsModeCombo
                                        Layout.fillWidth: true
                                        enabled: tsSwitch.checked
                                        model: [qsTr("时间"), qsTr("日期时间")]
                                        onActivated: if (tsSwitch.checked) SerialLog.timestampMode = currentIndex + 1
                                    }
                                }
                            }
                            SerialCube_SettingsRow {
                                label: qsTr("时间分包")
                                Layout.fillWidth: true
                                Layout.preferredHeight: 40
                                RowLayout {
                                    width: 200
                                    spacing: 8
                                    FluToggleSwitch {
                                        id: packetSwitch
                                        checked: true
                                        onToggled: SerialLog.timePacketMs = checked ? (parseInt(packetMsBox.text) || 0) : 0
                                    }
                                    FluTextBox {
                                        id: packetMsBox
                                        Layout.preferredWidth: 60
                                        enabled: packetSwitch.checked
                                        text: "20"
                                        onTextChanged: if (packetSwitch.checked) SerialLog.timePacketMs = parseInt(text) || 0
                                    }
                                    FluText { text: "ms"; font: FluTextStyle.Caption; color: FluTheme.fontSecondaryColor }
                                }
                            }
                            SerialCube_SettingsRow {
                                label: qsTr("最大行数")
                                Layout.fillWidth: true
                                Layout.preferredHeight: 40
                                FluTextBox {
                                    width: 200
                                    text: "10000"
                                    onTextChanged: SerialLog.maxLines = parseInt(text) || 10000
                                }
                            }
                            SerialCube_SettingsRow {
                                label: qsTr("冻结显示")
                                Layout.fillWidth: true
                                Layout.preferredHeight: 40
                                FluToggleSwitch {
                                    onToggled: SerialLog.frozen = checked
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
                                        SerialLog.save("")
                                        showSuccess(qsTr("日志已保存到 Downloads 目录"))
                                    }
                                }
                                FluButton {
                                    Layout.fillWidth: true
                                    text: qsTr("清空")
                                    onClicked: SerialLog.clear()
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
                                Layout.fillWidth: true
                                Layout.preferredHeight: 40
                                FluToggleSwitch { id: hexSwitch }
                            }
                            SerialCube_SettingsRow {
                                label: qsTr("追加换行")
                                Layout.fillWidth: true
                                Layout.preferredHeight: 40
                                FluComboBox {
                                    id: eolCombo
                                    width: 200
                                    model: [qsTr("无"), "CR", "LF", "CRLF"]
                                }
                            }
                            SerialCube_SettingsRow {
                                label: qsTr("定时发送")
                                Layout.fillWidth: true
                                Layout.preferredHeight: 40
                                RowLayout {
                                    width: 200
                                    spacing: 8
                                    FluToggleSwitch { id: timedSwitch }
                                    FluTextBox {
                                        id: timedMsBox
                                        Layout.preferredWidth: 60
                                        enabled: timedSwitch.checked
                                        text: "1000"
                                    }
                                    FluText { text: "ms"; font: FluTextStyle.Caption; color: FluTheme.fontSecondaryColor }
                                }
                            }
                            SerialCube_SettingsRow {
                                label: qsTr("本地回显")
                                Layout.fillWidth: true
                                Layout.preferredHeight: 40
                                FluToggleSwitch { id: echoSwitch }
                            }
                        }
                    }
                }
                ScrollBar.vertical: FluScrollBar { }
            }

            // ==================== 右侧：数据区 + 发送区 ====================
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
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
                                    onClicked: serialPage.logFontPx = Math.max(serialPage.logFontPx - 1, 10)
                                }
                                FluButton {
                                    text: "A+"
                                    onClicked: serialPage.logFontPx = Math.min(serialPage.logFontPx + 1, 28)
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
                                text: SerialLog.logText
                                font.family: "Consolas"
                                font.pixelSize: serialPage.logFontPx
                                wrapMode: Text.WrapAnywhere
                                color: FluTheme.fontPrimaryColor
                                textFormat: Text.PlainText
                            }
                            ScrollBar.vertical: FluScrollBar { }

                            FluText {
                                anchors.centerIn: parent
                                visible: SerialLog.logText === ""
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
                            placeholderText: SerialWorker.opened ? qsTr("输入要发送的内容（HEX 模式输入如 5A 01 02）") : qsTr("打开串口后可发送数据")
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
                                enabled: SerialWorker.opened
                                onClicked: serialPage.doSend()
                            }
                        }
                    }
                }
            }
        }

        // ==================== 底部状态栏 ====================
        RowLayout {
            Layout.fillWidth: true
            spacing: 16
            Rectangle {
                Layout.preferredWidth: 8
                Layout.preferredHeight: 8
                radius: 4
                color: SerialWorker.opened ? FluColors.Green.normal : FluColors.Red.normal
            }
            FluText {
                font: FluTextStyle.Caption
                color: SerialWorker.opened ? FluTheme.fontPrimaryColor : FluTheme.fontSecondaryColor
                text: SerialWorker.opened ? qsTr("已连接 %1").arg(serialPage.currentDevice()) : qsTr("未连接")
            }
            FluText {
                font: FluTextStyle.Caption
                color: FluTheme.fontSecondaryColor
                text: "RX " + serialPage.fmtBytes(SerialLog.rxBytes) + " · " + SerialLog.rxPackets + qsTr(" 包 · ") + serialPage.fmtBytes(SerialLog.rxRate) + "/s"
            }
            FluText {
                font: FluTextStyle.Caption
                color: FluTheme.fontSecondaryColor
                text: "TX " + serialPage.fmtBytes(SerialLog.txBytes) + " · " + SerialLog.txPackets + qsTr(" 包 · ") + serialPage.fmtBytes(SerialLog.txRate) + "/s"
            }
            Item { Layout.fillWidth: true }
        }
    }

    Connections {
        target: SerialWorker
        function onOpenedChanged() {
            if (SerialWorker.opened)
                showSuccess(qsTr("串口已打开 %1").arg(serialPage.currentDevice()))
        }
        function onErrorOccurred(message) {
            showError(qsTr("串口错误"), message)
        }
    }

    Timer {
        id: sendTimer
        repeat: true
        running: timedSwitch.checked && SerialWorker.opened && sendInput.text.length > 0
        interval: Math.max(parseInt(timedMsBox.text) || 1000, 10)
        onTriggered: serialPage.doSend()
    }

    Component.onCompleted: serialPage.refreshPorts()
}
