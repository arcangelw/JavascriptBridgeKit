//
//  JavascriptBridgeKit.swift
//
//
//  Created by 吴哲 on 2023/8/7.
//

import JavascriptBridgeObjC
import WebKit

final class JavascriptBridgeProxy: _JavascriptBridgeProxy {
    private var interceptSelectors: [Selector] = []

    init(_ uiDelegate: WKUIDelegate?, interceptor: _JavascriptBridgeProxyInterceptor) {
        super.init(target: uiDelegate, interceptor: interceptor)
        interceptSelectors = [
            #selector(WKUIDelegate.webView(_:runJavaScriptTextInputPanelWithPrompt:defaultText:initiatedByFrame:)),
        ]
    }

    init(_ navigationDelegate: WKNavigationDelegate?, interceptor: _JavascriptBridgeProxyInterceptor) {
        super.init(target: navigationDelegate, interceptor: interceptor)
        interceptSelectors = [
            #selector(WKUIDelegate.webView(_:runJavaScriptTextInputPanelWithPrompt:defaultText:initiatedByFrame:)),
        ]
    }

    override func interceptsSelector(_ aSelector: Selector) -> Bool {
        return interceptSelectors.contains(aSelector)
    }
}

extension JavascriptBridgeProxy: WKUIDelegate, WKNavigationDelegate {}

// MARK: - _JSBridgeProxyInterceptor

extension JavascriptBridge: _JavascriptBridgeProxyInterceptor {}

// MARK: - WKUIDelegate

extension JavascriptBridge: WKUIDelegate {
    public func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        guard canShowPanel(webView) else {
            completionHandler(nil)
            return
        }

        guard !handleSyncCall(prompt, description, completionHandler) else {
            return
        }
        guard uiDelegate?.webView?(webView, runJavaScriptTextInputPanelWithPrompt: prompt, defaultText: defaultText, initiatedByFrame: frame, completionHandler: completionHandler) == nil else {
            return
        }
        let sender = webView.url?.host ?? ""
        let alert = UIAlertController(title: prompt, message: sender, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.text = defaultText
        }
        alert.addAction(.init(title: "确定", style: .default, handler: { _ in
            if let input = alert.textFields?.first?.text, !input.isEmpty {
                completionHandler(input)
            } else {
                completionHandler(nil)
            }
        }))
        alert.addAction(.init(title: "取消", style: .cancel, handler: { _ in
            completionHandler(nil)
        }))
        if let parentViewController = parentViewController(webView) {
            parentViewController.present(alert, animated: true)
        } else {
            completionHandler(nil)
        }
    }

    private func canShowPanel(_ webview: WKWebView) -> Bool {
        guard let parentViewController = parentViewController(webview) else {
            return false
        }
        return !(parentViewController.isBeingPresented || parentViewController.isBeingDismissed || parentViewController.isMovingToParent || parentViewController.isMovingFromParent)
    }

    private func parentViewController(_ webview: WKWebView) -> UIViewController? {
        weak var parentResponder: UIResponder? = webview.next
        while parentResponder != nil {
            if let viewController = parentResponder as? UIViewController {
                return viewController
            }
            parentResponder = parentResponder?.next
        }
        return nil
    }
}
