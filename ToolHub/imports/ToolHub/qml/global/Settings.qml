pragma Singleton

import QtQuick 2.15
import QtCore   // 2026-08-26: QtCore.Settings (Qt 6.5+ 替代 Qt.labs.settings)
import FluentUI 1.0

/**
 * Settings (应用全局设置 singleton)
 * ----------------------------------
 * 统一封装持久化设置(底层 Qt.labs.settings → QSettings)和运行时切换。
 *
 * 当前支持的配置项:
 *   - navMode: int  0=紧凑 / 1=开放 / 2=自动(业务态)
 *
 * 关联决策: .workflow/decisions/2026-08-26_nav-mode-config.md
 *
 * v7 (2026-08-26 16:00): 0/1 直接对应库原生 FluNavigationViewType.Compact/Open 常量,
 *                       NavModel/NavFooter 单纯 push (跟 Example ItemsOriginal 一样)
 *                       2 仍用业务态启动 Compact + v5 helper toggle
 *
 * 用法:
 *   // 1. main.qml 启动时注入 navView 引用
 *   Settings.navView = nav_view
 *   Settings.applyNavMode()
 *
 *   // 2. 业务态读取
 *   Settings.navMode                    // 当前业务态 0/1/2
 *   if (Settings.navMode === 0) { ... } // 紧凑
 *
 *   // 3. 设置页切换
 *   Settings.setNavMode(0)              // 立即生效 + 写 QSettings
 */
FluObject {
    id: appSettings

    // 由 main.qml 注入(跟 NavModel / NavFooter 一致: singleton 拿不到外部 id)
    property var navView: null

    // ===== 持久化层(Qt.labs.settings 自动落 QSettings) =====
    // category="ui" → 注册表路径 ...\Software\ToolHub\ToolHub\ui
    // 首次运行 key 不存在 → 默认 navMode=2(自动, 符合用户原描述"默认折叠")
    Settings {
        id: persisted
        category: "ui"
        property int navMode: 2
    }

    // ===== 业务态属性 =====
    // 0 = 紧凑(Compact, 库原生常量, 跟 Example 选 Compact 一样)
    // 1 = 开放(Open, 库原生常量, 跟 Example 选 Open 一样)
    // 2 = 自动(Auto, 业务态: 启动 Compact + 点图标展开 + 重复点同项折叠)
    property int navMode: persisted.navMode

    // ===== 启动时一次性应用(main.qml Component.onCompleted 调用) =====
    // v9: 同步设 _navAutoMode 守卫 (库 expander onClicked 用)
    //     0/1 走 Example 库默认 popup 行为 (锁死)
    //     2 走 v3 决策 toggle 行为 (Compact→Open / Open→Compact)
    function applyNavMode() {
        if (!navView) {
            console.warn("Settings.applyNavMode(): navView 未注入,跳过")
            return
        }
        if (navMode === 0) {
            navView.displayMode = FluNavigationViewType.Compact
        } else if (navMode === 1) {
            navView.displayMode = FluNavigationViewType.Open
        } else {
            // 业务态 Auto: 强制启动 Compact(覆盖库默认 Auto+width>900=Open)
            // 配合 v5 helper toggle,实现"默认折叠 + 点展开 + 重复点折叠"
            navView.displayMode = FluNavigationViewType.Compact
        }
        // 同步 _navAutoMode 守卫
        navView._navAutoMode = (navMode === 2)
    }

    // ===== 切换时调用(T_Settings RadioButton onCurrentIndexChanged) =====
    function setNavMode(mode) {
        if (mode !== 0 && mode !== 1 && mode !== 2) {
            console.warn("Settings.setNavMode(): 无效值", mode)
            return
        }
        navMode = mode
        persisted.navMode = mode   // 写回 QSettings(Qt.labs.settings 自动)
        applyNavMode()              // 立即生效 (含 _navAutoMode 同步)
    }
}
