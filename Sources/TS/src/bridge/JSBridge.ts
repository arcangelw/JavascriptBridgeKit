/// <reference path="../../types/index.d.ts" />
import { JSBridgeIframe } from "src/util/JSBridgeUtil";

/**
 * 建立同 Native 通信
 */
export class JSBridge {

    /**
     * 标记回调函数
     */
    private uniqueId: number;

    /**
     * 用于缓存Native回调
     */
    private callbackCache: { [key: string]: JS.Callback };

    /**
     * 用于缓存Native事件
     */
    private eventCallbackCache: { [key: string]: [JS.EventCallback] };

    /**
     * 记录已经注册的module
     */
    private moduleNames: string[];

    constructor() {
        this.uniqueId = -1;
        this.callbackCache = {};
        this.eventCallbackCache = {};
        this.moduleNames = [];
    }

    /**
     * 清空所有modules
     */
    public clearAllModules() {
        this.moduleNames.forEach(module => {
            window[module] = null;
            delete window[module];
        });
        this.moduleNames = []
    }

    /**
     * 清空指定module
     * @param module 
     */
    public clearModule(module: string) {
        window[module] = null;
        delete window[module];
    }

    /**
     * Native方法注入
     * @param module 模块名称
     * @param methodString 方法名列表
     * @param isSync 是否是同步
     */
    public injectNativeScript(module: string, methodString: string, isSync: Boolean) {
        this.moduleNames.push(module);
        let methods: [string] = JSON.parse(methodString);
        let global: { [key: string]: any } = window[module] ? window[module] : (window[module] = { "_sync": [] });
        let sync: [string] = global["_sync"];
        methods.forEach(method => {
            if (isSync && sync.indexOf(method) === -1) {
                sync.push(method);
            }
            let shot: string = method.replace(":", "");
            if (!global[shot]) {
                global[shot] = function () {
                    let data: [] = Array.prototype.slice.call(arguments) || [];
                    let targetMethod: string = shot + data.map(() => ":").join("");
                    if (sync.indexOf(targetMethod) === -1) {
                        // 异步调用
                        window.JSBridge.callNative(module, targetMethod, data);
                    } else {
                        // 同步调用
                        return window.JSBridge.syncCallNative(module, targetMethod, data);
                    }
                };
            }
        });
    }

    /**
     * 参数包装
     * @param data 
     */
    private messageDataWrapper(module: string, method: string, data: any[]): any[] {
        let wrapper: any[] = [];
        for (let i = 0; i < data.length; i++) {
            let value = data[i];
            if (typeof value === "function") {
                // 拼装 callbackId
                const callbackId: string = 'cb_' + module + '_' + method + '_' + (this.uniqueId++) + '_' + new Date().getTime();
                // 缓存 callback，用于在 Native 处理完消息后，通知 H5
                this.callbackCache[callbackId] = value;
                let callbackWrapper: JS.SendMessageCallbackId = {
                    callbackId: callbackId
                }
                wrapper.push(callbackWrapper)
            } else {
                wrapper.push(value)
            }
        }
        return wrapper
    }

    /**
     * 异步调用 Native
     * @param module 模块
     * @param method 方法
     * @param data 数据
     */
    public callNative(module: string, method: string, data: any[]) {
        let message: JS.SendMessage = {
            module: module,
            method,
            data: this.messageDataWrapper(module, method, data)
        };
        // 发送消息给 Native
        window.webkit.messageHandlers.iOS_Native_JSBridgeMessage.postMessage(message);
    }

    /**
      * 同步调用 Native
      * @param module 模块
      * @param method 方法
      * @param data 数据
      */
    public syncCallNative(module: string, method: string, data: any[]): any {
        let message: JS.SendMessage = {
            module: module,
            method,
            data: this.messageDataWrapper(module, method, data)
        };
        let messageString = JSON.stringify(message);
        try {
            let response = window.prompt("iOS_Native_JSBridgeMessage", messageString);
            let result: JS.SyncResult | null = response ? JSON.parse(response) : null;
            return result.value;
        } catch (e) {
            // https://developer.mozilla.org/en-US/docs/Web/API/WindowEventHandlers/onbeforeunload
            console.log('window.prompt will happen error when beforeunload event triggered', e);
            return null;
        }
    }

    /**
     * 处理来自 Native 的回调
     * @param message 
     */
    public handleMesageFromNative(message: string) {
        let callbackMessage: JS.CallbackMessage = JSON.parse(message);
        if (callbackMessage.messageType === JS.MessageType.Callback) {
            // 执行 callback 回调并删除缓存
            let callback: JS.Callback = this.callbackCache[callbackMessage.callbackId];
            if (callback) {
                callback.apply(null, callbackMessage.data);
                this.callbackCache[callbackMessage.callbackId] = null;
                delete this.callbackCache[callbackMessage.callbackId];
            }
        } else if (callbackMessage.messageType === JS.MessageType.Event) {
            // 批量处理事件
            let obsevers: [JS.EventCallback] = this.eventCallbackCache[callbackMessage.callbackId];
            if (obsevers) {
                for (let i = 0; i < obsevers.length; i++) {
                    let eventCallback: JS.EventCallback = obsevers[i];
                    if (eventCallback) {
                        eventCallback.apply(null, callbackMessage.data);
                    }
                }
            }
        }
        // 处理 iframe
        JSBridgeIframe.dispatchMessage(message);
    }

    /**
     * 监听事件
     * @param eventName 事件名字
     * @param callback 事件回调
     */
    public on(eventName: string, callback: JS.EventCallback) {
        // 使用数组，支持多个观察者
        let obsevers: [JS.EventCallback] = this.eventCallbackCache[eventName];
        if (obsevers) {
            obsevers.push(callback);
        } else {
            obsevers = [callback];
            this.eventCallbackCache[eventName] = obsevers;
        }
    }

    /**
     * 取消监听事件
     * @param eventName 事件名字
     */
    public off(eventName: string) {
        let obsevers: [JS.EventCallback] = this.eventCallbackCache[eventName];
        if (obsevers && obsevers.length > 0) {
            obsevers.splice(0, obsevers.length);
        }
    }
}