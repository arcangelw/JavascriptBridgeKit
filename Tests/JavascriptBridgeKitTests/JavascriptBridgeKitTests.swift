@testable import JavascriptBridgeCore
@testable import JavascriptBridgeKit
import XCTest

@objc
protocol JSBridgeExport: JavascriptBridgeExport {
    func funcSync() -> String
    func funcSync(_ a: Int, _ b: String) -> String
    func funcAsync()
    func funcAsync(_ a: Int, _ b: String)
}

@objc
protocol JSBridgeExport1: JSBridgeExport {
    func funcSync(_ a: Int, _ b: String, _ c: Int) -> String
    func funcAsync(_ a: Int, _ b: String, _ c: Int)
}

class JSBridge: NSObject, JSBridgeExport {
    func funcSync() -> String {
        ""
    }

    func funcSync(_: Int, _: String) -> String {
        ""
    }

    func funcAsync() {}

    func funcAsync(_: Int, _: String) {}
}

class JSBridge1: JSBridge, JSBridgeExport1 {
    func funcSync(_: Int, _: String, _: Int) -> String {
        ""
    }

    func funcAsync(_: Int, _: String, _: Int) {}
}

final class JavascriptBridgeKitTests: XCTestCase {
    func testJavascriptFunctionInject() throws {
        let object = JSBridge1()
        let methods = instanceMethods(object, on: JavascriptBridgeExport.self)
        let syncMethods = methods.syncSelectors.map(NSStringFromSelector).sorted(by: <)
        let asyncMethods = methods.asyncSelectors.map(NSStringFromSelector).sorted(by: <)
        XCTAssertTrue(syncMethods.contains("funcSync"))
        XCTAssertTrue(syncMethods.contains("funcSync::"))
        XCTAssertTrue(syncMethods.contains("funcSync:::"))
        XCTAssertTrue(asyncMethods.contains("funcAsync"))
        XCTAssertTrue(asyncMethods.contains("funcAsync::"))
        XCTAssertTrue(asyncMethods.contains("funcAsync:::"))
    }
}
