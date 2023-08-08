//
//  JavascriptBridgeKit.swift
//
//
//  Created by 吴哲 on 2023/8/10.
//

import WebKit

final class JavascriptBridgeUserScript: WKUserScript {
    static func create() -> JavascriptBridgeUserScript? {
        #if JavascriptBridgeKitModule
            let file = Bundle.module.path(forResource: "JSBridge", ofType: "js") ?? ""
        #else
            let file = Bundle(for: self).path(forResource: "JSBridge", ofType: "js") ?? ""
        #endif
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: file))
            return createInDefaultContentWorld(source: String(decoding: data, as: UTF8.self), injectionTime: .atDocumentStart, forMainFrameOnly: false)
        } catch {
            return nil
        }
    }
}

final class JavascriptUserScript: WKUserScript {
    let module: String
    init(module: String, target: JavascriptBridgeExport, of aProtocol: Protocol) {
        self.module = module
        let methods = instanceMethods(target, on: aProtocol)
        let script: (_ list: [String], _ isSync: Bool) -> String = {
            let data: Data = (try? JSONEncoder().encode($0)) ?? Data("[]".utf8)
            return "window.JSBridge.injectNativeScript&&window.JSBridge.injectNativeScript('\(module)','\(String(decoding: data, as: UTF8.self))',\($1 ? "true" : "false");"
        }
        let syncMethods = methods.syncSelectors.map(NSStringFromSelector).sorted(by: <)
        let asyncMethods = methods.asyncSelectors.map(NSStringFromSelector).sorted(by: <)
        let source = script(syncMethods, true) + script(asyncMethods, false)
        super.init(source: source, injectionTime: .atDocumentStart, forMainFrameOnly: false)
    }
}
