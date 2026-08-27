pragma Singleton

import QtQuick 2.15
import FluentUI 1.0
import "../Components"
import "."   // 2026-08-26: 拿 Settings singleton

FluObject {
    id: navFooterRoot

    // 由 main.qml 注入：nav_view 引用
    // singleton 拿不到外部 id，所以从外部注入
    property var navView: null

    // 共享点击行为 helper(同 NavModel.qml)
    SerialCube_NavToggleHelper {
        id: toggleHelper
        navView: navFooterRoot.navView
    }

    // ===== 规范依据 =====
    // 点击行为：见 decisions/2026-08-26_ui-nav-click-behavior.md
    //   - Compact 模式点任何图标 → 展开 sidebar
    //   - Open 模式重复点同一图标 → 折叠回 Compact (toggle)
    //   - onTap 保持最小：调 helper 后 return，再 push(url)
    //   - 折叠按钮本身就在 toggle displayMode, 不走 helper(行为已经在 onTapListener 里)
    //   v7 (2026-08-26 16:00): 业务态 0/1 跟 Example ItemsOriginal 一样 — 单纯 push, 不调 helper
    //   v10 (2026-08-26 16:22): 业务态 2 footer 单纯 push, 不调 helper
    //        - 用户反馈 (16:20): "自动模式设置和信息保持紧凑, 点击图标不需要展开"
    //        - footer (设置/关于) 是辅助, 频繁点击不展开 sidebar 减少视觉跳动
    //        - 主区 NavModel 业务态 2 仍走 v5 helper toggle (跟原话"点击图标展开" 一致)
    //        - expander 父项 "工具" 业务态 2 走库 _navAutoMode 守卫 toggle (v9)

    // ===== 转发到共享 helper =====
    // footer 项没有 expander 父项,所以不需要 parent 参数(与 NavModel 区分)
    // v10: helper 实际不被 footer 调用 (v10 后 footer 全部业务态都单纯 push),
    //      保留以备未来恢复 toggle 行为
    function isCurrentItem(item) { return toggleHelper.isCurrentItem(item) }
    function handleItemClick(item) { return toggleHelper.handleItemClick(item, null) }

    // ===== 底部 items =====

    // 折叠按钮已删除(决策 2026-08-26): v5 helper 的"重复点图标折叠"完全替代手动折叠按钮

    FluPaneItem {
        id: item_settings
        key: "settings"
        title: qsTr("设置")
        icon: FluentIcons.Settings
        url: "qrc:/ToolHub/qml/page/T_Settings.qml"
        onTap: {
            // v10: footer 全部业务态 (0/1/2) 单纯 push, 不调 helper
            //     业务态 0/1 锁死 (跟 v7 一致)
            //     业务态 2 footer 不展开 sidebar (用户 16:20 反馈)
            navView.push(url)
        }
    }

    FluPaneItem {
        id: item_about
        key: "about"
        title: qsTr("关于")
        icon: FluentIcons.Info
        url: "qrc:/ToolHub/qml/page/T_About.qml"
        onTap: {
            // v10: 同 item_settings
            navView.push(url)
        }
    }
}
