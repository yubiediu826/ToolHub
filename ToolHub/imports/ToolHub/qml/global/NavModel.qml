pragma Singleton

import QtQuick 2.15
import FluentUI 1.0
import "../Components"
import "."   // 2026-08-26: 拿 Settings singleton (sibling NavModel/NavFooter/Settings 同在 global/)

FluObject {
    id: navModel

    // 由 main.qml 注入：nav_view 引用
    // singleton 拿不到外部 id，所以从外部注入
    property var navView: null

    // 共享点击行为 helper(非 singleton,可被多个 singleton 实例化复用)
    SerialCube_NavToggleHelper {
        id: toggleHelper
        navView: navModel.navView
    }

    // ===== 规范依据 =====
    // 图标规范：见 decisions/2026-08-23_toolhub-nav-icon-spec.md
    // 点击行为：见 decisions/2026-08-26_ui-nav-click-behavior.md
    //   - Compact 模式点任何图标 → 展开 sidebar + (父项时)展开子项
    //   - Open 模式重复点同一图标 → 折叠回 Compact (toggle)
    //   - onTap 保持最小：调 helper 后 return，再 push(url)
    //   v7 (2026-08-26 16:00): 业务态 0/1 跟 Example ItemsOriginal 一样 — 单纯 push, 不调 helper
    //                            业务态 2 (自动) 仍调 helper (toggle 闭环)

    // ===== 转发到共享 helper(避免 NavModel/NavFooter 各写一份) =====
    // v7: helper 只服务业务态 2 (自动 toggle), 0/1 不调
    function isCurrentItem(item) { return toggleHelper.isCurrentItem(item) }
    function handleItemClick(item, parent) { return toggleHelper.handleItemClick(item, parent) }
    // ===== 主区 items =====

    // 顶级 leaf（首页）
    FluPaneItem {
        id: item_home
        key: "home"
        title: qsTr("首页")
        icon: FluentIcons.Home
        url: "qrc:/ToolHub/qml/page/T_Home.qml"
        onTap: {
            // v7: 业务态 2 (自动) 调 helper; 0/1 库原生单纯 push
            if (Settings.navMode === 2 && navModel.handleItemClick(this, null)) return
            navView.push(url)
        }
    }

    // 工具分组
    FluPaneItemExpander {
        id: toolExpander
        key: "tool"
        title: qsTr("工具")
        icon: FluentIcons.DeveloperTools
        // expander 父项点击行为在库 FluNavigationView.qml:228-244(决策: 2026-08-26)

        FluPaneItem {
            id: item_tool_serial
            key: "tool_serial"
            title: qsTr("串口调试")
            url: "qrc:/ToolHub/qml/page/T_Serial.qml"
            onTap: {
                // v7: 业务态 2 调 helper; 0/1 单纯 push (跟 Example ItemsOriginal 一样)
                if (Settings.navMode === 2 && navModel.handleItemClick(this, toolExpander)) return
                navView.push(url)
            }
        }
    }

    // ===== 搜索数据(已有,保留) =====
    function getSearchData() {
        var arr = []
        for (var i = 0; i < children.length; i++) {
            var item = children[i]
            if (item instanceof FluPaneItem) {
                arr.push({title: item.title, key: item.key})
            } else if (item instanceof FluPaneItemExpander) {
                for (var j = 0; j < item.children.length; j++) {
                    var c = item.children[j]
                    if (c instanceof FluPaneItem) {
                        arr.push({title: item.title + " → " + c.title, key: c.key})
                    }
                }
            }
        }
        return arr
    }
}
