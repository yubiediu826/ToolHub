import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQml 2.15
import Qt.labs.platform 1.1
import FluentUI 1.0
import "global"

FluWindow {
    id: window
    title: "ToolHub"
    width: 1000
    height: 668
    minimumWidth: 668
    minimumHeight: 480
    launchMode: FluWindowType.SingleTask
    fitsAppBarWindows: true

    appBar: FluAppBar {
        width: window.width
        height: 30
        // 启用 FluAppBar 自带 dark 按钮（原始位置：OS 标题栏区域 y=0-30 右侧）
        // 通过 frameless.setHitTestVisible 让它能接收鼠标事件
        showDark: true
        darkClickListener: (button) => {
            // FluThemeType.DarkMode: System=0, Light=1, Dark=2
            // 点 dark 按钮 → 切到 Dark；再点 → 切回 Light。
            // System (0) 也走 2 (Dark),符合"按下变深色"的用户预期
            FluTheme.darkMode = FluTheme.darkMode === 2 ? 1 : 2
        }
    }

    FluNavigationView {
        id: nav_view
        anchors.fill: parent
        pageMode: FluNavigationViewType.NoStack

        // 侧边栏宽度：默认 300 → 250
        cellWidth: 250

        logo: "qrc:/ToolHub/image/logo.ico"
        title: "ToolHub"

        // 搜索栏——用 FluentUI 内置 autoSuggestBox（侧边栏头部自动位置）
        autoSuggestBox: FluAutoSuggestBox {
            iconSource: FluentIcons.Search
            placeholderText: qsTr("搜索工具 / 设置")
            items: NavModel.getSearchData()
            onItemClicked: (data) => {
                if (data && data.key) {
                    nav_view.startPageByItem(data)
                }
            }
        }

        Component.onCompleted: {
            // 把 nav_view 引用注入给 nav 模型的 singleton
            // 因为 singleton 拿不到外部 id，必须从外部注入
            NavModel.navView = nav_view
            NavFooter.navView = nav_view
            Settings.navView = nav_view   // 2026-08-26: navMode 配置用

            // 2026-08-26: 应用持久化的 navMode(必须在 setCurrentIndex 之前,
            // 否则库会先按 Auto+width 判定一次 displayMode)
            // 业务态 Auto 强制启动 Compact,覆盖库默认 Open
            Settings.applyNavMode()

            setCurrentIndex(0)
            if (nav_view.buttonMenu) {
                nav_view.buttonMenu.visible = true
            }
            // 隐藏 nav view 内置的返回箭头（NoStack 模式不需要）
            if (nav_view.buttonBack) {
                nav_view.buttonBack.visible = false
            }
        }

        items: NavModel
        footerItems: NavFooter
    }

    // 折叠按钮已移到 NavFooter（侧边栏底部）

    Component.onCompleted: {
        // 把 FluAppBar 内部的 dark 按钮注册到 frameless 的 hit-test 可见区
        // 这样即使它在 OS 标题栏区域（y=0-30）也能接收鼠标事件
        if (window.appBar && window.appBar.btn_dark) {
            if (typeof frameless !== "undefined" && frameless && frameless.setHitTestVisible) {
                frameless.setHitTestVisible(window.appBar.btn_dark)
            }
        }
    }

    Component.onDestruction: {
        FluRouter.exit()
    }
}
