(function (global, factory) {
    typeof exports === 'object' && typeof module !== 'undefined' ? module.exports = factory() :
    typeof define === 'function' && define.amd ? define(factory) :
    (global = typeof globalThis !== 'undefined' ? globalThis : global || self, global.JSBridge = factory());
})(this, (function () { 'use strict';

    /// <reference path="../../types/index.d.ts" />
    /**
     * JSBridge 工具
     */
    /**
     * 处理iframe
     */
    var JSBridgeIframe = /** @class */ (function () {
        function JSBridgeIframe() {
        }
        /**
         * 分发消息
         * @param message
         */
        JSBridgeIframe.dispatchMessage = function (message) {
            var iframe = document.querySelectorAll("iframe");
            // 处理有iframe的情况
            if (iframe) {
                var len = iframe.length;
                for (var i = 0; i < len; i++) {
                    var win = iframe[i].contentWindow;
                    win.postMessage(message, "*");
                }
            }
        };
        /**
         * 添加消息监听
         */
        JSBridgeIframe.addMessageListener = function () {
            // iframe 处理来自父 window 的消息
            window.addEventListener("message", function (e) {
                var data = e.data;
                if (typeof data === 'string') {
                    var str = data;
                    if (str.indexOf("messageType") !== -1) {
                        // 处理回调
                        window.JSBridge.handleMesageFromNative(str);
                    }
                }
            });
        };
        /**
         * 让 iframe 能够注入 app 里面的脚本
         */
        JSBridgeIframe.setupHook = function () {
            // 设置 iframe 标签 的 sandbox 属性
            document.addEventListener('DOMContentLoaded', function () {
                var iframes = document.querySelectorAll("iframe");
                if (iframes) {
                    var len = iframes.length;
                    for (var i = 0; i < len; i++) {
                        var iframe = iframes[i];
                        if (iframe.getAttribute('sandbox') && iframe.getAttribute('sandbox').indexOf('allow-scripts') === -1) {
                            iframe.setAttribute('sandbox', iframe.getAttribute('sandbox') + ' allow-scripts');
                        }
                    }
                }
            });
            // 设置 iframe 动态创建的 sandbox 属性
            var originalCreateElement = document.createElement;
            document.createElement = function (tag) {
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
                    }
                    catch (e) {
                        console.log('this browser does not support reconfigure iframe sandbox property', e);
                    }
                }
                return element;
            };
        };
        return JSBridgeIframe;
    }());

    /// <reference path="../../types/index.d.ts" />
    /**
     * 建立同 Native 通信
     */
    var JSBridge = /** @class */ (function () {
        function JSBridge() {
            this.uniqueId = -1;
            this.callbackCache = {};
            this.eventCallbackCache = {};
            this.moduleNames = [];
        }
        /**
         * 清空所有modules
         */
        JSBridge.prototype.clearAllModules = function () {
            this.moduleNames.forEach(function (module) {
                window[module] = null;
                delete window[module];
            });
            this.moduleNames = [];
        };
        /**
         * 清空指定module
         * @param module
         */
        JSBridge.prototype.clearModule = function (module) {
            window[module] = null;
            delete window[module];
        };
        /**
         * Native方法注入
         * @param module 模块名称
         * @param methodString 方法名列表
         * @param isSync 是否是同步
         */
        JSBridge.prototype.injectNativeScript = function (module, methodString, isSync) {
            this.moduleNames.push(module);
            var methods = JSON.parse(methodString);
            var global = window[module] ? window[module] : (window[module] = { "_sync": [] });
            var sync = global["_sync"];
            methods.forEach(function (method) {
                if (isSync && sync.indexOf(method) === -1) {
                    sync.push(method);
                }
                var shot = method.replace(":", "");
                if (!global[shot]) {
                    global[shot] = function () {
                        var data = Array.prototype.slice.call(arguments) || [];
                        var targetMethod = shot + data.map(function () { return ":"; }).join("");
                        if (sync.indexOf(targetMethod) === -1) {
                            // 异步调用
                            window.JSBridge.callNative(module, targetMethod, data);
                        }
                        else {
                            // 同步调用
                            return window.JSBridge.syncCallNative(module, targetMethod, data);
                        }
                    };
                }
            });
        };
        /**
         * 参数包装
         * @param data
         */
        JSBridge.prototype.messageDataWrapper = function (module, method, data) {
            var wrapper = [];
            for (var i = 0; i < data.length; i++) {
                var value = data[i];
                if (typeof value === "function") {
                    // 拼装 callbackId
                    var callbackId = 'cb_' + module + '_' + method + '_' + (this.uniqueId++) + '_' + new Date().getTime();
                    // 缓存 callback，用于在 Native 处理完消息后，通知 H5
                    this.callbackCache[callbackId] = value;
                    var callbackWrapper = {
                        callbackId: callbackId
                    };
                    wrapper.push(callbackWrapper);
                }
                else {
                    wrapper.push(value);
                }
            }
            return wrapper;
        };
        /**
         * 异步调用 Native
         * @param module 模块
         * @param method 方法
         * @param data 数据
         */
        JSBridge.prototype.callNative = function (module, method, data) {
            var message = {
                module: module,
                method: method,
                data: this.messageDataWrapper(module, method, data)
            };
            // 发送消息给 Native
            window.webkit.messageHandlers.iOS_Native_JSBridgeMessage.postMessage(message);
        };
        /**
          * 同步调用 Native
          * @param module 模块
          * @param method 方法
          * @param data 数据
          */
        JSBridge.prototype.syncCallNative = function (module, method, data) {
            var message = {
                module: module,
                method: method,
                data: this.messageDataWrapper(module, method, data)
            };
            var messageString = JSON.stringify(message);
            try {
                var response = window.prompt("iOS_Native_JSBridgeMessage", messageString);
                var result = response ? JSON.parse(response) : null;
                return result.value;
            }
            catch (e) {
                // https://developer.mozilla.org/en-US/docs/Web/API/WindowEventHandlers/onbeforeunload
                console.log('window.prompt will happen error when beforeunload event triggered', e);
                return null;
            }
        };
        /**
         * 处理来自 Native 的回调
         * @param message
         */
        JSBridge.prototype.handleMesageFromNative = function (message) {
            var callbackMessage = JSON.parse(message);
            if (callbackMessage.messageType === "callback" /* JS.MessageType.Callback */) {
                // 执行 callback 回调并删除缓存
                var callback = this.callbackCache[callbackMessage.callbackId];
                if (callback) {
                    callback.apply(null, callbackMessage.data);
                    this.callbackCache[callbackMessage.callbackId] = null;
                    delete this.callbackCache[callbackMessage.callbackId];
                }
            }
            else if (callbackMessage.messageType === "event" /* JS.MessageType.Event */) {
                // 批量处理事件
                var obsevers = this.eventCallbackCache[callbackMessage.callbackId];
                if (obsevers) {
                    for (var i = 0; i < obsevers.length; i++) {
                        var eventCallback = obsevers[i];
                        if (eventCallback) {
                            eventCallback.apply(null, callbackMessage.data);
                        }
                    }
                }
            }
            // 处理 iframe
            JSBridgeIframe.dispatchMessage(message);
        };
        /**
         * 监听事件
         * @param eventName 事件名字
         * @param callback 事件回调
         */
        JSBridge.prototype.on = function (eventName, callback) {
            // 使用数组，支持多个观察者
            var obsevers = this.eventCallbackCache[eventName];
            if (obsevers) {
                obsevers.push(callback);
            }
            else {
                obsevers = [callback];
                this.eventCallbackCache[eventName] = obsevers;
            }
        };
        /**
         * 取消监听事件
         * @param eventName 事件名字
         */
        JSBridge.prototype.off = function (eventName) {
            var obsevers = this.eventCallbackCache[eventName];
            if (obsevers && obsevers.length > 0) {
                obsevers.splice(0, obsevers.length);
            }
        };
        return JSBridge;
    }());

    /// <reference path="../types/index.d.ts" />
    var init = function () {
        if (window.JSBridge) {
            return;
        }
        // 初始化 JSBridge 并设为全局对象
        window.JSBridge = new JSBridge();
        // iframe 内处理来自父 window 的消息
        JSBridgeIframe.addMessageListener();
        // 设置 iframe hook
        JSBridgeIframe.setupHook();
    };
    init();
    var index = window.JSBridge;

    return index;

}));
