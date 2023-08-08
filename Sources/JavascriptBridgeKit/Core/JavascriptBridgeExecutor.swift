//
//  JavascriptBridgeKit.swift
//
//
//  Created by 吴哲 on 2023/8/7.
//

import Foundation
import WebKit

// MARK: - Callback

public extension JavascriptBridge {
    /// 回调JS方法
    /// - Parameter id: 回调id
    func callBack(_ id: SendMessageCallBack) {
        _callBack(id, arguments: [])
    }

    /// 回调JS方法
    /// - Parameters:
    ///   - id: 回调id
    ///   - data: 回调数据
    func callBack(_ id: SendMessageCallBack, argument: Any? ...) {
        _callBack(id, arguments: argument.map { $0 ?? NSNull() })
    }

    private func _callBack(_ id: SendMessageCallBack, arguments: [Any]) {
        let callbackMessage = CallbackMessage(messageType: .callback, callbackId: id.callbackId, eventName: nil, data: arguments)
        do {
            let messageData = try JSONEncoder().encode(callbackMessage)

            var messageJSON = String(decoding: messageData, as: UTF8.self)
            messageJSON = messageJSON.replacingOccurrences(of: "\\", with: "\\\\")
            messageJSON = messageJSON.replacingOccurrences(of: "\"", with: "\\\"")
            messageJSON = messageJSON.replacingOccurrences(of: "\'", with: "\\\'")
            messageJSON = messageJSON.replacingOccurrences(of: "\n", with: "\\n")
            messageJSON = messageJSON.replacingOccurrences(of: "\r", with: "\\r")
            messageJSON = messageJSON.replacingOccurrences(of: "\u{000C}", with: "\\f")
            messageJSON = messageJSON.replacingOccurrences(of: "\u{2028}", with: "\\u2028")
            messageJSON = messageJSON.replacingOccurrences(of: "\u{2029}", with: "\\u2029")

            let javascript = "window.JSBridge.handleMesageFromNative && window.JSBridge.handleMesageFromNative('\(messageJSON)')"
            webView?.evaluateJavascriptInDefaultContentWorld(javascript)
        } catch {
            debugPrint(error.localizedDescription)
        }
    }
}

// MARK: - clear module

internal extension JavascriptBridge {
    /// 清空所有module
    func clearAllModules() {
        webView?.evaluateJavascriptInDefaultContentWorld("window.JSBridge&&window.JSBridge.clearAllModules()")
    }

    /// 清空指定module
    /// - Parameter module: module
    func clearModule(_ module: String) {
        webView?.evaluateJavascriptInDefaultContentWorld("window.JSBridge&&window.JSBridge.clearModule('\(module)')")
    }
}
