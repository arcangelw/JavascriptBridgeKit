/// <reference path="../../types/index.d.ts" />

/**
 * JSBridge 工具
 */
export class JSBridgeKitUtils {

}

/**
 * 处理iframe
 */
export class JSBridgeKitIframe {


    /**
     * 分发消息
     * @param message 
     */
    public static dispatchMessage(message: string) {
        let iframe: NodeListOf<HTMLIFrameElement> = document.querySelectorAll("iframe");
        // 处理有iframe的情况
        if (iframe) {
            let len = iframe.length;
            for (let i = 0; i < len; i++) {
                let win: any = iframe[i].contentWindow;
                win.postMessage(message, "*");
            }
        }
    }

    /**
     * 添加消息监听
     */
    public static addMessageListener() {
        // iframe 处理来自父 window 的消息
        window.addEventListener("message", e => {
            let data: any = e.data;
            if (typeof data === 'string') {
                let str: string = data as string
                if (str.indexOf("messageType") !== -1) {
                    // 处理回调
                    window.JSNativeBridge.handleMesageFromNative(str);
                }
            }
        });
    }

    /**
     * 让 iframe 能够注入 app 里面的脚本
     */
    public static setupHook() {
        // 设置 iframe 标签 的 sandbox 属性
        document.addEventListener('DOMContentLoaded', function () {
            let iframes: NodeListOf<HTMLIFrameElement> = document.querySelectorAll("iframe");
            if (iframes) {
                let len: number = iframes.length;
                for (let i = 0; i < len; i++) {
                    let iframe: HTMLIFrameElement = iframes[i];
                    if (iframe.getAttribute('sandbox') && iframe.getAttribute('sandbox').indexOf('allow-scripts') === -1) {
                        iframe.setAttribute('sandbox', iframe.getAttribute('sandbox') + ' allow-scripts');
                    }
                }
            }
        });

        // 设置 iframe 动态创建的 sandbox 属性
        let originalCreateElement = document.createElement;
        document.createElement = function (tag: string) {
            var element = originalCreateElement.call(document, tag);
            if (tag.toLowerCase() === 'iframe') {
                try {
                    var iframeSandbox = Object.getOwnPropertyDescriptor(window.HTMLIFrameElement, 'sandbox') ||
                        Object.getOwnPropertyDescriptor(HTMLIFrameElement.prototype, 'sandbox');
                    if (iframeSandbox && iframeSandbox.configurable) {
                        Object.defineProperty(element, 'sandbox', {
                            configurable: true,
                            enumerable: true,
                            get: function () {
                                return iframeSandbox.get.call(element);
                            },
                            set: function (val) {
                                if (val.indexOf('allow-scripts') === -1) {
                                    val = val + ' allow-scripts';
                                }
                                iframeSandbox.set.call(element, val);
                            }
                        });
                    }
                } catch (e) {
                    console.log('this browser does not support reconfigure iframe sandbox property', e);
                }
            }
            return element;
        };
    }
}