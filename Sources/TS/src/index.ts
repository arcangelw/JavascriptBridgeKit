/// <reference path="../types/index.d.ts" />
import { JSNativeBridge } from "./bridge/JSNativeBridge";
import { _JSBridgeKitCookieHook } from "./hooks/JSBridgeKitCookieHook";
import { JSBridgeKitIframe } from "./util/JSBridgeKitUtils";
import { JSBridgeKitUtils } from "./util/JSBridgeKitUtils";

var init = function () {
    if (window.JSNativeBridge) {
        return;
    }
    /**
  * JSBridge 配置
  */
    class JSBridgeKitConfig {
        public static cookieSetHook: boolean = true;
        public static cookieGetHook: boolean = true;

        /**
         * 开启 cookie set hook
         */
        public static enableCookieSetHook: Function = (enable: boolean) => {
            JSBridgeKitConfig.cookieSetHook = enable;
        };

        /**
         * 开启 cookie get hook
         */
        public static enableCookieGetHook: Function = (enable: boolean) => {
            JSBridgeKitConfig.cookieGetHook = enable;
        };
    }

    // 初始化 JSBridge 并设为全局对象
    window.JSNativeBridge = new JSNativeBridge();
    // 设置 JSBridgeKitConfig 为全局对象
    window.JSNativeBridgeKitConfig = JSBridgeKitConfig;
    
    // iframe 内处理来自父 window 的消息
    JSBridgeKitIframe.addMessageListener();

    // 设置 iframe hook
    JSBridgeKitIframe.setupHook();

    // 安装 cookie hook
    _JSBridgeKitCookieHook.setupHook();
}
init();
export default window.JSNativeBridge;