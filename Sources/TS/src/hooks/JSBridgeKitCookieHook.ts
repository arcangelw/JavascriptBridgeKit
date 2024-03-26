/// <reference path="../../types/index.d.ts" />

/**
 * hook document.cookie
 */
export class _JSBridgeKitCookieHook {
    // 静态属性和方法
    public static readonly moduleName: string = 'cookieSync';
    /**
     * 通过重新定义 cookie 属性来进行 cookie hook
     */
    public static setupHook: Function = () => {
        try {
            var cookieDesc = Object.getOwnPropertyDescriptor(Document.prototype, 'cookie') ||
                Object.getOwnPropertyDescriptor(HTMLDocument.prototype, 'cookie');
            if (cookieDesc && cookieDesc.configurable) {
                Object.defineProperty(document, 'cookie', {
                    configurable: true,
                    enumerable: true,
                    get: function () {
                        if (window.JSNativeBridgeKitConfig.cookieGetHook) {// 如果开启 cookie get hook，则需要从 Native 同步
                            return window.JSNativeBridge.callNative(_JSBridgeKitCookieHook.moduleName, "getCookie", [window.location.href]);
                        }

                        return cookieDesc.get.call(document);
                    },
                    set: function (val) {
                        // console.log('setCookie');
                        if (window.JSNativeBridgeKitConfig.cookieSetHook) {// 如果开启 cookie set hook，则需要把 cookie 同步给 Native
                            window.JSNativeBridge.callNative(_JSBridgeKitCookieHook.moduleName, "setCookie", [val]);
                        }

                        cookieDesc.set.call(document, val);
                    }
                });
            }
        } catch (e) {
            console.log('this browser does not support reconfigure document.cookie property', e);
        }
    };
}