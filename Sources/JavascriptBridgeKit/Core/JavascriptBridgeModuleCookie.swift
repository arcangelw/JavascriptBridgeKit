//
//  JavascriptBridgeModuleCookie.swift
//
//
//  Created by 吴哲 on 2023/8/11.
//

import Foundation

private protocol CookieSyncExport: JavascriptBridgeExport {
    func setCookie(_ cookie: String)
    func getCookie(_ location: String) -> String
}

final class JavascriptBridgeModuleCookie: NSObject, CookieSyncExport {
    func setCookie(_: String) {}

    func getCookie(_: String) -> String {
        return ""
    }
}
