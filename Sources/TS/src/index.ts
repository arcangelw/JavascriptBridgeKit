/// <reference path="../types/index.d.ts" />
import { JSBridge } from "./bridge/JSBridge";
import { JSBridgeIframe } from "./util/JSBridgeUtil";
import { JSBridgeUtils } from "./util/JSBridgeUtil";

var init = function() {
    if (window.JSBridge) {
        return;
    }
    // 初始化 JSBridge 并设为全局对象
    window.JSBridge = new JSBridge();

    // iframe 内处理来自父 window 的消息
    JSBridgeIframe.addMessageListener();

    // 设置 iframe hook
    JSBridgeIframe.setupHook();
}
init();
export default window.JSBridge;