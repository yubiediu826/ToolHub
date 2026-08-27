import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import FluentUI 1.0
import "../Components"
import "../global"   // 2026-08-26: 拿 Settings singleton (用于导航视图模式配置)

FluScrollablePage {
    id: settingsPage
    launchMode: FluPageType.SingleTask
    animationEnabled: false
    property var _route: ({})
    property var argument: ({})
    header: Item {}

    FluText {
        Layout.topMargin: 20
        Layout.leftMargin: 20
        text: qsTr("设置")
        font: FluTextStyle.Title
    }

    // 通用
    FluText {
        Layout.topMargin: 30
        Layout.leftMargin: 20
        text: qsTr("通用")
        font: FluTextStyle.BodyStrong
        opacity: 0.6
    }

    SerialCube_SettingsRow {
        label: qsTr("主题")
        Layout.fillWidth: true
        Layout.leftMargin: 20
        Layout.rightMargin: 20
        FluComboBox {
            model: [qsTr("跟随系统"), qsTr("浅色"), qsTr("深色")]
            currentIndex: FluTheme.dark ? 2 : 1
            onCurrentIndexChanged: {
                if (currentIndex === 0) {
                    // follow system - 简化：维持现状
                } else if (currentIndex === 1) {
                    FluTheme.darkMode = false
                } else {
                    FluTheme.darkMode = true
                }
            }
        }
    }

    SerialCube_SettingsRow {
        label: qsTr("语言")
        Layout.fillWidth: true
        Layout.leftMargin: 20
        Layout.rightMargin: 20
        FluText { text: qsTr("简体中文") }
    }

    // 2026-08-26: 导航视图模式可配置(决策 .workflow/decisions/2026-08-26_nav-mode-config.md)
    // 三选一:紧凑(0/Compact,固定折叠) / 开放(1/Open,固定展开) / 自动(2/业务态,默认折叠+点展开+重复点折叠)
    SerialCube_SettingsRow {
        label: qsTr("导航视图")
        Layout.fillWidth: true
        Layout.leftMargin: 20
        Layout.rightMargin: 20
        FluRadioButtons {
            id: navModeGroup
            currentIndex: Settings.navMode
            onCurrentIndexChanged: Settings.setNavMode(currentIndex)
            FluRadioButton { text: qsTr("紧凑") }      // index 0
            FluRadioButton { text: qsTr("开放") }      // index 1
            FluRadioButton { text: qsTr("自动") }      // index 2
        }
    }

    // 自动模式说明(仅当 navMode===2 时显示,避免其他模式噪音)
    FluText {
        Layout.topMargin: 4
        Layout.leftMargin: 20
        Layout.rightMargin: 20
        Layout.fillWidth: true
        text: qsTr("自动:默认折叠,点图标展开,再次点同一图标折叠")
        font: FluTextStyle.Caption
        opacity: 0.6
        wrapMode: Text.WordWrap
        visible: Settings.navMode === 2
    }

    // 启动
    FluText {
        Layout.topMargin: 30
        Layout.leftMargin: 20
        text: qsTr("启动")
        font: FluTextStyle.BodyStrong
        opacity: 0.6
    }

    SerialCube_SettingsRow {
        label: qsTr("开机自启")
        Layout.fillWidth: true
        Layout.leftMargin: 20
        Layout.rightMargin: 20
        FluToggleSwitch {}
    }

    SerialCube_SettingsRow {
        label: qsTr("启动时打开主页")
        Layout.fillWidth: true
        Layout.leftMargin: 20
        Layout.rightMargin: 20
        FluToggleSwitch { checked: true }
    }

    // 关于入口
    FluText {
        Layout.topMargin: 30
        Layout.leftMargin: 20
        text: qsTr("其他")
        font: FluTextStyle.BodyStrong
        opacity: 0.6
    }

    SerialCube_SettingsRow {
        label: qsTr("查看更新")
        Layout.fillWidth: true
        Layout.leftMargin: 20
        Layout.rightMargin: 20
        FluFilledButton {
            text: qsTr("检查更新")
        }
    }

    SerialCube_SettingsRow {
        label: qsTr("关于")
        Layout.fillWidth: true
        Layout.leftMargin: 20
        Layout.rightMargin: 20
        FluButton {
            text: qsTr("打开关于页")
        }
    }
}
