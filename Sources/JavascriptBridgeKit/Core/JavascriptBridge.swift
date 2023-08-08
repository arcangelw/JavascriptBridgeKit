//
//  JavascriptBridgeKit.swift
//
//
//  Created by 吴哲 on 2023/8/4.
//

import Foundation
import UIKit
import WebKit

@objc
public protocol JavascriptBridgeExport: AnyObject {}

public class JavascriptBridge: NSObject {
    private let iOS_Native_JSBridgeMessage = "iOS_Native_JSBridgeMessage"

    public weak var webView: WKWebView?

    private(set) weak var uiDelegate: WKUIDelegate?

    private(set) var uIDelegateProxy: JavascriptBridgeProxy!

    private(set) weak var navigationDelegate: WKNavigationDelegate?

    private(set) var navigationDelegateProxy: JavascriptBridgeProxy!

    private var dispatchers: [String: JavascriptDispatcher] = [:]

    public init(webView: WKWebView) {
        super.init()
        self.webView = webView
        resetProxy()
        setupBaseBridgeUserScript()
        addScriptMessageHandlers()
    }

    deinit {
        removeScriptMessageHandlers()
    }

    // MARK: - Public Funcs

    public func reset() {
        dispatchers.removeAll()
        removeAllBridgeUserScript()
        clearAllModules()
    }

    public func resetProxy() {
        if !(webView?.uiDelegate is JavascriptBridgeProxy) {
            uiDelegate = webView?.uiDelegate
            uIDelegateProxy = .init(uiDelegate, interceptor: self)
            webView?.uiDelegate = uIDelegateProxy
        }
        if !(webView?.navigationDelegate is JavascriptBridgeProxy) {
            navigationDelegate = webView?.navigationDelegate
            navigationDelegateProxy = .init(navigationDelegate, interceptor: self)
            webView?.navigationDelegate = navigationDelegateProxy
        }
    }

    public func addJavascript<T: AnyObject>(
        _ target: T,
        of aProtocol: Protocol = JavascriptBridgeExport.self,
        for module: String,
        on queue: DispatchQueue? = nil,
        retainTarget: Bool = false
    ) where T: JavascriptBridgeExport {
        let dispatcher = JavascriptDispatcher(target, for: module, on: queue, retainTarget: retainTarget)
        dispatchers[module] = dispatcher
        let userScript = JavascriptUserScript(module: module, target: target, of: aProtocol)
        addUserScript(userScript)
    }

    public func removeJavascript(for module: String) {
        dispatchers.removeValue(forKey: module)
        removeUserScript(of: module)
        clearModule(module)
    }

    // MARK: - Private Funcs

    private func addUserScript(_ userScript: WKUserScript) {
        webView?.configuration.userContentController.addUserScript(userScript)
    }

    private func removeUserScript(of module: String) {
        guard let webView = webView else { return }
        var userScripts = webView.configuration.userContentController.userScripts
        userScripts.removeAll { ($0 as? JavascriptUserScript)?.module == module }
        for userScript in userScripts {
            webView.configuration.userContentController.addUserScript(userScript)
        }
    }

    private func removeAllBridgeUserScript() {
        guard let webView = webView else { return }
        var userScripts = webView.configuration.userContentController.userScripts
        userScripts.removeAll { $0 is JavascriptUserScript }
        for userScript in userScripts {
            webView.configuration.userContentController.addUserScript(userScript)
        }
    }

    private func setupBaseBridgeUserScript() {
        guard webView?.configuration.userContentController.userScripts.contains(where: { $0 is JavascriptBridgeUserScript }) == false else {
            return
        }
        guard let userScript = JavascriptBridgeUserScript.create() else {
            fatalError()
        }
        addUserScript(userScript)
    }

    private func addScriptMessageHandlers() {
        webView?.configuration.userContentController.add(LeakAvoider(delegate: self), name: iOS_Native_JSBridgeMessage)
    }

    private func removeScriptMessageHandlers() {
        webView?.configuration.userContentController.removeScriptMessageHandler(forName: iOS_Native_JSBridgeMessage)
    }
}

// MARK: - WKScriptMessageHandler && handleSyncCall

extension JavascriptBridge: WKScriptMessageHandler {
    public func userContentController(_: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == iOS_Native_JSBridgeMessage else {
            return
        }
        guard JSONSerialization.isValidJSONObject(message.body) else {
            return
        }
        do {
            let data = try JSONSerialization.data(withJSONObject: message.body)
            let message = try JSONDecoder().decode(SendMessage.self, from: data)
            guard let dispatcher = dispatchers[message.module] else { return }
            dispatcher.javascriptCall(message)
        } catch {
            debugPrint(error.localizedDescription)
        }
    }

    internal func handleSyncCall(_ prompt: String, _ defaultText: String, _ completionHandler: @escaping (String?) -> Void) -> Bool {
        guard prompt == iOS_Native_JSBridgeMessage else {
            return false
        }
        do {
            let message = try JSONDecoder().decode(SendMessage.self, from: Data(defaultText.utf8))
            if let dispatcher = dispatchers[message.module] {
                dispatcher.javascriptSyncCall(message, completionHandler: completionHandler)
            } else {
                completionHandler(nil)
            }
        } catch {
            debugPrint(error.localizedDescription)
        }
        return true
    }
}

// MARK: - LeakAvoider

final class LeakAvoider: NSObject {
    weak var delegate: WKScriptMessageHandler?

    init(delegate: WKScriptMessageHandler) {
        super.init()
        self.delegate = delegate
    }
}

extension LeakAvoider: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        delegate?.userContentController(userContentController, didReceive: message)
    }
}
