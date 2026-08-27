import QtQuick 2.15
import QtQuick.Controls 2.15
import FluentUI 1.0

/**
 * SerialCube_NavToggleHelper
 * --------------------------
 * 侧边栏点击行为的共享逻辑。
 *
 * 历史:
 * - v1 (2026-08-26): NavModel + NavFooter 各写一份 isCurrentItem/handleItemClick
 * - v2 (L1 抽取): 抽成单一 component,各 singleton 实例化后 forward
 * - v3 (12:24 修复 1): navView.currentUrl → navView.getCurrentUrl() (属性/函数误用)
 * - v4 (12:30 修复 2): 用内部状态 lastClickedUrl 替代 getCurrentUrl() 字符串比较
 *       — ToolHub 启动 displayMode=Open(width=1000 > 900 触发 Auto 模式);
 *         loader_content.source.toString() 与 item.url 的 QUrl 形式可能不严格相等,
 *         字符串比较失败导致 toggle 永远不触发
 *       — 业务层自己记录"上次点击的 url" 绕开 QUrl 比较问题
 * - v5: handleItemClick 简化(去冗余条件),重复点 → 无条件折叠
 * - v6 (2026-08-26, 配套 navMode 配置): 加 fixedMode 短路
 *       — 0=固定紧凑/1=固定开放: 点图标不切换 displayMode(用户显式选定的固定态不能被 toggle 破坏)
 *       — 2=业务态自动/未传: 走 v5 toggle 逻辑
 *       — 启动态不再依赖库 Auto(width-based),改由 main.qml 注入 Settings.applyNavMode() 强制设
 * - v7 (2026-08-26 16:00, 用户反馈后修正): 删 v6 fixedMode 短路
 *       — 用户反馈"和 Example 一样": Example 用库原生 Compact/Open/Auto, NavModel 单纯 push 不切 displayMode
 *       — v6 短路导致业务态 0/1 "点击图标不展开/不折叠",跟用户原话"点击图标可以展开/折叠"相反
 *       — 新约定: NavModel/NavFooter onTap 根据 Settings.navMode 决定是否调 helper
 *         * 0/1 库原生: 不调 helper, 单纯 navView.push(url) (跟 Example ItemsOriginal 一样)
 *         * 2 业务态自动: 调 helper (v5 toggle)
 *       — helper 本身退回 v5, 不需要传 fixedMode
 *
 * 用法:
 *   SerialCube_NavToggleHelper {
 *       id: navHelper
 *       navView: nav_view
 *   }
 *   // 然后:
 *   navHelper.isCurrentItem(item)
 *   navHelper.handleItemClick(item, parent)   // parent 可选 (业务态 2/自动用, 0/1 不调)
 */
QtObject {
    id: helper

    // 由 main.qml 注入
    property var navView: null

    // 业务层自己的"上次点击"记忆(绕开 QUrl 字符串比较问题)
    // 不同 singleton 各持一份(NavModel 一个,NavFooter 一个)
    // 跨 singleton 切换页:目标 singleton 的 lastClickedUrl 初始为 "" → 不会误折叠
    property string lastClickedUrl: ""

    // 判定 item 是否是当前页(用于 toggle 检查)
    // 用业务层自己的 lastClickedUrl,绕开 QUrl 字符串 normalize 问题
    function isCurrentItem(item) {
        if (!item || !item.url) return false
        return helper.lastClickedUrl === item.url
    }

    // 处理 item 点击:返回 true 表示已折叠(调用方跳过 push),false 表示已展开(可继续 push)
    // parent 传 null/undefined 表示无父项(顶级 leaf 场景)
    //
    // v7 退回 v5:helper 自身不再分 fixedMode,统一走 toggle 逻辑
    // NavModel/NavFooter onTap 根据 Settings.navMode 决定是否调本函数:
    //   0/1 库原生 → 不调, 单纯 navView.push(url)
    //   2 业务态自动 → 调, 走下面 v5 toggle
    //
    // v5 关键修法:不去读 navView.displayMode(库外部 property 默认 Auto=2,不是实际状态)
    // 重复点 → 无条件折叠(改 navView.displayMode,库内部 d.displayMode 跟随)
    // 第一次 / 切换 → 展开(若当前是 Compact)+ push + 记录 lastClickedUrl
    function handleItemClick(item, parent) {
        // 1. 重复点同一项 → 折叠(无条件)
        if (isCurrentItem(item)) {
            navView.displayMode = FluNavigationViewType.Compact
            helper.lastClickedUrl = ""   // 折叠后清空,下次点重新走"展开"分支
            return true
        }
        // 2. 第一次点 / 切到不同项 → 展开 + 推进
        if (navView && navView.displayMode === FluNavigationViewType.Compact) {
            navView.displayMode = FluNavigationViewType.Open
        }
        if (parent && parent.isExpand !== undefined) {
            parent.isExpand = true
        }
        helper.lastClickedUrl = item.url   // 记录本次点击,下次可判定重复
        return false
    }
}
