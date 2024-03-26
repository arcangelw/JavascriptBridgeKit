//
//  WKWebViewExtension.swift
//
//
//  Created by 吴哲 on 2023/8/4.
//

import Foundation
import WebKit

public extension WKWebView {
    func evaluateJavascriptInDefaultContentWorld(_ javascript: String) {
        // iOS 14.3 is required here because of a webkit bug in lower iOS versions with this API
        if #available(iOS 14.3, *) {
            self.evaluateJavaScript(javascript, in: nil, in: .defaultClient, completionHandler: { _ in })
        } else {
            evaluateJavaScript(javascript)
        }
    }

    func evaluateJavascriptInDefaultContentWorld(_ javascript: String, _ frame: WKFrameInfo? = nil, _ completion: @escaping (Any?, Error?) -> Void) {
        // iOS 14.3 is required here because of a webkit bug in lower iOS versions with this API
        if #available(iOS 14.3, *) {
            self.evaluateJavaScript(javascript, in: frame, in: .defaultClient) { result in
                switch result {
                case let .success(value):
                    completion(value, nil)
                case let .failure(error):
                    completion(nil, error)
                }
            }
        } else {
            evaluateJavaScript(javascript) { data, error in
                completion(data, error)
            }
        }
    }
}

public extension WKUserContentController {
    func addInDefaultContentWorld(scriptMessageHandler: WKScriptMessageHandler, name: String) {
        // iOS 14.3 is required here because of a webkit bug in lower iOS versions with this API
        if #available(iOS 14.3, *) {
            add(scriptMessageHandler, contentWorld: .defaultClient, name: name)
        } else {
            add(scriptMessageHandler, name: name)
        }
    }

    func addInPageContentWorld(scriptMessageHandler: WKScriptMessageHandler, name: String) {
        // iOS 14.3 is required here because of a webkit bug in lower iOS versions with this API
        if #available(iOS 14.3, *) {
            add(scriptMessageHandler, contentWorld: .page, name: name)
        } else {
            add(scriptMessageHandler, name: name)
        }
    }
}

public extension WKUserScript {
    class func createInDefaultContentWorld<T: WKUserScript>(source: String, injectionTime: WKUserScriptInjectionTime, forMainFrameOnly: Bool) -> T {
        // iOS 14.3 is required here because of a webkit bug in lower iOS versions with this API
        if #available(iOS 14.3, *) {
            return T(source: source, injectionTime: injectionTime, forMainFrameOnly: forMainFrameOnly, in: .defaultClient)
        } else {
            return T(source: source, injectionTime: injectionTime, forMainFrameOnly: forMainFrameOnly)
        }
    }

    class func createInPageContentWorld<T: WKUserScript>(source: String, injectionTime: WKUserScriptInjectionTime, forMainFrameOnly: Bool) -> T {
        // iOS 14.3 is required here because of a webkit bug in lower iOS versions with this API
        if #available(iOS 14.3, *) {
            return T(source: source, injectionTime: injectionTime, forMainFrameOnly: forMainFrameOnly, in: .page)
        } else {
            return T(source: source, injectionTime: injectionTime, forMainFrameOnly: forMainFrameOnly)
        }
    }
}

private let apostropheEncoded = "%27"

public extension WKWebView {
    func replaceLocation(with url: URL) {
        let safeUrl = url.absoluteString.replacingOccurrences(of: "'", with: apostropheEncoded)
        evaluateJavascriptInDefaultContentWorld("location.replace('\(safeUrl)')")
    }
}
