/// <reference path="../types/index.d.ts" />
import { JSBridge } from "./bridge/JSBridge";
import { _JSBridgeCookieHook } from "./hooks/JSBridgeCookieHook";
import { JSBridgeIframe } from "./util/JSBridgeUtil";
import { JSBridgeUtils } from "./util/JSBridgeUtil";

var init = function () {
    if (window.JSBridge) {
        return;
    }
    /**
  * KKJSBridge 配置
  */
    class JSBridgeConfig {
        public static cookieSetHook: boolean = true;
        public static cookieGetHook: boolean = true;

        /**
         * 开启 cookie set hook
         */
        public static enableCookieSetHook: Function = (enable: boolean) => {
            JSBridgeConfig.cookieSetHook = enable;
        };

        /**
         * 开启 cookie get hook
         */
        public static enableCookieGetHook: Function = (enable: boolean) => {
            JSBridgeConfig.cookieGetHook = enable;
        };
    }

    // 初始化 JSBridge 并设为全局对象
    window.JSBridge = new JSBridge();
    // 设置 KKJSBridgeConfig 为全局对象
    window.JSBridgeConfig = JSBridgeConfig;
    
    // iframe 内处理来自父 window 的消息
    JSBridgeIframe.addMessageListener();

    // 设置 iframe hook
    JSBridgeIframe.setupHook();

    // 安装 cookie hook
    _JSBridgeCookieHook.setupHook();
}
init();
export default window.JSBridge;